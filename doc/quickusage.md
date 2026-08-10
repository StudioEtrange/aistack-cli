# Quick Usage Cases

Right to the point how-to

- [Quick Usage Cases](#quick-usage-cases)
  - [Case 0 : AIStack install and init](#case-0--aistack-install-and-init)
  - [Case 1 : Antigravity CLI](#case-1--antigravity-cli)
  - [Case 2 : Kilo Code VS Code extension + OpenAI](#case-2--kilo-code-vs-code-extension--openai)
  - [Case 3 : Orla + OpenAI](#case-3--orla--openai)
  - [Case 4 : use Playwright CLI to take screenshot of a website](#case-4--use-playwright-cli-to-take-screenshot-of-a-website)
  - [Case 5 : OpenCode + OpenAI](#case-5--opencode--openai)
  - [Case 6 : OpenChamber desktop + OpenCode + OpenAI](#case-6--openchamber-desktop--opencode--openai)
  - [Case 7 : scan skills with NVIDIA skillspector + OpenAI](#case-7--scan-skills-with-nvidia-skillspector--openai)
  - [Case 8 : scan skills with Agent Skill Manager](#case-8--scan-skills-with-agent-skill-manager)
  - [Case 9 : scan skills with Cisco AI Skill Scanner + OpenAI](#case-9--scan-skills-with-cisco-ai-skill-scanner--openai)
  - [Case 10 : install the Rust runtime](#case-10--install-the-rust-runtime)
  - [Case 11 : Configure Node.js internal runtime](#case-11--configure-nodejs-internal-runtime)
  - [Case 12 : install gemini-cli](#case-12--install-gemini-cli)
  - [Case 13 : gemini-cli and local MCP server](#case-13--gemini-cli-and-local-mcp-server)

## Case 0 : AIStack install and init

_"I want to use any how-to from case list, I MUST launch this once first"_

**_AIStack installation and initialization_** :
```
git clone https://github.com/StudioEtrange/aistack-cli.git
cd aistack-cli
./aistack init
```

## Case 1 : Antigravity CLI

_"I want to install Antigravity CLI from scratch and make it accessible from all my bash session"_

**_AIStack installation and initialisation_** :
```
git clone https://github.com/StudioEtrange/aistack-cli.git
cd aistack-cli
./aistack init
```

**_Antigravity CLI installation, register and launch_** :
```
./aistack agy install
./aistack agy info
./aistack agy register bash
```

**_in another bash session, launch_** :
```
agy
```

## Case 2 : Kilo Code VS Code extension + OpenAI

_"I want to install Kilo Code VS Code extension aand using my OpenAI subscription with it."_

**_CPA installation and launch in background_** :

```bash
cd aistack-cli
./aistack cpa install
./aistack cpa up
./aistack cpa info
```

Use `./aistack cpa status` to check the CPA daemon, `./aistack cpa logs` to follow its logs, and `./aistack cpa down` to stop it.


**_Codex (OpenAI) login and model listing_** :
```bash
./aistack cpa login codex-oauth
./aistack cpa model list
```

**_Kilo Code installation_** :
```
./aistack kc install extension
```
**_Kilo Code connection_** :
```
./aistack kc connect cpa
```

To select an explicit default model and an optional small model:

```bash
./aistack kc connect cpa "gpt-5.6-sol" "gpt-5.6-luna"
```



## Case 3 : Orla + OpenAI

_"I want to install Orla agent and use it connected to my OpenAI subscription."_

**_CPA installation and launch in background_** :
```
cd aistack-cli
./aistack cpa install
./aistack cpa up
```
Use `./aistack cpa status` to check the CPA daemon, `./aistack cpa logs` to follow its logs, and `./aistack cpa down` to stop it.

**_Codex (OpenAI) login_** :
```
./aistack cpa login codex-oauth
./aistack cpa model list
```

**_orla installation_** :
```
./aistack orla install
```
**_orla connection_** :
```
./aistack orla connect agent cpa gpt-5.6-luna
```
**_orla agent test_** :
```
./aistack orla agent "Solve: If 2x + 3 = 7, what is x?"
```

## Case 4 : use Playwright CLI to take screenshot of a website

_"I want to install Playwright CLI, register it in shell and use it to take a screenshot of a website."_

```bash
cd aistack-cli
./aistack plw install
./aistack plw info
./aistack plw register bash
```

**_in another bash session, open webrowser and take a screenshot in current directory_** :

```bash
playwright-cli open https://github.com/StudioEtrange/aistack-cli --headed
playwright-cli screenshot
playwright-cli close
```

## Case 5 : OpenCode + OpenAI

_"I want to install OpenCode and using my OpenAI subscription with it."_

**_CPA installation and launch in background_** :
```bash
cd aistack-cli
./aistack cpa install
./aistack cpa up
```
Use `./aistack cpa status` to check the CPA daemon, `./aistack cpa logs` to follow its logs, and `./aistack cpa down` to stop it.

**_Codex (OpenAI) login and model listing_** :
```bash
./aistack cpa login codex-oauth
./aistack cpa model list
```

**_OpenCode installation and connection to CPA_** :

```bash
./aistack oc install
./aistack oc register bash

./aistack oc connect cpa
./aistack oc info
```

To select an explicit default model and an optional small model:
```bash
./aistack oc connect cpa "gpt-5.6-sol" "gpt-5.6-luna"
```

**_in another bash session, launch_** :
```
opencode
```

## Case 6 : OpenChamber desktop + OpenCode + OpenAI

_"I want to use OpenChamber Desktop with my installed OpenCode and using my OpenAI subscription."_ _(see [Case 5](#case-5--opencode--openai))_

```bash
./aistack och connect aistack
```

## Case 7 : scan skills with NVIDIA skillspector + OpenAI

_"I want to install NVIDIA skillspector and use it connected to my OpenAI subscription to scan skills."_

**_skillspector installation and launch_** :
```
./aistack sktor install
./aistack sktor register bash

./aistack sktor connect cpa gpt-5.4-mini
./aistack sktor launch
```

**_in another bash session, launch_** :
```
skillspector --help

cd $HOME
git clone https://github.com/anthropics/skills /tmp/skills

skillspector scan /tmp/skills/skills/algorithmic-art --no-llm --format markdown
skillspector scan /tmp/skills/skills/algorithmic-art --format markdown
skillspector scan /tmp/skills/skills/docx --no-llm  --format markdown
skillspector scan /tmp/skills/skills/docx --format markdown

rm -Rf /tmp/skills
```

## Case 8 : scan skills with Agent Skill Manager

_"I want to install Agent Skill Manager (asm) and use it to scan skills security and quality."_

**_asm installation and launch_** :
```
./aistack asm install
./aistack asm register bash

./aistack asm launch
```

**_in another bash session, launch_** :
```
asm --help
asm list
```

**_scan skill security_** :
```
asm audit security --json
asm audit security https://github.com/anthropics/skills/tree/main/skills/algorithmic-art
asm audit security https://github.com/anthropics/skills/tree/main/skills/algorithmic-art --json
asm audit security https://github.com/anthropics/skills/tree/main/skills/docx
```

**_scan skill quality_** :
```
git clone https://github.com/anthropics/skills /tmp/skills

asm eval /tmp/skills/skills/docx

rm -Rf /tmp/skills
```

## Case 9 : scan skills with Cisco AI Skill Scanner + OpenAI

_"I want to install Cisco AI Skill Scanner and use it connected to my OpenAI subscription to scan skills."_

**_CPA installation and launch in background_** :
```
cd aistack-cli
./aistack cpa install
./aistack cpa up
```
Use `./aistack cpa status` to check the CPA daemon, `./aistack cpa logs` to follow its logs, and `./aistack cpa down` to stop it.

**_Codex (OpenAI) login and model listing_** :
```
./aistack cpa login codex-oauth
./aistack cpa model list
```

**_Cisco AI Skill Scanner installation and connection_** :
```
./aistack ciss install
./aistack ciss register bash

./aistack ciss connect cpa "gpt-5.6-luna"
```

**_in another bash session, scan a skill_** :
```
skill-scanner --help

git clone https://github.com/anthropics/skills /tmp/skills

skill-scanner scan /tmp/skills/skills/algorithmic-art --use-behavioral
skill-scanner scan /tmp/skills/skills/algorithmic-art --use-behavioral --use-llm --format markdown

rm -Rf /tmp/skills
```

## Case 10 : install the Rust runtime

_"I want to use an isolated Rust toolchain without changing my system installation."_

```bash
cd aistack-cli
./aistack runtime add rust
./aistack rustc --version
./aistack cargo --version
```

Remove the managed Rust runtime with:

```bash
./aistack runtime remove rust
```

## Case 11 : Configure Node.js internal runtime

_"I want to set a npm registry for the internal Node.js runtime."_

```
cd aistack-cli
./aistack npm config set registry https://registry.local.org/ -g
```

_"When I init AIStack, which will install Node.js runtime and some npm packages, I want to set a npm registry for the internal Node.js runtime."_

```
export AISTACK_INIT_FORCE_NPM_REGISTRY="https://registry.local.org/"
cd aistack-cli
./aistack init
```

## Case 12 : install gemini-cli

_"I want to install gemini-cli from scratch and make it accessible from all my bash session"_

**_gemini-cli installation, register and launch_** :
```
cd aistack-cli
./aistack gc install
./aistack gc info
./aistack gc register bash
```
**_in another bash session, launch_** :
```
gemini
```

## Case 13 : gemini-cli and local MCP server

_"I want to register intoto gemini-cli installation, a local MCP server calculator to do some maths"_

**_register local MCP server calculator for gemini-cli_** :
```
cd aistack
./aistack gc mcp calculator install
```
