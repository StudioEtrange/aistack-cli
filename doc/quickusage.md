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

**_CPA installation and launch_** :
```
cd aistack-cli
./aistack cpa install
./aistack cpa launch
```

**_in another terminal, Codex (OpenAI) login_** :
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
**_kilocode extension test_** :
* in kilocode extension, in the model selector choose a model from provider `AIStack CLIProxyAPI`

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

**_CPA installation and launch_** :
```
cd aistack-cli
./aistack cpa install
./aistack cpa launch
```

**_in another terminal, Codex (OpenAI) login_** :
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
