# Alternative glibc runtimes

AIStack can use custom glibc runtimes through [glibc-binary-compat](https://github.com/StudioEtrange/glibc-binary-compat) when an installed tool requires a newer glibc than the host system provides.

## Tool requirements

- Node.js requires glibc 2.28 or newer.
- Antigravity CLI requires glibc 2.28 or newer.
- llmfit requires glibc 2.39 or newer.

## Using AIStack on an old Linux system with GBC

1. Build the required custom glibc runtimes for your system. For example:

    ```bash
    cd "$HOME"
    git clone https://github.com/StudioEtrange/glibc-binary-compat.git
    cd glibc-binary-compat
    ./build-custom-glibc-runtime.sh "$HOME/custom-glibc228-runtime" "2.28"
    ./build-custom-glibc-runtime.sh "$HOME/custom-glibc239-runtime" "2.39"
    sudo cp -R "$HOME/custom-glibc228-runtime" /opt
    sudo cp -R "$HOME/custom-glibc239-runtime" /opt
    sudo chmod -R a+rx /opt/custom-glibc228-runtime /opt/custom-glibc239-runtime
    ```

    Build each runtime on a compatible system as explained by the glibc-binary-compat project.

2. Configure the paths of the available alternative glibc runtimes before initializing AIStack:

    - `AISTACK_GLIBC_217_PATH` for glibc 2.17
    - `AISTACK_GLIBC_228_PATH` for glibc 2.28
    - `AISTACK_GLIBC_239_PATH` for glibc 2.39

    AIStack detects the system glibc and selects an alternative according to each tool requirement. If the exact runtime is not configured, AIStack can use a newer configured runtime.

    ```bash
    cd "$HOME"
    git clone https://github.com/StudioEtrange/aistack-cli.git
    cd aistack-cli
    export AISTACK_GLIBC_228_PATH="/opt/custom-glibc228-runtime"
    export AISTACK_GLIBC_239_PATH="/opt/custom-glibc239-runtime"
    ./aistack init
    ```

## Override automatic glibc selection

You can set tool-specific environment variable to override automatic selection for that tool:

- `AISTACK_INIT_FORCE_NODE_GBC`
- `AISTACK_INIT_FORCE_AGY_GBC`
- `AISTACK_INIT_FORCE_LLMFIT_GBC`
