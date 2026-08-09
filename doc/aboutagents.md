# Agent Topics

* AGENTS.md file specification : https://agents.md/


## Agent Anatomy

```
X Agent UI
┌────────────────────────────────────┐
│ CLI/Desktop/Web interface          │
│                                    │
│  X Agent                           │
│  ┌──────────────────────────────┐  │
│  │ X Agent harness              │  │
│  │  ├─ agent loop               │  │
│  │  ├─ orchestration            │  │
│  │  ├─ context management       │  │
│  │  ├─ tool management          │  │
│  │  └─ skill management         │  │
│  │                              │  │
│  │ + LLM                        │  │
│  │ + tools                      │  │
│  │ + skills                     │  │
│  │ + instructions / context     │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘

X = Copilot, Opencode, Claude Code, ...
X Agent         = The agent
X Agent UI      = user interface UI (CLI/Desktop/Web)
X Agent harness = orchestration/runtime layer that hosts, runs and controls the agent
LLM             = model used by X Agent
```

## Acronym

* A2A: Agent to Agent
  * agent ↔ agent 
  * detail: X Agent ↔ A2A interface/endpoint ↔ A2A interface/endpoint ↔ X Agent
  * ie: Travel Planning Agent ↔ Flight Booking Agent
  * https://a2a-protocol.org/
  * A2A is for agent-to-agent communication: as a universal, decentralized standard, A2A lets independent agents — including those using MCP — discover each other, delegate tasks, and share results.

* MCP: Model Context Protocol
  * agent ↔ tools 
  * detail: X Agent (= MCP Host) ↔ MCP Client ↔  MCP Server
  * ie: Antigravity CLI ↔ MCP GitHub Server
  * https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro
  * MCP is for agent-to-tool communication: it standardizes how an agent connects to its tools, APIs, and resources to get information.

  ```
  X Agent (= MCP Host)
  ├── X Agent harness
  └── MCP Client ─── MCP ─── MCP Server (remote or local)
                                  ├── tools
                                  ├── resources
                                  └── prompts
  ```


* AHP: Agent Host Protocol
  * client(s) ↔ Agent Host persistant ↔ agent harness
  * detail: client(s) ↔ Agent Host ↔ X Agent harness
  * ie: VS Code ↔ VS Code Agent Host ↔ Copilot CLI agent harness
  * https://microsoft.github.io/agent-host-protocol/
  * standard of how clients (an AHP client like vscode) connect to a persistent agent runtime to manage and interact with agent sessions.

* ACP: Agent Client Protocol
  * IDE/editor ↔ coding agent
  * detail: IDE/editor ↔ X Agent
  * ie: JetBrains IDE ↔ Gemini CLI
  * https://agentclientprotocol.com/
  * standard of how editors and other clients connect to coding agents, exchange prompts and context, stream responses, and invoke agent capabilities.

* ADK: Agent Development Kit
  * https://adk.dev/
  * The Agent Development Kit (ADK) for Python, TypeScript, Go, Java, and Kotlin, is a flexible and modular framework for developing and deploying AI agents.
  * complex sample using agents built in Python, Node, GO and Rust with native libraries or with ADK and communicating with A2A and connected to a cli (antigravity-cli or gemini-cli) with MCP
    * https://medium.com/google-cloud/cross-language-a2a-agent-benchmarking-with-antigravity-cli-ff8689b1d264
    * https://medium.com/google-cloud/cross-language-a2a-agent-benchmarking-with-gemini-3-and-gemini-cli-930eb3fd8507
    * https://github.com/xbill9/a2a-benchmark



## Ressources

* multica
  * https://github.com/multica-ai/multica
  * https://multica.ai/
  * Web IDE + services - 15k stars 1,8k forks - last activity april 26
  * The open-source managed agents platform. Turn coding agents into real teammates — assign tasks, track progress, compound skills.

* agent framework or orchestration methods :
  * superpowers
    * https://github.com/obra/superpowers/tree/main
  * BMAD
    * https://github.com/bmad-code-org/BMAD-METHOD
  * GSD - get-shit-done
    * https://github.com/gsd-build/get-shit-done

* voltagent
  * platform multi-agent systems — development, observability, and deployment
  * need to write agent in TypeScript
  * https://github.com/voltagent/voltagent/
  * https://voltagent.dev/
  * 8k stars 811 forks

* various ressources type
  * https://github.com/VoltAgent?q=awesome&type=all&language=&sort=


## Personal agent

### openclaw alternatives focus on private and self hosted :

* Vellum
  * https://www.vellum.ai/
  * https://github.com/vellum-ai/vellum-assistant

* zeroclaw
  * https://github.com/zeroclaw-labs/zeroclaw
  * https://www.zeroclawlabs.ai/
  * self host
  * rust based
  * any OS

