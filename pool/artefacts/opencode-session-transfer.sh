#!/usr/bin/env bash
set -euo pipefail

# Opencode source code: https://github.com/anomalyco/opencode
# Opencode 2 CLI documentation: https://opencode.ai/v2/docs

# nb session returned by 'opencode session list' (default is 100)
SESSION_LIST_MAX_COUNT=10000

# max nb database backup to keep
NB_BACKUP_DATABASE=3

# Remote invocations explicitly supply their SSH host; direct runs are local.
OST_LOG_HOST=${OST_LOG_HOST:-local}

# Log
log() {
    local LEVEL=${1:-} COLOR=34 LINE
    shift
    # 34 blue; 33 yellow; 31 red; 32 green
    case "$LEVEL" in
        INFO) COLOR=34 ;;
        WARN) COLOR=33 ;;
        ERROR) COLOR=31 ;;
    esac
    while IFS= read -r LINE; do
        printf '\033[%sm[OST][%s][%s]\033[0m %s\n' "$COLOR" "$LEVEL" "$OST_LOG_HOST" "$LINE"
    done <<<"$*"
}

# Display usage and requirements
show_help() {
    cat <<EOF
--=== OpenCode Session Transfer ===-- [OST]
Transfer OpenCode v2 sessions between projects over SSH and manage database backups.
Launch this script then select interactively a session to export and to import.

Usage:
  opencode-session-transfer.sh transfer <SOURCE_HOST|local> <SOURCE_DIR> <TARGET_HOST|local> <TARGET_DIR>
  opencode-session-transfer.sh savedb
  opencode-session-transfer.sh restoredb
  opencode-session-transfer.sh restoredb <BACKUP_FILE>
  opencode-session-transfer.sh backupdb <list|purge [nb]> 
  opencode-session-transfer.sh help

Required:
  - Bash
  - SSH client locally and SSH server on the remote host
  - OpenCode v2 on both hosts
  - An existing target project directory
  - jq on both hosts 
  - sqlite3 optional on the target host for automatic backups
  - sqlite3 required for savedb and restoredb commands

Notes:
  - Exporting active sessions may produce incomplete exports.
  - Child session of an exported sessions are not exported.
  - Replacement of an existing session is refused when the queried server reports the target session
    as running, or its activity cannot be checked, or if session has child session.
  - Use 'local' as a host to operate on this machine without SSH.
  - Remote-to-remote transfers pass through this machine.
  - Directory expressions are evaluated on the host where they are used.
      Example: opencode-session-transfer.sh transfer local . orion '\$HOME/workspace/app'
      Example: opencode-session-transfer.sh transfer orion '\$HOME/workspace/app' local .
  - Automatic backups are created only when replacing an existing session
    and sqlite3 is available. Only $NB_BACKUP_DATABASE backups are keeped when automatic backup, other are purged.
EOF
}

# Check the installed OpenCode major version
check_opencode_available_and_version() {
    local version opencode_path

    opencode_path=$(command -v opencode) || {
        log "ERROR" "opencode not found." >&2
        exit 1
    }

    version=$(opencode --version)

    # The first sequence of digits is the major version.
    [[ "$version" =~ ([0-9]+) ]] &&
        [ "${BASH_REMATCH[1]}" = "2" ] || {
        log "ERROR" "OpenCode v2 required, detected: $version" >&2
        exit 1
    }

    log "INFO" "OpenCode detected: $opencode_path"
    log "INFO" "OpenCode version: $version"
}

# Return 0 if reported active, 1 if absent, and 2 on API or parsing error.
# This observes execution on the queried server
check_active() {
    local ID="$1" STATUS RESULT

    # opencode api GET /api/session/active returns all active sessions
    STATUS=$(opencode api GET /api/session/active) || {
        log "ERROR" "Failed to check session activity: $ID" >&2
        return 2
    }

    if jq -e --arg id "$ID" '.data | has($id)' <<<"$STATUS" >/dev/null; then
        return 0
    else
        RESULT=$?
        if ((RESULT == 1)); then
            return 1
        fi
        log "ERROR" "Failed to parse session activity: $ID" >&2
        return 2
    fi
}

