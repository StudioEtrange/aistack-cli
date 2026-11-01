# Claude Code

AIStack installs the latest native Claude Code executable in `${AISTACK_ISOLATED_ROOT}/claude-code/claude`. No Node.js runtime is required.

## Usage

Initialize AIStack once with `./aistack init`, then:

```bash
./aistack cc install
./aistack cc info
./aistack cc launch -- --version
./aistack cc launch /path/to/project
./aistack cc launch -- -p "Explain this project"
./aistack cc register
```

In a new shell, use `claude` directly. `register` accepts `current`, a quoted shell list, or `vs` for the VS Code terminal. `unregister` accepts the same targets plus `all` (the default).

```bash
./aistack cc unregister
./aistack cc uninstall
```

Uninstallation removes the managed executable, context and launcher registration, keeping Claude Code user configuration.


## Notes

* latest version number : https://downloads.claude.ai/claude-code-releases/latest
* `cc install` accepts no version argument: the upstream bootstrap script always downloads `latest`; other target versions are normally resolved by the installation step that AIStack skips. Run `cc install` again to refresh the binary.