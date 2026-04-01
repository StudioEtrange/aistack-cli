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
  * First steps : 
  * yolo mode :
    * `kilo run --auto "run tests and fix any failures"`
    * The --auto flag disables all permission prompts and allows the agent to execute any action without confirmation. 
  * kilo cli and vs code extension config file : ~/.config/kilo/kilo.json
  * MCP config : https://kilo.ai/docs/automate/mcp/using-in-kilo-code