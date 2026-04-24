# Kilo Code

Kilo is the all-in-one agentic engineering platform.
* **Website**: [kilo.ai](https://kilo.ai/)
* **Source**: [github.com/Kilo-Org/kilocode](https://github.com/Kilo-Org/kilocode) 
* **IDE Integration**: Exists as a VS Code extension and a CLI. It shares the same code base.

## NOTES
  * VS Code extension
    * marketplace link : https://marketplace.visualstudio.com/items?itemName=kilocode.kilo-code
    * id : kilocode.Kilo-Code
  * Kilo CLI is a fork of OpenCode, they share the same json config syntax file
  * First steps : TODO
  * yolo mode :
    * `kilo run --auto "run tests and fix any failures"`
    * The --auto flag disables all permission prompts and allows the agent to execute any action without confirmation. 
  * kilo cli and vs code extension config file : ~/.config/kilo/kilo.json
  * MCP config : https://kilo.ai/docs/automate/mcp/using-in-kilo-code
  * Agent
    * primary agent (previously known as kilo code 'mode') : https://kilo.ai/docs/customize/custom-modes
    * subagent intend to be called by primary agent : https://kilo.ai/docs/customize/custom-subagents
  * Code indexing (DEPRECATED ?)
    * Use configurable embedding models and Qdrant vector databse : https://kilo.ai/docs/customize/context/codebase-indexing
  * Kilo Code is built upon Vercel AI SDK using its unified provider architecture 
    * https://github.com/vercel/ai
    * https://ai-sdk.dev/docs/foundations/providers-and-models

## Kilo Code connected to CPA
* how to commands :
    ```
    ./aistack kc connect cpa
    ./aistack kc launch -- run "hello"
    ./aistack kc launch -- run "hello" --model "aistack-cpa/gemini-2.5-flash-lite"
    ```

* commands lifecycle :
  * kilo install
      kilo configure

  * kilo connect [NEEDS CPA RUNNING to get available models]
      generate api key
        remove previously generated api key from cpa conf file
        record api key in a kilo private file
        add api key into cpa conf file (cpa_settings_api_key_add)
      register all available model into kilo conf file (using cpa_get_model_list)
        add api key into kilo conf file for those models

  * cpa install
    * fill cpa config with some default values
    * delete all previously existing api keys
    * create one api key and one management api key