# Return 0 if children exist, 1 if none, and 2 on error.
has_children() {
    local ID="$1" RESPONSE RESULT

    RESPONSE=$(opencode api GET "/api/session?parentID=$ID&limit=1" 2>/dev/null) || {
        log "ERROR" "Failed to check child sessions: $ID" >&2
        return 2
    }

    if jq -e '.data | length > 0' <<<"$RESPONSE" >/dev/null; then
        return 0
    else
        RESULT=$?
        if ((RESULT == 1)); then
            return 1
        fi
        log "ERROR" "Failed to parse child sessions: $ID" >&2
        return 2
    fi
}

# List up to SESSION_LIST_MAX_COUNT root sessions in the current project
list_sessions() {
    opencode session list --format json --max-count "$SESSION_LIST_MAX_COUNT"
}

# Report recovery information only when an existing session was deleted
warn_deleted_session() {
    [ "$2" = "true" ] || return 0
    log "WARN" "The previous target session has already been deleted: $1" >&2
    if [ -n "$3" ]; then
        log "INFO" "If needed, database backup available at: $3" >&2
    else
        log "WARN" "No database backup was created before those operations." >&2
    fi
}

# Create a unique backup directly in its final location.
# Keep the random suffix after .db: trailing Xs work on both macOS and Linux.
# Arguments: database, backup filename prefix, caller output variable name.
create_database_backup() {
    local SOURCE_DB="$1" PREFIX="$2" OUTPUT_VAR="$3"
    local CREATED_BACKUP SQLITE_PATH

    CREATED_BACKUP=$(mktemp "${PREFIX}.db.XXXXXXXX") || return 1

    # SQLite dot commands accept double-quoted paths with escaped backslashes/quotes.
    SQLITE_PATH="$CREATED_BACKUP"
    SQLITE_PATH=${SQLITE_PATH//\\/\\\\}
    SQLITE_PATH=${SQLITE_PATH//\"/\\\"}
    if ! sqlite3 "$SOURCE_DB" ".backup \"$SQLITE_PATH\""; then
        rm -f -- "$CREATED_BACKUP"
        log "ERROR" "Database backup failed." >&2
        return 1
    fi

    printf -v "$OUTPUT_VAR" '%s' "$CREATED_BACKUP"
}

# Save the entire local OpenCode database under the adjacent backups directory
# SQLite .backup creates a consistent snapshot even while OpenCode is running
# Optionally pass a variable name to receive the backup's path:
#   save_database REPLACEMENT_BACKUP
# Use 'purge' to prune old backups
#   save_database purge REPLACEMENT_BACKUP
# If .backup fails, remove the incomplete backup and return an error
#
#	save_database <purge> <output variable name>
save_database() {
    local DB BACKUPS_FOLDER BACKUP_DB PURGE=false

    if [ "${1:-}" = "purge" ]; then
        PURGE=true
        shift
    fi

    log "INFO" "Saving database"
    command -v sqlite3 >/dev/null 2>&1 || {
        log "ERROR" "sqlite3 is required to save a database." >&2
        return 1
    }

    check_opencode_available_and_version 1>/dev/null

    DB=$(opencode debug paths db)

    [ -f "$DB" ] || {
        log "ERROR" "OpenCode database not found: $DB" >&2
        return 1
    }
    log "INFO" "Detected database found: $DB"

    BACKUPS_FOLDER="$(dirname "$DB")/backups"
    mkdir -p "$BACKUPS_FOLDER"

    create_database_backup "$DB" "$BACKUPS_FOLDER/opencode" BACKUP_DB || return 1

    log "INFO" "Database backup: $BACKUP_DB"
    if [ -n "${1:-}" ]; then
        printf -v "$1" '%s' "$BACKUP_DB"
    fi

    # Prune only when explicitly requested, after the backup has succeeded.
    if [ "$PURGE" = "true" ]; then
        log "INFO" "Purge database backups to keep only $NB_BACKUP_DATABASE"
        cleanup_database_backup "$NB_BACKUP_DATABASE" "$BACKUPS_FOLDER"
    fi
}

restore_database() {
    local BACKUP_DB="${1:-}" DB BACKUPS_FOLDER SAFETY_BACKUP CONFIRM LINE

    command -v sqlite3 >/dev/null 2>&1 || {
        log "ERROR" "sqlite3 is required to restore a database." >&2
        return 1
    }

    check_opencode_available_and_version 1>/dev/null

    DB=$(opencode debug paths db)
    BACKUPS_FOLDER="$(dirname "$DB")/backups"

    [ -f "$BACKUP_DB" ] || {
        log "ERROR" "Backup not found: $BACKUP_DB" >&2
        return 1
    }

    [ -f "$DB" ] || {
        log "ERROR" "OpenCode database not found: $DB" >&2
        return 1
    }
    log "INFO" "Detected database found: $DB"

    # Verify backup integrity before restoring
    [ "$(sqlite3 "$BACKUP_DB" 'PRAGMA integrity_check;')" = "ok" ] || {
        log "ERROR" "Backup integrity check failed." >&2
        return 1
    }

    log "WARN" "This operation will replace the entire OpenCode database." >&2
    log "WARN" "You must STOP all OpenCode processes before continuing." >&2
    log "INFO" "Backup:   $BACKUP_DB"

    log "WARN" "Type RESTORE to confirm:" >&2
    read -r CONFIRM

    [ "$CONFIRM" = "RESTORE" ] || {
        log "WARN" "Restore cancelled."
        return 1
    }

    # Preserve the current database before restoring
    mkdir -p "$BACKUPS_FOLDER"
    create_database_backup "$DB" "$BACKUPS_FOLDER/opencode.pre-restore" SAFETY_BACKUP || return 1
    log "INFO" "Current database saved to: $SAFETY_BACKUP"

    # Restore the selected backup
    sqlite3 "$DB" ".restore '$BACKUP_DB'"

    log "INFO" "Database restored successfully."
}

# Look up an ID across projects on the connected server, including child sessions
# IDs are unique across projects
# Look up a session ID globally: 0 = found, 1 = absent, 2 = lookup failed
lookup_session() {
    local ID="$1" RESPONSE
    if RESPONSE=$(opencode api GET "/api/session/$ID" 2>/dev/null); then
        if ! jq -e --arg id "$ID" '
		.data.id == $id and
		(.data.location.directory | type == "string" and startswith("/"))
    ' <<<"$RESPONSE" >/dev/null; then
            log "ERROR" "Invalid session lookup response: $ID" >&2
            return 2
        fi
        printf '%s\n' "$RESPONSE"
        return 0
    fi

    if jq -e --arg id "$ID" '
    	._tag == "SessionNotFoundError" and .sessionID == $id
  ' <<<"$RESPONSE" >/dev/null 2>&1; then
        return 1
    fi
    log "ERROR" "Unable to look up session: $ID" >&2
    return 2
}

# Return the session ID when available
get_session_id() {
    jq -er '.info.id | select(type == "string" and length > 0)' "$1"
}

# Remove the local export and attempt remote temporary-directory cleanup
# Paths passed here are frozen into the EXIT trap before local variables expire
cleanup_transfer() {
    rm -f -- "$1"
    if [ -n "$3" ]; then
        ssh -S "$4/control" -o ControlMaster=no -o BatchMode=yes \
            -o ProxyCommand=false -o ConnectTimeout=15 \
            -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -- "$2" \
            "rm -rf -- '$3'" </dev/null ||
            log "WARN" "Remote cleanup failed: $2:$3" >&2
    fi
    # Close only the master created for this transfer, never a user-owned socket.
    if [ -n "$4" ]; then
        if ssh -S "$4/control" -O check -- "$2" </dev/null >/dev/null 2>&1; then
            if ! ssh -S "$4/control" -O exit -- "$2" </dev/null >/dev/null 2>&1; then
                log "WARN" "Unable to close SSH master; keeping its socket: $4/control" >&2
                return 0
            fi
        elif [ -S "$4/control" ]; then
            # An unresponsive socket is not proof that its master has stopped.
            log "WARN" "Unable to verify SSH master; keeping its socket: $4/control" >&2
            return 0
        fi
        # A successful exit request may precede socket removal by the master.
        # Do not unlink the socket ourselves: retain access if shutdown is delayed.
        if [ -S "$4/control" ]; then
            log "WARN" "SSH shutdown requested; temporary socket directory retained: $4" >&2
        else
            rmdir -- "$4" || log "WARN" "Unable to remove SSH socket directory: $4" >&2
        fi
    fi
}

# Initialize the SSH connection and traps for either transfer direction.
# Callers declare these variables locally; Bash dynamic scoping shares them.
ssh_connection() {
    local HOST="${1}"
    local CURRENT_SCRIPT

    # A private socket prevents repeated password prompts and does not interfere
    # with SSH multiplexing configured by the user. Freeze paths into the trap
    SSH_CONTROL_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ost.XXXXXXXX")
    CONNECTION_HOSTS+=("$HOST")
    CONNECTION_SOCKETS+=("$SSH_CONTROL_DIR")
    CONNECTION_DIRS+=("")

    ssh -M -S "$SSH_CONTROL_DIR/control" -o ControlMaster=yes \
        -o ControlPersist=120 -o ConnectTimeout=15 \
        -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -f -N -- "$HOST"

    if ! ssh -S "$SSH_CONTROL_DIR/control" -O check -- "$HOST" </dev/null; then
        log "ERROR" "SSH master is unavailable; transfer aborted: $HOST" >&2
        return 1
    fi

    # Multiplexed sessions bypass ProxyCommand. If the master disappears,
    # fail instead of silently opening a new authenticated connection.
    SSH_OPTIONS=(-S "$SSH_CONTROL_DIR/control" -o ControlMaster=no -o BatchMode=yes
        -o ProxyCommand=false -o ConnectTimeout=15
        -o ServerAliveInterval=15 -o ServerAliveCountMax=3)

    # Create a temporary directory on the distant host
    TMP_REMOTE_DIR=$(ssh "${SSH_OPTIONS[@]}" -- "$HOST" 'mktemp -d /tmp/opencode-transfer.XXXXXXXX')
    [ "$TMP_REMOTE_DIR" =~ ^/tmp/opencode-transfer\.[a-zA-Z0-9]+$ ] || {
        log "ERROR" "Unexpected remote temporary directory: $TMP_REMOTE_DIR" >&2
        return 1
    }
    CONNECTION_DIRS[${#CONNECTION_DIRS[@]} - 1]="$TMP_REMOTE_DIR"

    CURRENT_SCRIPT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")

    ssh_transfer_file "$HOST" "$CURRENT_SCRIPT" "$TMP_REMOTE_DIR/transfer.sh"

}

ssh_transfer_file() {
    local HOST="${1}"
    local FILE="${2}"
    local TARGET_DEST_FILE="${3}"
    ssh "${SSH_OPTIONS[@]}" -- "$HOST" "cat > '$TARGET_DEST_FILE'" <"$FILE"
}

# Export a session
export_session() (
    local SOURCE_DIR="$1" EXPORTED_SESSION="$2" ID
    [ "${EXPORTED_SESSION:0:1}" = "/" ] || EXPORTED_SESSION="$PWD/$EXPORTED_SESSION"
    SOURCE_DIR=$(eval "printf '%s' \"${SOURCE_DIR//\"/\\\"}\"") || return 1

    [ -d "$SOURCE_DIR" ] || {
        log "ERROR" "Source dir does not exist: $SOURCE_DIR" >&2
        return 1
    }

    cd -- "$SOURCE_DIR"
    command -v jq >/dev/null 2>&1 || {
        log "ERROR" "jq is required on the source host." >&2
        return 1
    }

    check_opencode_available_and_version

    # Interactively select and export a root session from the current directory.
    opencode session export >"$EXPORTED_SESSION"

    ID=$(get_session_id "$EXPORTED_SESSION") || return 1

    [[ "$ID" =~ ^ses_[a-zA-Z0-9]+$ ]] || {
        log "ERROR" "Invalid session ID" >&2
        exit 1
    }

    log "INFO" "Selected session: $ID"

    if has_children "$ID"; then
        log "WARN" "Session has child sessions. Exporting child sessions is not supported; they will not be included." >&2
    fi

    if check_active "$ID"; then
        log "WARN" "Session is active. Exported history may be incomplete." >&2
    fi
    log "INFO" "Exported session in: $EXPORTED_SESSION"

)

cleanup_connections() {
    local INDEX
    rm -f -- "$EXPORTED_SESSION"
    for ((INDEX = 0; INDEX < ${#CONNECTION_HOSTS[@]}; INDEX++)); do
        [ -n "${CONNECTION_HOSTS[INDEX]}" ] || continue
        cleanup_transfer "$EXPORTED_SESSION" "${CONNECTION_HOSTS[INDEX]}" \
            "${CONNECTION_DIRS[INDEX]}" "${CONNECTION_SOCKETS[INDEX]}" || true
    done
}

# Keep the N most recently modified backups, including pre-restore snapshots.
# Optional arguments: retention count (default NB_BACKUP_DATABASE), backup folder.
# Resolve the local database folder when called without an explicit folder.
cleanup_database_backup() {
    local KEEP="${1:-$NB_BACKUP_DATABASE}" BACKUPS_FOLDER="${2:-}"
    local DB FILE INDEX POSITION COUNT=0
    local -a BACKUPS
    BACKUPS=()

    # Require a positive count so cleanup cannot remove every recovery snapshot.
    [[ "$KEEP" =~ ^[1-9][0-9]*$ ]] || {
        log "ERROR" "Backup retention must be a positive integer: $KEEP" >&2
        return 1
    }

    if [ -z "$BACKUPS_FOLDER" ]; then
        check_opencode_available_and_version 1>/dev/null
        DB=$(opencode debug paths db) || return 1
        BACKUPS_FOLDER="$(dirname "$DB")/backups"
    fi
    [ -d "$BACKUPS_FOLDER" ] || return 0

    # Sort paths directly in Bash: no parsing of ls output, portable to macOS/Linux.
    # Only regular, non-symlink OpenCode backups in this folder are eligible.
    for FILE in "$BACKUPS_FOLDER"/opencode.db.* "$BACKUPS_FOLDER"/opencode.pre-restore.db.*; do
        [ -f "$FILE" ] && [ ! -L "$FILE" ] || continue
        POSITION=$COUNT
        while ((POSITION > 0)); do
            [ "$FILE" -nt "${BACKUPS[POSITION - 1]}" ] || break
            BACKUPS[POSITION]="${BACKUPS[POSITION - 1]}"
            POSITION=$((POSITION - 1))
        done
        BACKUPS[POSITION]="$FILE"
        COUNT=$((COUNT + 1))
    done

    for ((INDEX = KEEP; INDEX < COUNT; INDEX++)); do
        FILE="${BACKUPS[INDEX]}"
        if ! rm -f -- "$FILE"; then
            log "ERROR" "Unable to remove old database backup: $FILE" >&2
            return 1
        fi
        log "INFO" "Old database backup removed: $FILE"
    done
}

list_database_backup() {

    check_opencode_available_and_version 1>/dev/null

    DB=$(opencode debug paths db)
    BACKUPS_FOLDER="$(dirname "$DB")/backups"

    log "INFO" "Available backups in $BACKUPS_FOLDER:"
    if [ -d "$BACKUPS_FOLDER" ]; then
        find "$BACKUPS_FOLDER" -maxdepth 1 -type f \
            \( -name 'opencode.db.*' -o -name 'opencode.pre-restore.db.*' \) -print |
            while IFS= read -r LINE; do log "INFO" "$LINE"; done
    fi
    return 0
}

remote_command() {
    local HOST="$1" TERMINAL="$2" COMMAND ARG
    shift 2
    printf -v COMMAND 'export OST_LOG_HOST=%q; exec bash %q ' \
        "$HOST" "$TMP_REMOTE_DIR/transfer.sh"
    for ARG in "$@"; do
        printf -v COMMAND '%s%q ' "$COMMAND" "$ARG"
    done
    COMMAND+='2>&3 3>&-'
    COMMAND=${COMMAND//\'/\'\\\'\'}
    if [ "$TERMINAL" = "true" ]; then
        ssh "${SSH_OPTIONS[@]}" -t -- "$HOST" "bash +m -ic '$COMMAND' 3>&2 2>/dev/null"
    else
        ssh "${SSH_OPTIONS[@]}" -- "$HOST" "bash +m -ic '$COMMAND' 3>&2 2>/dev/null"
    fi
}

# A subshell keeps source/target cd and cleanup state isolated from the caller
# use 'local' to use the current host as source and/or target without ssh transfer
transfer() (
    local SRC_HOST="$1" SRC_DIR="$2" TARGET_HOST="$3" TARGET_DIR="$4"
    local SSH_CONTROL_DIR TMP_REMOTE_DIR EXPORTED_SESSION ID HOST
    local -a SSH_OPTIONS CONNECTION_HOSTS CONNECTION_SOCKETS CONNECTION_DIRS

    # ssh_connection fills the active SSH state and registers each host
    # in these arrays so cleanup_connections can release all connections.
    CONNECTION_HOSTS=() CONNECTION_SOCKETS=() CONNECTION_DIRS=()

    # Validate both endpoints before exporting or opening any SSH connection.
    for HOST in "$SRC_HOST" "$TARGET_HOST"; do
        [ -n "$HOST" ] && [ "${HOST:0:1}" != "-" ] || {
            log "ERROR" "Host must be nonempty and must not start with '-'." >&2
            return 1
        }
    done

    command -v jq >/dev/null 2>&1 || {
        log "ERROR" "jq is required for session transfers." >&2
        return 1
    }

    # The remote selector reads from a terminal; JSON is downloaded separately.
    if [ "$SRC_HOST" != "local" ] && [ ! -t 0 ]; then
        log "ERROR" "Remote session selection requires an interactive terminal." >&2
        return 1
    fi

    # Always stage the export locally, including remote-to-remote transfers.
    # The EXIT trap runs while this subshell's local variables are still available.
    EXPORTED_SESSION=$(mktemp)
    trap 'cleanup_connections' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    log "INFO" "Transfer: $SRC_HOST:$SRC_DIR -> $TARGET_HOST:$TARGET_DIR"

    # Export on the source host. Directory expressions are expanded there.
    if [ "$SRC_HOST" = "local" ]; then
        export_session "$SRC_DIR" "$EXPORTED_SESSION"
    else
        ssh_connection "$SRC_HOST"
        remote_command "$SRC_HOST" true export "$SRC_DIR" "$TMP_REMOTE_DIR/session.json"

        # No PTY for the download: keep terminal output out of the JSON file.
        ssh "${SSH_OPTIONS[@]}" -- "$SRC_HOST" "cat '$TMP_REMOTE_DIR/session.json'" >"$EXPORTED_SESSION"
    fi

    ID=$(get_session_id "$EXPORTED_SESSION") || return 1
    [[ "$ID" =~ ^ses_[a-zA-Z0-9]+$ ]] || {
        log "ERROR" "Invalid session ID: $ID" >&2
        return 1
    }

    # Once downloaded and validated, a distinct remote source is no longer needed.
    # Clean it before destination authentication/import can leave it idle too long.
    # Keep the local JSON: cleanup_transfer's first argument must be empty here.
    if [ "$SRC_HOST" != "local" ] && [ "$SRC_HOST" != "$TARGET_HOST" ]; then
        if ssh "${SSH_OPTIONS[@]}" -- "$SRC_HOST" \
            "rm -rf -- '$TMP_REMOTE_DIR'" </dev/null; then
            CONNECTION_DIRS[0]=""
            cleanup_transfer "" "$SRC_HOST" "" "$SSH_CONTROL_DIR"

            # Retain failed/unconfirmed shutdowns for another attempt in the EXIT trap.
            if [ ! -S "$SSH_CONTROL_DIR/control" ]; then
                CONNECTION_HOSTS[0]=""
            fi
        else
            log "WARN" "Early source cleanup failed; will retry at exit: $SRC_HOST:$TMP_REMOTE_DIR" >&2
        fi
    fi

    # Import on the destination host using the existing replacement checks.
    if [ "$TARGET_HOST" = "local" ]; then
        import_session "$ID" "$TARGET_DIR" "$EXPORTED_SESSION"
    else
        # Identical SSH host arguments reuse the source connection and temp folder.
        # Otherwise ssh_connection switches the active state to the target.
        if [ "$TARGET_HOST" != "$SRC_HOST" ]; then
            ssh_connection "$TARGET_HOST"
        fi

        ssh_transfer_file "$TARGET_HOST" "$EXPORTED_SESSION" "$TMP_REMOTE_DIR/session.json"
        remote_command "$TARGET_HOST" false import "$ID" "$TARGET_DIR" "$TMP_REMOTE_DIR/session.json"
    fi
)

# Import a session
import_session() {
    local ID="$1" TARGET_DIR="$2" FILE="$3"
    local SESSION STATUS FILE_ID
    local REPLACEMENT_BACKUP="" SESSION_DELETED=false

    command -v jq >/dev/null 2>&1 || {
        log "ERROR" "jq is required on the target host." >&2
        return 1
    }

    [[ "$ID" =~ ^ses_[a-zA-Z0-9]+$ ]] || {
        log "ERROR" "Invalid session ID: $ID" >&2
        return 1
    }

    # Evaluate the user-supplied expression only on the importing host, as one
    # double-quoted value. Keep literal double quotes in directory names
    TARGET_DIR=$(eval "printf '%s' \"${TARGET_DIR//\"/\\\"}\"") || {
        log "ERROR" "Failed to expand target directory expression." >&2
        return 1
    }

    [ -d "$TARGET_DIR" ] || {
        log "ERROR" "Target dir does not exist: $TARGET_DIR" >&2
        return 1
    }

    [ -f "$FILE" ] && [ -r "$FILE" ] || {
        log "ERROR" "Session export is not a readable file: $FILE" >&2
        return 1
    }

    # Make the file path absolute before cd, also protecting leading '-' filenames
    [ "${FILE:0:1}" = "/" ] || FILE="$PWD/$FILE"

    FILE_ID=$(get_session_id "$FILE") || return 1
    [ "$FILE_ID" = "$ID" ] || {
        log "ERROR" "Exported session ID does not match argument: $ID" >&2
        return 1
    }

    cd -- "$TARGET_DIR"
    TARGET_DIR=$(pwd -P)

    check_opencode_available_and_version

    # Check whether the session id already exists
    if SESSION=$(lookup_session "$ID"); then
        if ! jq -e --arg directory "$TARGET_DIR" \
            '.data.location.directory == $directory' <<<"$SESSION" >/dev/null; then
            log "ERROR" "Session $ID already exists in another directory." >&2
            log "INFO" "Existing: $(jq -r '.data.location.directory' <<<"$SESSION")" >&2
            log "INFO" "Target:   $TARGET_DIR" >&2
            return 1
        fi
        log "WARN" "Already existing session exists in the same project: $ID"

        # Deleting a session also deletes its children, so we stop here
        if has_children "$ID"; then
            log "ERROR" "Session has child sessions; replacement aborted: $ID" >&2
            return 1
        else
            STATUS=$?
            if ((STATUS != 1)); then
                log "ERROR" "Unable to verify if session has child; replacement aborted: $ID" >&2
                return 1
            fi
        fi

        # Refuse to replace an active target session
        if check_active "$ID"; then
            log "ERROR" "Target session is active and in use, close it; transfer aborted: $ID" >&2
            return 1
        else
            STATUS=$?
            if ((STATUS != 1)); then
                log "ERROR" "Unable to verify target session activity" >&2
                return 1
            fi
        fi

        # Back up the database before deleting an existing session
        if command -v sqlite3 >/dev/null 2>&1; then
            save_database purge REPLACEMENT_BACKUP
        fi

        # The backup may take time. Recheck immediately before deletion to narrow
        # the race window; this is still not an atomic check-and-delete operation.
        if check_active "$ID"; then
            log "ERROR" "Target session started running; transfer aborted: $ID" >&2
            return 1
        else
            STATUS=$?
            if ((STATUS != 1)); then
                log "ERROR" "Unable to recheck target session activity; transfer aborted: $ID" >&2
                return 1
            fi
        fi

        # Delete the existing session before importing
        log "INFO" "Deleting already existing session $ID"
        opencode session delete "$ID"
        SESSION_DELETED=true
    else
        STATUS=$?
        if ((STATUS != 1)); then
            return 1
        fi
    fi

    # Import the session
    if ! opencode session import "$FILE" --directory "$TARGET_DIR"; then
        log "ERROR" "Session import failed: $ID" >&2
        warn_deleted_session "$ID" "$SESSION_DELETED" "$REPLACEMENT_BACKUP"
        return 1
    fi

    # Verify that the imported session exists
    if ! SESSION=$(lookup_session "$ID"); then
        log "ERROR" "Session import failed: $ID" >&2
        warn_deleted_session "$ID" "$SESSION_DELETED" "$REPLACEMENT_BACKUP"
        return 1
    fi

    if ! jq -e --arg directory "$TARGET_DIR" \
        '.data.location.directory == $directory' <<<"$SESSION" >/dev/null; then
        log "ERROR" "Imported session has an unexpected directory: $ID" >&2
        log "INFO" "Actual:   $(jq -r '.data.location.directory' <<<"$SESSION")" >&2
        log "INFO" "Expected: $TARGET_DIR" >&2
        warn_deleted_session "$ID" "$SESSION_DELETED" "$REPLACEMENT_BACKUP"
        return 1
    fi

    log "INFO" "Session successfully imported: $ID"
}

case "${1:-}" in
    -h | --help | help)
        show_help
        ;;
    savedb)
        [ $# -eq 1 ] || {
            show_help >&2
            exit 1
        }
        save_database
        ;;
    restoredb)
        [ $# -eq 2 ] || {
            show_help >&2
            exit 1
        }
        restore_database "$2"
        ;;
    backupdb)
        [ $# -lt 4 ] || {
            show_help >&2
            exit 1
        }
        case "$2" in
            "purge") cleanup_database_backup ${3:-} ;;
            "list") list_database_backup ;;
            *)
                show_help >&2
                exit 1
                ;;
        esac
        ;;
    import)
        [ $# -eq 4 ] || {
            show_help >&2
            exit 1
        }
        import_session "$2" "$3" "$4"
        ;;
    export)
        [ $# -eq 3 ] || {
            show_help >&2
            exit 1
        }
        export_session "$2" "$3"
        ;;
    transfer)
        [ $# -eq 5 ] || {
            show_help >&2
            exit 1
        }
        transfer "$2" "$3" "$4" "$5"
        ;;
    *)
        show_help >&2
        exit 1
        ;;
esac
