[![made-with-bash](https://img.shields.io/badge/-Made%20with%20Bash-1f425f?logo=gnubash&logoColor=B83280)](https://www.gnu.org/software/bash/)<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
![cli-first](https://img.shields.io/badge/CLI-First-B83280?logo=gnometerminal)

# AIStack CLI

AIStack CLI is an experimental swiss-knife command-line application designed to streamline the installation and management of AI development tools, including `gemini-cli`, `antigravity-cli`, `opencode`, `asm`, `kilo code`, `orla` and various MCP servers, plugin, extensions, skills, frameworks like `bmad-method`, `get-shit-done-cc` or `ADK`, and so on. The main goal is to provide a convenient way to install and configure AI tools, ensuring no host impact nor change, to test and use them.

## Key Features of AIStack

*   **AI Tool Management**: Streamlines the installation and configuration of AI agents like `gemini-cli`, `opencode`, `asm`, `Kilo Code` and so on. Provides some minimal convenient default settings.
*   **MCP Server Integration**: Easily configure and manage connections to various MCP (Model Context Protocol) servers.
*   **Isolated Environments**: All tools are installed into a local `workspace/` directory, preventing system-wide conflicts. Installing any agent or MCP server will not pollute in anyway your system nor your development environment path with its own dependencies (nodejs, python, ...). Everything is contained in an easy deletable internal folder.
*   **Portability**: Bash application, works on Linux & MacOS.

## Getting Started

### Requirements

*   `bash`
*   `git`

### Commands

`aistack` provides a simple command-line interface to manage your tools and environments.

To see complete commands use `aistack help`.

| Core Commands | Description |
| - | - |
| **init** | Install/Reinstall dependencies |
| **uninstall** | Remove any tools and dependencies managed by AIStack |
| **help** | Display help message |
| **info** | Display various AIStack information and configuration |
| **shell** | Enter a sub-shell with the `aistack` environment and paths configured |


## How-To and Quick Usage

_"I want to install antigravity CLI from scratch and make it accessible from all my bash session"_

**_antigravity CLI installation, register and launch_** :
```
git clone https://github.com/StudioEtrange/aistack-cli.git
cd aistack-cli
./aistack init
./aistack agy install
./aistack agy info
./aistack agy register bash
```
**_in another bash session, launch_** :
```
agy
```

**SEE OTHER [Quick Usage](./doc/quickusage.md)**

## Specific documentation interest

* Installing AIStack using a [specific npm registry](./doc/nodejs.md#using-a-npm-registry)
+ Installing AIStack on old linux system, like Redhat/Centos 7 [see GBC](./doc/nodejs.md#using-aistack-on-old-linux-system-with-gbc)

## Directory Structure

*   `aistack` : Main script.
*   `README.md` : Documentation main entrypoint.
*   `doc/`: Various doc topic.
*   `lib/`: internal libraries and code.
*   `pool/`: Contains configuration files templates and framework.
*   `workspace/`: The directory where all isolated environments, dependencies and tools are located.

## Integrations

* AIStack CLI offers functionality for these tools

### Gemini CLI

See [Gemini CLI](doc/geminicli.md) 

### Opencode

See [Opencode](doc/opencode.md) 

### CLIProxyAPI

See [CLIProxyAPI](doc/cliproxyapi.md) 

### Antigravity CLI

See [Antigravity CLI](doc/antigravity.md)

### asm - agent skill manager

See [asm](doc/asm.md)

### Kilo Code

See [Kilo Code](doc/kilocode.md)

### Orla

See [Orla](doc/orla.md)

### BMAD

See [BMAD](doc/bmad.md)

### Agent Development Kit (ADK)

See [Agent Development Kit](doc/adk.md)

### VS Code

See [VS Code](doc/vscode.md)

### MCP Servers

AIStack simplifies connecting to MCP (Model Context Protocol) servers, allowing your AI agents to interact with external tools and services.
* **Catalogs**: [MCPMarket](https://mcpmarket.com/), [PulseMCP](https://www.pulsemcp.com/servers), [MCPServers.org](https://mcpservers.org/)

**Supported MCP Servers:**
* **Desktop Commander**: Grants terminal control and file system access. ([Source](https://github.com/wonderwhy-er/desktopcommandermcp))
* **Calculator**: A simple server for performing calculations. ([Source](https://github.com/githejie/mcp-server-calculator))
* **Context7**: Fetches up-to-date documentation and code examples. ([Source](https://github.com/upstash/context7)). https://context7.com/
* **GitHub**: Official server for interacting with GitHub issues, PRs, and repositories. ([Source](https://github.com/github/github-mcp-server))
* **Data Commons**: Tools and agents for interacting with the Data Commons Knowledge Graph using the Model Context Protocol (MCP). ([Source](https://github.com/datacommonsorg/agent-toolkit))



## Design Notes

### Notes on concept

AIStack defines 

* component : 
  * A component is any installable piece of software managed by AIStack.
  * A core component defines a piece of software mandatory for AIStack and always installed when initializing AIStack.
  * Each component has a `kind`, which defines its role in AIStack:
    - `module`
    - `runtime`
    - `tool`

* module :
  * A module is a kind of component used internally by AIStack.
  * The PATH of each module is always injected into AIStack run context and may be injected into each tool run context. 
    * Exception : when a module requires a runtime : the module PATH is not injected into AIStack run context and may be injected into each tool run context. 

* runtime : 
  * A runtime is a kind of component used to execute code (Python, Nodejs, and so on...). 
  * Runtimes are fully managed by AIStack and internally installed. 
  * A core runtime is mandatory and is always installed when initializing AIStack.
  * A runtime managed and installed by AIStack takes precedence over existing system runtimes.
  * The PATH of each runtime is not injected into AIStack run context but may be injected into each tool run context.

* tool :
  * Tools are the main purpose of AIStack : managing tools exposed for direct use by AIStack, agents, or users.
  * The PATH of each tool is not injected into AIStack run context but may be injected into each tool run context.
  * A launcher for each tool is generated and its PATH may be injected into shell context so that the tool can be used directly and autonomously.



### Notes on underlying framework: Stella

AIStack leverages the **[Stella](https://github.com/StudioEtrange/stella)** framework for its core functionality.
Stella provides the infrastructure for application structure, environment isolation, and package management. 

About *Package Management*: Stella uses a concept of "Features" (software packages) which are defined by "Recipes" (Bash scripts). `AIStack` uses this system to provide some of the components it manages or use. Stella features recipes are located in `pool/stella/nix/pool/feature-recipe/`.

## Contributors

See the [CONTRIBUTORS](CONTRIBUTORS) file for the full list of contributors

## License

Licensed under the **Apache License, Version 2.0**.

Copyright © 2025-2026 **Sylvain Boucault**.

See the [LICENSE](LICENSE) file for details.
