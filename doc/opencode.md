# OpenCode

An AI coding agent built for the terminal.
* **Website**: [opencode.ai](https://opencode.ai)
* **Source**: [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode)
* **IDE Integration**: Integrates with VS Code, Cursor, and other IDEs by running `OpenCode` in the integrated terminal.

## NOTES
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
* extension oh-my-opencode (aka OmO)
  * https://github.com/code-yeongyu/oh-my-openagent
  * https://www.npmjs.com/package/oh-my-opencode
  * extension for opencode cli but also codex cli

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

## Skills

* configuration locations loaded:
  - opencode project scope: `.opencode/skills/<name>/SKILL.md`
  - opencode global scope: `~/.config/opencode/skills/<name>/SKILL.md`
  - claude project scope: `.claude/skills/<name>/SKILL.md`
  - claude global scope: `~/.claude/skills/<name>/SKILL.md`
  - generic agent project scope: `.agents/skills/<name>/SKILL.md`
  - generic agent global scope: `~/.agents/skills/<name>/SKILL.md`
