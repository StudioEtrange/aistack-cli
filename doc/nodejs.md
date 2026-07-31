# Node.js

- [Node.js](#nodejs)
  - [Node.js and glibc](#nodejs-and-glibc)
  - [Notes](#notes)
  - [About MCP server](#about-mcp-server)
  - [Using a npm registry](#using-a-npm-registry)


## Node.js and glibc

* Node.js requires glibc 2.28 or newer
* If you do not meet this requirement see [glibc](glibc.md)
  
## Notes 

* `npx` command needs at least `node` binary in PATH and `sh` binary in PATH


## About MCP server

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
            "PATH": "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}"
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

## Using a npm registry

* set a npm registry for Node.js at AIStack init

```
export AISTACK_INIT_FORCE_NPM_REGISTRY="https://registry.local.org/"
cd aistack-cli
./aistack init
```

* set a npm registry for Node.js

```
cd aistack-cli
./aistack npm config set registry https://registry.local.org/ -g
```


