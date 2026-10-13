# Ollama

[Ollama](https://github.com/ollama/ollama) runs language models locally.
AIStack installs the official CLI release, not the desktop application or a system service.

## Install and use

```bash
./aistack init # once, before using AIStack
./aistack ollama install
./aistack ollama info
./aistack ollama launch -- --version
./aistack ollama serve
```

`serve` runs in the foreground; Ctrl+C stops the server. In another terminal:

```bash
./aistack ollama pull llama3.2
./aistack ollama run llama3.2 "Hello!"
./aistack ollama list
./aistack ollama ps
./aistack ollama stop llama3.2
./aistack ollama show llama3.2
./aistack ollama rm llama3.2
```

Model downloads can be large. GPU support depends on the host hardware and drivers;
AIStack does not install drivers. The standard Linux archive is used (no optional
ROCm or JetPack archive). macOS uses `ollama-darwin.tgz`; Linux x86-64/ARM64 uses
`ollama-linux-<architecture>.tar.zst` and requires `zstd`, `curl`, and `tar` already
available. AIStack never runs the upstream system installer or uses `sudo`.
Older releases that do not provide these archive names are not supported.

An explicit version can be selected with `./aistack ollama install v0.40.3`
(the `v` prefix is optional). Installation failures before replacement leave the
previous binaries intact.

## Isolation and endpoint

`ollama info` prints the exact paths. Binaries and their libraries reside under
`workspace/<host>/isolated_dependencies/ollama`. Models reside under
`workspace/<host>/ollama/models`; keys and history are kept in the isolated
`workspace/<host>/ollama/.ollama` directory. The launcher sets `HOME` and
`OLLAMA_MODELS` only for the Ollama process, without changing the caller's shell.

The default endpoint is `127.0.0.1:11434`. To avoid conflicting with another
Ollama server, use the same `OLLAMA_HOST` for the server and clients:

```bash
OLLAMA_HOST=127.0.0.1:11435 ./aistack ollama serve
OLLAMA_HOST=127.0.0.1:11435 ./aistack ollama list
```

An existing server at the selected endpoint controls its own model storage;
use AIStack's `serve` command to use the isolated models directory.
Other native `OLLAMA_*` settings are passed through, except `OLLAMA_MODELS`,
which is deliberately set to AIStack's managed directory.

## Shell and VS Code registration

```bash
./aistack ollama register bash # or zsh, current, vs
# In a new terminal:
ollama list
```

`./aistack ollama launch -- <arguments>` forwards any native CLI arguments.
Common model commands are also available directly as `aistack ollama <command>`.

```bash
./aistack ollama unregister all
./aistack ollama uninstall
```

Stop the foreground server before uninstalling or upgrading. Uninstallation
removes binaries and launchers but preserves models, keys, and history.
