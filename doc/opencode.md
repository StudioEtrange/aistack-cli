# opencode

An AI coding agent built for the terminal.
* **Website**: [opencode.ai](https://opencode.ai)
* **Source**: [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode)
* **IDE Integration**: Integrates with VS Code, Cursor, and other IDEs by running `opencode` in the integrated terminal.

## NOTES
* First step : init IA provider : `opencode auth login`
* OpenCode supports a default model and a small model in its configuration:
  ```json
  {
    "model": "aistack-cpa/gpt-5.6-terra",
    "small_model": "aistack-cpa/gpt-5.4-mini"
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

Select an explicit default model and an optional small model:

```bash
./aistack cpa model list
./aistack oc connect cpa "gpt-5.6-sol" "gpt-5.6-luna"
```

When CLIProxyAPI is not reachable, an explicit default model is required. Only the explicitly provided models are then registered.
