# Node.js

- [Node.js](#nodejs)
  - [Choosing the core Node.js version](#choosing-the-core-nodejs-version)
  - [Node.js and glibc](#nodejs-and-glibc)
  - [Notes](#notes)
  - [About MCP server](#about-mcp-server)
  - [Set a cache path for nvm binaries](#set-a-cache-path-for-nvm-binaries)
  - [Using your own npm registry](#using-your-own-npm-registry)


## Choosing the core Node.js version

Set `AISTACK_INIT_FORCE_NODE_VERSION` when initializing AIStack to choose the managed core runtime instead of the latest LTS:

```bash
AISTACK_INIT_FORCE_NODE_VERSION=22 ./aistack init
AISTACK_INIT_FORCE_NODE_VERSION=22.14.0 ./aistack init
```
Accepted formats are a major version (`22`), major.minor (`22.14`), or an exact version (`22.14.0`), optionally prefixed with `v`. NVM resolves partial versions to the latest matching release. Invalid formats or unavailable versions cause initialization to fail.

Without this variable (or when empty), initialization installs the latest LTS. The variable also applies to `init reinstall`. See [Node.js version selection](doc/nodejs.md#choosing-the-core-nodejs-version) for details.



## Selecting a version after initialization

To select a managed Node.js version after initialization:

```bash
./aistack runtime add nodejs 24.1
./aistack node --version
```

The version argument accepts a major, major.minor or exact version, optionally prefixed with `v`. `24.1` selects the latest `24.1.x`, even when another version is installed, and refreshes launchers and contexts. Older versions are not removed. The argument overrides `AISTACK_INIT_FORCE_NODE_VERSION` for this command only. The installer runs even when Node.js is already installed. Without a version argument, it selects the environment variable or the latest LTS, rather than leaving the active version unchanged. NVM reuses the selected release if it is already installed. Other runtimes do not accept a version argument.

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
  export PATH="/home/nomorgan/workspace/aistack/workspace/isolated/nodejs/bin/:${PATH}"
  exec "npx" -y @upstash/context7-mcp --api-key "${CONTEXT7_API_KEY}"
  ```

## Set a cache path for nvm downloaded binaries

- define AISTACK_NVM_BIN_CACHE before using aistack

  ```
  export AISTACK_NVM_BIN_CACHE=/opt/nvm-bin-cache
  cd aistack-cli
  ./aistack init
  ```

- sample usage with a shared folder on a host mounted as volume in containers

  ```
  sudo mkdir -p /opt/nvm-bin-cache
  sudo chmod -R 777 /opt/nvm-bin-cache

  # launch containers with --volume /opt/nvm-bin-cache:/opt/nvm-bin-cache

  # inside containers
  export AISTACK_NVM_BIN_CACHE=/opt/nvm-bin-cache
  cd aistack-cli
  ./aistack init
  ```

## Using your own npm registry

* set a npm registry for Node.js at AIStack init

```
export AISTACK_INIT_FORCE_NPM_REGISTRY="https://registry.local.org/"
cd aistack-cli
./aistack init
```

* set a npm registry for Node.js (it is redundant if you have already done using AISTACK_INIT_FORCE_NPM_REGISTRY)

```
cd aistack-cli
./aistack npm config set registry https://registry.local.org/ -g
```
