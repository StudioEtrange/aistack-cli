# Antigravity CLI

Antigravity CLI is installed from the official Antigravity CLI release manifests.

Source installer:

```bash
https://antigravity.google/cli/install.sh
```

Install:

```bash
./aistack agy install
```

Register launcher in your shell PATH:

```bash
./aistack agy register bash
```

Launch:

```bash
./aistack agy launch -- --help
```

Show installation status:

```bash
./aistack agy info
```

Uninstall:

```bash
./aistack agy uninstall
```


## About tools commands deprecated commands

In Antigravity CLI, the `/tools` command from the legacy Gemini CLI has been split and replaced by more specialized commands to better manage Antigravity's modular and secure architecture: 

  •  `/mcp`: Lists and configures Model Context Protocol (MCP) servers and the external tools they expose.
  •  `/skills`: Lists the agent's active skills (encapsulated workflows and local capabilities).
  •  `/permissions`: Provides granular control over tool execution and access permissions (file access, command execution, HTTP requests).

## NOTES

* antigravity-cli fork verzion for android termux https://github.com/wallentx/antigravity-cli-termux
  * https://gist.github.com/Brajesh2022/e42160d29b55417db6c18c52dd1d6d37
* releases page : https://antigravity.google/releases