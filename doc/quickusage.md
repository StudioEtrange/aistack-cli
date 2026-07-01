# Quick Usage

Right to the point how-to

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

_"I want to set the registry for npm package for the internal Node.js runtime."_

```
cd aistack-cli
./aistack npm config set registry https://registry.local.org/ -g
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

