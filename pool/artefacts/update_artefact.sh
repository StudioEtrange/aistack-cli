#!/usr/bin/env bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# https://gist.github.com/StudioEtrange/dfc230fcca6be8b6e575c90b46096f21
update_opencode_session_transfer() {
  rm -f "${_CURRENT_FILE_DIR}/opencode-session-transfer.sh"
  # ?$(date +%s) is here only to invalidate server cache by changing URL
  curl -fksL "https://gist.githubusercontent.com/StudioEtrange/dfc230fcca6be8b6e575c90b46096f21/raw/opencode-session-transfer.sh?$(date +%s)" -o "${_CURRENT_FILE_DIR}/opencode-session-transfer.sh"
  chmod +x "${_CURRENT_FILE_DIR}/opencode-session-transfer.sh"
}


case "$1" in
  opencode-session-transfer)
    update_opencode_session_transfer
    ;;
  all)
    update_opencode_session_transfer
  ;;
  * )
    echo "Usage : ${0} <aall|opencode-session-transfer>"
    ;;
esac
