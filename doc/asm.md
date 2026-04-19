# asm - Agent Skill Manager

Agent Skill Manager (`asm`) is a CLI/TUI to manage AI agent skills across multiple providers.

## Links

* **Source**: [github.com/luongnv89/asm](https://github.com/luongnv89/asm)

## Quickstart

* install
```
./aistack asm install
```

* register launcher in your shell PATH
```
./aistack asm register bash
```

* launch the TUI
```
./aistack asm launch
```

* launch a specific command
```
./aistack asm launch -- doctor
```
* uninstall
```
./aistack asm uninstall
```

## Notes

* `aistack asm launch` executes the `asm` binary with AIStack runtime context.
* If you register PATH, you can directly use `asm` from your shell.
* asm main config file is at `~/.config/agent-skill-manager/config.json`.
* Requires Bun runtime >= 1.0.0 as the runtime
* aistack [use npm recommended package manager](https://github.com/luongnv89/asm#pick-one-package-manager) 
