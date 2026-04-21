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

## Skills commands

* add a skill for every coding agent tool, at global scope
  * it will create a symbolic link with the skill folder fr om ./agents/skill-name to a configuration folder for each coding agent tool, even for tool not installed
```
asm install github:anthropics/skills --path skills/algorithmic-art --tool all --scope global -y
asm install https://github.com/anthropics/skills/tree/main/skills/algorithmic-art --tool all --scope global -y
```

## Notes

* `aistack asm launch` executes the `asm` binary with AIStack runtime context.
* If you register PATH, you can directly use `asm` from your shell.
* asm main config file is at `~/.config/agent-skill-manager/config.json`.
* Requires Bun runtime >= 1.0.0 as the runtime
* aistack [use npm recommended package manager](https://github.com/luongnv89/asm#pick-one-package-manager) 
