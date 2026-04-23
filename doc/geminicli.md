# Gemini CLI

An open-source AI agent that brings the power of Gemini directly into your terminal.
* **Website**: [google-gemini.github.io/gemini-cli](https://google-gemini.github.io/gemini-cli)
* **Source**: [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
* **IDE Integration**: 
  * When you run Gemini CLI inside a supported editor, it will automatically detect your environment and prompt you to install Gemini Cli Companion.
  * Manual installation : use `/ide install` - if you install vscode extension with /ide install and have problem, just close and relaunch vscode
  * Other Manual Installation : https://marketplace.visualstudio.com/items?itemName=Google.gemini-cli-vscode-ide-companion
  * NOTE : gemini-cli can install vs code extensuib Gemini Cli Companion if binary code cli is in the PATH
* settings.json doc : https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html#settings-files

## NOTES

* Installing Gemini CLI with aistack set some convenient default settings
  * disable usage statistics
  * gemini-cli will read AGENTS.md by default
* Gemini CLI supports MCP Prompts as slash commands
* `/chat save` - saved chat history are in $HOME/.gemini/tmp
* gemini 2.5 pro is only free of charge when using google auth inside gemini-cli. If you set a gemini key, by using GEMINI_API_KEY, it will not be free (even if you previously with google auth)
* gemmini-cli Bridge API
  * 821 stars Expose Gemini CLI endpoints as OpenAI API (mainly on Cloudflare Workers) : https://github.com/GewoonJaap/gemini-cli-openai 
  * 20 stars - Use Gemini CodeAssist (Gemini CLI) through the OpenAI/Anthropic API : https://github.com/ubaltaci/gemini-cli-proxy
  * 48 stars - Gemini CLI wrapper to serve Gemini models through an OpenAI-compatible API : https://github.com/Brioch/gemini-openai-proxy
  * 127 stars - Wrap Gemini CLI as an OpenAI-compatible API service : https://github.com/nettee/gemini-cli-proxy
  * 720 stars - convert the OpenAI API protocol to the Google Gemini protocol : https://github.com/zhu327/gemini-openai-proxy https://deepwiki.com/zhu327/gemini-openai-proxy
  * 128 stars - Exposes all built-in tools from gemini-cli through a unified MCP endpoint and OpenAI-Compatible API Bridge https://github.com/Intelligent-Internet/gemini-cli-mcp-openai-bridge
  * 8900 stars - Wrap Gemini CLI, Antigravity, ChatGPT Codex, Claude Code, Qwen Code, iFlow as an OpenAI/Gemini/Claude/Codex compatible API service - https://github.com/router-for-me/CLIProxyAPI - https://github.com/brokechubb/cliproxyapi-installer
  * 106 stars - Experimental gemini-cli as MCP server : https://github.com/levindixon/gemini-cli-mcp-server
* LiteLLM and gemini-cli https://docs.litellm.ai/docs/tutorials/litellm_gemini_cli
* override gemini-cli with GEMINI_API_KEY, GEMINI_MODEL, GOOGLE_GEMINI_BASE_URL
* gemini-cli extensions : https://geminicli.com/extensions/
  * build extensions : https://geminicli.com/docs/extensions/writing-extensions/
  * extensions for gemini-cli are a package of
    * MCP Servers
    * Commands definition : /command which execute prompt or shell command
    * Context file : mardown file instructions
    * Agent skills : package of instructions (SKILL.md) and assets invoked on demand
    * Hooks : hooks in gemini cli lifecyle
    * Themes : change gemini cli appearance
* gemini-cli sandboxing : 
  * Command flag: -s or --sandbox
  * Environment variable: GEMINI_SANDBOX=true|docker|podman|sandbox-exec
  * Settings file: "sandbox": true in the tools object of your settings.json file (e.g., {"tools": {"sandbox": true}})
* License usage for gemini 
  * https://geminicli.com/docs/get-started/authentication/
* gemini-cli reads $HOME/.agents/skills and $HOME/.gemini/skills

## gemini cli A2A server 

* add a connectivity to use gemini-cli using A2A protocol
  * A2A protocol  ⇄  Gemini CLI (process local)

```
┌──────────────────────┐
│  Agent client A2A    │
└──────────┬───────────┘
           │ A2A
           ▼
┌──────────────────────┐
│ Gemini CLI A2A Server│
└──────────┬───────────┘
           │ stdin/stdout
           ▼
┌──────────────────────┐
│   Gemini CLI         │
└──────────────────────┘
```

* package npm 
  * https://www.npmjs.com/package/@google/gemini-cli-a2a-server
  * source code integrated in gemini-cli code source :
    * https://github.com/google-gemini/gemini-cli/tree/main/packages/a2a-server
* authentification mode used by A2A server
  * https://github.com/google-gemini/gemini-cli/blob/main/packages/a2a-server/src/config/config.ts

* bridge API connecting to A2A server : Gemini CLI - A2A API Proxy Server
  * https://www.npmjs.com/package/@vitorcen/gemini-cli-2-api
  * https://github.com/vitorcen/gemini-cli-2-api