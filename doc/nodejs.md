# Node.js

- [Node.js](#nodejs)
  - [Notes](#notes)
  - [About MCP server](#about-mcp-server)
  - [Using a npm registry](#using-a-npm-registry)
  - [Using AIStack on old linux system with GBC](#using-aistack-on-old-linux-system-with-gbc)


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


## Using AIStack on old linux system with GBC

AIStack can support Node.js installation on old glibc system using https://github.com/StudioEtrange/glibc-binary-compat.git

1. Build a supported recent custom glibc for your system. Change target parameters in script. Default parameters will build a glibc 2.28 to be used on RedHat/Centos 7 OS which have by default a 2.17 glibc.


    ```
    cd $HOME
    git clone https://github.com/StudioEtrange/glibc-binary-compat.git
    cd glibc-binary-compat
    build-custom-glibc-runtime.sh
    sudo cp -R $HOME/custom-glibc228-runtime /opt
    sudo chmod -R a+rx /opt/custom-glibc228-runtime
    ```


2. Set `AISTACK_INIT_FORCE_NODE_GBC` variable with the PATH of the built glibc with GBC when init AIStack or installing Node.js runtime.

    ```
    cd $HOME
    git clone https://github.com/StudioEtrange/aistack-cli.git
    cd aistack-cli
    export AISTACK_INIT_FORCE_NODE_GBC="/opt/custom-glibc228-runtime"
    ./aistack-cli init
    ```