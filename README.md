# AIStack CLI

AIStack CLI is an experimental swiss-knife command-line application designed to streamline the installation and management of AI development tools, including `gemini-cli`, `opencode` and various MCP servers. The main goal is to provide a convenient way to install and configure AI tools, ensuring minimal system, to test or use them.

## Key Features of AIStack

*   **AI Tool Management**: Streamlines the installation and configuration of AI agents like `gemini-cli` and `opencode`. Provides some minimal convenient default settings.
*   **MCP Server Integration**: Easily configure and manage connections to various MCP (Model Context Protocol) servers.
*   **Isolated Environments**: All tools are installed into a local `workspace/` directory, preventing system-wide conflicts. Installing any agent or MCP server will not pollute in anyway your system nor your development environment path with its own dependencies (nodejs, python, ...). Everything is contained in an easy deletable internal folder.
*   **Portability**: Bash application, works on Linux & MacOS.

## Getting Started

### Requirements

*   `bash`
*   `git`

### Commands

`aistack` provides a simple command-line interface to manage your tools and environments.

| Command | Description |
| - | - |
| **init** | Install/Reinstall dependencies |
| **help** | Display help message |
| **shell** | Enter a sub-shell with the `aistack` environment and paths configured |

### How-To


**Install and configure gemini-cli from scratch**

```
git clone https://github.com/StudioEtrange/aistack
cd aistack
./aistack init
./aistack gc install
./aistack gc register bash
```

**Register local MCP server calculator**
```
cd aistack
./aistack mcp calculator install
```

**Configure the underlying nodejs to add a local npm registry**
```
cd aistack
./aistack npm-config set registry https://registry.local.org/
```

## Directory Structure

*   `aistack/`: Contains the main application logic for the `aistack` wrapper script.
*   `lib/`: ITools internal libraries and code.
*   `pool/`: Contains configuration files templates and framework.
*   `workspace/`: The directory where all isolated environments and installed software ("features") are stored.

## Integrations

### Gemini CLI

See [Gemini CLI](doc/geminicli.md) 

### Opencode

See [Opencode](doc/opencode.md) 

### VS Code

See [VS Code](doc/vscode.md) 

### CLIProxyAPI

See [CLIProxyAPI](doc/cliproxyapi.md) 

### MCP Servers

AIStack simplifies connecting to MCP (Model Context Protocol) servers, allowing your AI agents to interact with external tools and services.
* **Catalogs**: [MCPMarket](https://mcpmarket.com/), [PulseMCP](https://www.pulsemcp.com/servers), [MCPServers.org](https://mcpservers.org/)

**Supported MCP Servers:**
* **Desktop Commander**: Grants terminal control and file system access. ([Source](https://github.com/wonderwhy-er/desktopcommandermcp))
* **Calculator**: A simple server for performing calculations. ([Source](https://github.com/githejie/mcp-server-calculator))
* **Context7**: Fetches up-to-date documentation and code examples. ([Source](https://github.com/upstash/context7)). https://context7.com/
* **GitHub**: Official server for interacting with GitHub issues, PRs, and repositories. ([Source](https://github.com/github/github-mcp-server))
* **Data Commons**: Tools and agents for interacting with the Data Commons Knowledge Graph using the Model Context Protocol (MCP). ([Source](https://github.com/datacommonsorg/agent-toolkit))

### Agent Skills

* spec : https://github.com/agentskills/agentskills
* home : https://agentskills.io/

## Design Notes 

### Notes on underlying Framework: Stella

AIStack leverages the **Stella** framework for its core functionality. Stella provides the infrastructure for application structure, environment isolation, and package management. **Package Management**: Stella uses a concept of "Features" (software packages) which are defined by "Recipes" (Bash scripts). `aistack` uses this system to provide all the tools it manages. The recipes are located in `pool/stella/nix/pool/feature-recipe/`.

### Notes on using nodejs, npx, npm

* `npx` command needs at least `node` binary in PATH and `sh` binary in PATH

* any mcp server based on node have 2 ways to be registered :
  
  A standard way using json in settings.json, injecting needed PATH env var value to reach node and other binaries (using STELLA_ORIGINAL_SYSTEM_PATH which contains original system PATH value)

  * registered mcp server desktop-commander :
  ```
  {
    "mcpServers": {
      "desktop-commander": {
        "command": "npx",
        "args": [
          "-y",
          "@wonderwhy-er/desktop-commander"
        ],
        "env": {
            "PATH": "${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}"
        }
      }
    }
  }
  ```

  Or an indirect way using a script as launcher
  * registered mcp server context7 :
  ```
  {
    "mcpServers": {
      "context7": {
        "command": "${AISTACK_MCP_LAUNCHER_HOME}/context7"
      }
    }
  }
  ```
  * script launcher for context7 :
  ```
  #!/bin/sh
  export PATH="/home/nomorgan/workspace/aistack/workspace/isolated_dependencies/nodejs/bin/:${PATH}"
  exec "npx" -y @upstash/context7-mcp --api-key "${CONTEXT7_API_KEY}"
  ```





## TODO and VARIOUS NOTES

* kilocode vsextension config home : $HOME/.vscode-server/data/User/globalStorage/kilocode.kilo-code/settings/mcp_settings.json
  * https://kilo.ai/docs/automate/mcp/using-in-cli
* process manager goreman https://github.com/mattn/goreman
* MCP-cli
  * https://github.com/IBM/mcp-cli
  * CLI to connect and interact with MCP (Model Context Protocol) servers.
  * Manages conversation, tool invocation, session handling.
  * Supports chat, interactive shell, and automation via MCP.
  * Integrates with LLMs for reasoning and tool-based workflows.
* Serving LLM - Ollama vs vLLM : https://developers.redhat.com/articles/2025/08/08/ollama-vs-vllm-deep-dive-performance-benchmarking#comparison_2__tuned_ollama_versus_vllm
  * Ollama excels in its intended role: a simple, accessible tool for local development, prototyping, and single-user applications. Its strength lies in its ease of use, not its ability to handle high-concurrency production traffic, where it struggles even when tuned.
  * vLLM is unequivocally the superior choice for production deployment. It is built for performance, delivering significantly higher throughput and lower latency under heavy load. Its dynamic batching and efficient resource management make it the ideal engine for scalable, enterprise-grade AI applications.


## Contributors

See the [CONTRIBUTORS](CONTRIBUTORS) file for the full list of contributors

## License

Licensed under the **Apache License, Version 2.0**.

Copyright © 2025-2026 **Sylvain Boucault**.

See the [LICENSE](LICENSE) file for details.