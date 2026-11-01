# OpenCode

An AI coding agent built for the terminal.
* **Website**: [opencode.ai](https://opencode.ai)
* **Source**: [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode)
* **IDE Integration**: Integrates with VS Code, Cursor, and other IDEs by running `OpenCode` in the integrated terminal.


## OpenCode connected to CPA

Connect OpenCode and register all models exposed by a running CLIProxyAPI instance:

```bash
./aistack oc connect cpa
```

Select an explicit default model and an optional session-title model:

```bash
./aistack cpa model list
./aistack oc connect cpa "gpt-5.6-sol" "gpt-5.6-luna"
```

When CLIProxyAPI is not reachable, an explicit default model is required. Only the explicitly provided models are then registered.

AIStack generates native OpenCode 2 configuration.


## Notes

* First step : init IA provider : `opencode auth login`
* OpenCode 2 supports a default model and a separate session-title model in `opencode.json(c)`:
  ```json
  {
    "model": "aistack-cpa/gpt-5.6-terra",
    "agents": {
      "title": {
        "model": "aistack-cpa/gpt-5.4-mini"
      }
    }
  }
  ```

* save opencode database while running
  ```sqlite3 "$(opencode debug paths db)" \
  ".backup '$HOME/.local/share/opencode/opencode.db.bak.$(date +%Y%m%d-%H%M%S)'"```


* OpenCode sync between host


| Project | Stars | Forks | Sync method | Remapping folder | Desc | URL |
|-|-|-|-|-|-|-|
| opencode-synced | 169	| 19	| GitHub / Git via SSH / Turso | No | Opencode plugin - Sync opencode configurations and session between machines | https://github.com/iHildy/opencode-synced |
|opencode-github-sync	| 34 |	6	| GitHub | No | OpenCode config & session sync via GitHub | https://github.com/lazyalex616/opencode-github-sync |
| opencode-session-manager-cli | 6 | 0 | Git, dossier partagé, transfert externe | Yes | Not compatible with oc 2.x - exporting/importing sessions with sub-sessions (tree-like), and sync between projects and the local database | https://github.com/neuronalism/opencode-session-manager-cli
| OpenCode-Session-Manager | 1 | 0 |	GitHub |	No | List, search, resume, export and backup sessions from any directory | https://github.com/evil-qq-intestine/OpenCode-Session-Manager |
|opencode_migrate |	0	| 0	| SSH / SCP |	Yes | import and export session between opencode, codex and claude-code | https://github.com/Erickrus/opencode_migrate |

  * remapping folder topic : when transfer from an host to another, path on each host are not the same
   * OpenCode project have their own folder path attached
   * OpenCode sessions are attached to a project but they have their own folder path attached



* opencode sessions and projects list

  ```
  sqlite3 -readonly -markdown "$DB" '
    SELECT
        p.id AS project_id,
        p.name AS project_name,
        p.worktree AS project_worktree,
        s.id AS session_id,
        s.directory AS session_directory,
        s.title AS session_title
    FROM project p
    LEFT JOIN session s ON s.project_id = p.id
    ORDER BY p.worktree, s.time_created DESC;
  '
  ```


|project_id| project_name |project_worktree|session_id|session_directory|  session_title   |
|-|-|-|-|-|-|
| global|   | /| ses_ef15e85ccffeQLnr96aVpXlNIR | /Users/user1/geneai      | Quick test    |
| global|   | /| ses_023900173ffelGrCLyI4uDnYJC | /Users/user1/geneai      | Reconfiguration du serveur MCP dbhub  |
| 3be20ad24410d5d894 |   | /Users/user1/aistack-cli          | ses_032df7fafffe5uj1I7Wwbx4t6T | /Users/user1/aistack-cli | Research OpenChamber install (@general subagent) |
| 3be20ad24410d5d894|   | /Users/user1/aistack-cli          | ses_032dfaff9ffeObshSO6a4NPIk8 | /Users/user1/aistack-cli | OpenChamber instal script   |
| 72f377550aff88a679 |   | /Users/user1/glibc-binary-compat  ||    |    |
| de9d4ff16189a68c17d|   | /Users/user1/stella    ||    |    |
