# OpenChamber CLI/Web

OpenChamber is an open-source workspace for running and supervising OpenCode agents from a browser or installable PWA.

## Links

* **Source**: [github.com/openchamber/openchamber](https://github.com/openchamber/openchamber)
* **Documentation**: [docs.openchamber.dev](https://docs.openchamber.dev/)
* **Website**: [openchamber.dev](https://openchamber.dev/)
* **Guide**: https://zread.ai/btriapitsyn/openchamber/2-quick-start

## Requirements

* Node.js 22 or newer.
* OpenCode CLI. Install it with `./aistack oc install`.

## Quickstart

Install OpenCode and the latest OpenChamber CLI/Web:

```bash
./aistack oc install
./aistack och install
```

Install a specific npm version:

```bash
./aistack och install @1.18.0
```

Start the local Web/PWA server:

```bash
./aistack och up -- --host 127.0.0.1 --port 3000
```

AIStack automatically creates and uses an OpenChamber UI password:

```bash
./aistack och info
```

The password is stored in `~/.config/openchamber/ui-password`, or under `OPENCHAMBER_DATA_DIR` when that variable is set. It is recreated when OpenChamber is installed and passed through `OPENCHAMBER_UI_PASSWORD`, so it is not exposed in the process arguments. `och up` and `och restart` reject a manual `--ui-password` option.

OpenChamber manages its own daemon, PID files, instance registry and logs through its native lifecycle commands:

```bash
./aistack och status
./aistack och logs
./aistack och restart
./aistack och down
```

Native OpenChamber options are forwarded:

```bash
./aistack och status -- --json
./aistack och logs -- --no-follow
./aistack och down -- --port 3000
```

Launch in a specific project directory:

```bash
./aistack och up /path/to/project -- --port 3000
```

Run any OpenChamber command through the managed environment:

```bash
./aistack och launch -- connect-url --qr
./aistack och launch -- tunnel providers --json
./aistack och launch -- startup status --json
```

Show installation information:

```bash
./aistack och info
```

Uninstall OpenChamber while preserving its upstream configuration and data:

```bash
./aistack och uninstall
```

## Security

OpenChamber listens on `127.0.0.1` by default. Keep this default unless remote access is required. When using `--lan` or `--host 0.0.0.0`, use `--ui-password` and only expose the service on a trusted network.

## Notes

* The npm package is `@openchamber/web`; the installed command is `openchamber`.
* AIStack installs the package globally in its isolated managed Node.js runtime. It does not use npm `--prefix`.
* all openchamber environment variables: https://github.com/syntax-syndicate/opencode-chamber/blob/main/packages/docs/content/docs/environment.mdx
    ```
    OPENCODE_BINARY: path to OpenCode
    OPENCHAMBER_DATA_DIR: Configuration and runtime data
    OPENCHAMBER_UI_PASSWORD
    OPENCHAMBER_HOST: 0.0.0.0  # Bind address


    # use an external opencode instance
    OPENCODE_HOST: http://172.17.0.1:4096 # Connect to external OpenCode server
    OPENCODE_SKIP_START: true
    OPENCODE_SKIP_START

    # bind the internal opencode server controlled by openchamber to adress instead of localhost only 
    OPENCHAMBER_OPENCODE_HOSTNAME: 0.0.0.0 
    ```
