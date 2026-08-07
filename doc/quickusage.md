# Quick Usage

Right to the point how-to

- [Quick Usage](#quick-usage)
  - [Case 0 : AIStack install and init](#case-0--aistack-install-and-init)
  - [Case 1 : Kilo Code in VS Code + OpenAI](#case-1--kilo-code-in-vs-code--openai)
  - [Case 2 : Configure Node.js internal runtime](#case-2--configure-nodejs-internal-runtime)
  - [Case 3 : install gemini-cli](#case-3--install-gemini-cli)
  - [Case 4 : gemini-cli and local MCP server](#case-4--gemini-cli-and-local-mcp-server)
  - [Case 5 : Orla + OpenAI](#case-5--orla--openai)
  - [Case 6 : scan skills with killspector + OpenAI](#case-6--scan-skills-with-killspector--openai)
  - [Case 7 : scan skills with asm](#case-7--scan-skills-with-asm)
  - [Case 8 : scan skills with Cisco AI Skill Scanner + OpenAI](#case-8--scan-skills-with-cisco-ai-skill-scanner--openai)
  - [Case 9 : install the Rust runtime](#case-9--install-the-rust-runtime)
  - [Case 10 : use Playwright CLI to take screenshot of a website](#case-10--install-playwright-cli)
  - [Case 11 : run OpenChamber Web with OpenCode](#case-11--run-openchamber-web-with-opencode)

## Case 0 : AIStack install and init

_"I want to use an how-to, I MUST launch once this"_

**_AIStack installation and initialization_** :
```
git clone https://github.com/StudioEtrange/aistack-cli.git
cd aistack-cli
./aistack init
```

## Case 1 : Kilo Code in VS Code + OpenAI

_"I want to install Kilo Code VS Code extension and use it connected to my OpenAI subscription."_

**_CPA installation and daemon start_** :
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
./aistack cpa info
```
* SEE http://localhost:8317/management.html 

**_kilocode installation_** :
```
./aistack kc install extension
```
**_kilocode connection_** :
```
./aistack kc connect cpa
```




## Case 2 : Configure Node.js internal runtime

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

## Case 3 : install gemini-cli

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

## Case 4 : gemini-cli and local MCP server

_"I want to register intoto gemini-cli installation, a local MCP server calculator to do some maths"_


**_register local MCP server calculator for gemini-cli_** :
```
cd aistack
./aistack gc mcp calculator install
```


## Case 5 : Orla + OpenAI

_"I want to install Orla agent and use it connected to my OpenAI subscription."_

**_CPA installation and daemon start_** :
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

## Case 6 : scan skills with killspector + OpenAI

_"I want to install skillspector and use it connected to my OpenAI subscription to scan skills."_

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

## Case 7 : scan skills with asm

_"I want to install agent skill manager (asm) and use it to scan skills security and quality."_

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

## Case 8 : scan skills with Cisco AI Skill Scanner + OpenAI

_"I want to install Cisco AI Skill Scanner and use it connected to my OpenAI subscription to scan skills."_

**_CPA installation, launch and Codex login_** :
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

**_Cisco AI Skill Scanner installation and connection_** :
```
./aistack ciss install
./aistack ciss register bash

./aistack ciss connect cpa gpt-5.4-mini
```

**_in another bash session, scan a skill_** :
```
skill-scanner --help

git clone https://github.com/anthropics/skills /tmp/skills

skill-scanner scan /tmp/skills/skills/algorithmic-art --use-behavioral
skill-scanner scan /tmp/skills/skills/algorithmic-art --use-behavioral --use-llm --format markdown

rm -Rf /tmp/skills
```

## Case 9 : install the Rust runtime

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

## Case 10 : use Playwright CLI to take screenshot of a website

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

## Case 11 : run OpenChamber Web with OpenCode

_"I want to install OpenChamber CLI/Web and use the OpenCode CLI managed by AIStack."_

```bash
cd aistack-cli
./aistack oc install
./aistack och install
./aistack och up
```

The UI password is generated automatically and displayed by `./aistack och info`. Manage the native OpenChamber daemon with:

```bash
./aistack och status
./aistack och logs
./aistack och restart
./aistack och down
```

Register the launcher to use OpenChamber from another shell:

```bash
./aistack och register bash
openchamber status
```
