# Geiger

[Geiger](https://github.com/Atomburstofficial/geiger) inventories AI agents,
MCP servers, hooks, plugins and extensions and reports their capabilities and
exposure.

## Install and run

Initialize AIStack once with `./aistack init`, then:

```bash
./aistack geiger install
./aistack geiger info
./aistack geiger launch -- --help
./aistack geiger launch
```

AIStack installs the npm package `geiger-scan` (executable `geiger`) under
`workspace/<platform>/isolated/geiger`, using its managed Node.js
runtime (Node.js >=18 required). It does not use `npx` or install into the host's
global npm prefix. Installation scripts are disabled. Re-run `install` to update,
or select a version explicitly:

```bash
./aistack geiger install @0.4.0
```

Native options must follow `launch --`, or `launch <context folder> --`:

```bash
./aistack geiger launch /path/to/project -- --json inventory.json
./aistack geiger launch -- --path /path/to/project --html report.html
./aistack geiger launch -- --strict --diff baseline.json
./aistack geiger launch -- --home /path/to/another/home
```

The context folder becomes Geiger's working directory; relative report paths
are resolved there. Without a context folder, the caller's directory is kept.
Arguments and exit codes are forwarded unchanged, including exit code `2` from
`--strict` when Geiger finds relevant exposure (or new exposure with `--diff`).

## Register the launcher

```bash
./aistack geiger register          # current shell
./aistack geiger register bash
./aistack geiger register vs       # VS Code integrated terminal
```

After applying the registration in a new shell, run `geiger --help` or
`geiger --json inventory.json` directly.

```bash
./aistack geiger unregister        # all supported shells and VS Code
./aistack geiger uninstall
```

Uninstallation removes the package and launcher registrations, not your reports.

## Scan scope and privacy

Geiger scans known configuration locations and the current project (plus explicit `--path` directories). And analyse global npm installed packages. But config file path, node packages names and the way geiger find them are hardcoded. It detects only what it know and the way it know it is installed.
Nonstandard installation paths, including AIStack's isolated npm prefixes, are not necessarily detected; adding `--path` does not turn it into a recursive scan of all installed packages.