* Hermes Agent
  * https://github.com/nousresearch/hermes-agent
  * statefull by design - each session is turn into a skill to improve next session

## Context files (aka Rules)

* Context files location
  * about gemini : https://antigravity.google/docs/gcli-migration
    | *SCOPE* | Gemini CLI | Antigravity CLI |
    | ---- | ---- | ---- |
    | *Global* | ~/.gemini/GEMINI.md | ~/.gemini/GEMINI.md |
    | *Workspace* | ./GEMINI.md and ./AGENTS.md | ./GEMINI.md and ./AGENTS.md |


## MCP servers

* MCP transport mpde
  * stdio: mcp client contact mcp servers on the same host, using stdio
    * the mcp client will start mcp server itself, with the command provided in its definition
  * http: mcp client contact mcp servers using http
    * the mcp servers must be started before

* MCP files location
  * about gemini : https://antigravity.google/docs/gcli-migration
    | *SCOPE* | Gemini CLI | Antigravity CLI |
    | ---- | ---- | ---- |
    | *Global* | ~/.gemini/settings.json | ~/.gemini/antigravity-cli/mcp_config.json |
    | *Workspace* | .gemini/settings.json | .agents/mcp_config.json |

## Skills

* doc and specifications :
  * https://agentskills.io/
  * https://github.com/agentskills/agentskills

* skills files location
  * about gemini : https://antigravity.google/docs/gcli-migration
    | *SCOPE* | Gemini CLI | Antigravity CLI |
    | ---- | ---- | ---- |
    | *Global* | ~/.gemini/skills/ | ~/.gemini/antigravity-cli/skills/  |
    | *Workspace* |.gemini/skills/ or .agents/skills/ | .agents/skills/ |

### skills catalogs

* Anthropic skills
  * https://github.com/anthropics/skills
* officials skills - skills developped by major ai actor or company
  * https://officialskills.sh/
  * https://github.com/VoltAgent/awesome-agent-skills
* VoltAgent clawskills
  * https://github.com/VoltAgent/awesome-openclaw-skills
  * https://clawskills.sh/
* MCPMarket
  * https://mcpmarket.com/tools/skills
* Will McGinnis's python development
  * https://github.com/wdm0006/python-skills
  * https://mcginniscommawill.com/guides/python-library-development/
* https://github.com/mattpocock/skills
* Agent Skill Manager catalog
  * https://luongnv.com/asm/#/skills

### skills tools

* skills registry hostable :
  * skillhub
    * https://github.com/iflytek/skillhub
    * 2,6k stars 328 forks - last activity april 26

* skills manager :
  * vercel labs skills
    * https://github.com/vercel-labs/skills
    * https://www.npmjs.com/package/skills
    * CLI - 20k stars - last activity may 26
    * package npm
    * list, manage, download skills from various location
  * skillfish
    * https://github.com/knoxgraeme/skillfish
    * CLI - 186 stars 15 forks - last activity april 26
    * https://www.skill.fish/
  * xingkongliang/skills-manager
    * https://github.com/xingkongliang/skills-manager
    * Desktop IDE and CLI - 663 stars 63 forks - last activity april 26
    * can manage group (aka preset) of skills
  * jiweiyeah/Skills-Manager
    * https://github.com/jiweiyeah/Skills-Manager
    * Desktop IDE - 526 stars 32 forks - last activity march 26
  * openskills
    * https://github.com/numman-ali/openskills
    * CLI - 10k stars 616 forks - last activity jan 26
    * forks analysis
    
    |fork|ahead|  behind|  stars|  last_commit_date|      pushed_at|             url|
    |-|-|-|-|-|-|-|
    |ain3sh/openskills|133|    26|      10|     2026-01-19T01:31:03Z|  2026-01-19T01:31:20Z|  https://github.com/ain3sh/openskills|
    |mandersogit/py-openskills|    26|     25|      0|      2025-11-23T21:58:18Z|  2025-11-23T21:58:21Z|  https://github.com/mandersogit/py-openskills|
    |otkHsiao/openskills|    13|     0|       0|  2026-01-22T11:04:33Z|  2026-01-22T11:04:39Z|  https://github.com/otkHsiao/openskills|

  * asm - agent-skill-manager
    * https://github.com/luongnv89/asm
    * CLI - 197 stars 13 forks - last activity april 26
    * https://luongnv.com/asm/
    * use central folder and symlink to agent skill folder
    * list, manage, download skills from various location (i.e `asm install https://github.com/anthropics/skills/tree/main/skills/algorithmic-art`)
  * Rito-w/skills-manager
    * https://github.com/Rito-w/skills-manager
    * Desktop IDE - 146 stars 10 forks - last release april 26
