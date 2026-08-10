# OpenChamber

OpenChamber is an open-source workspace for running and supervising OpenCode agents from a browser or an installable PWA or a desktop version.

OpenChamber installs its own opencode binary tool and use the standard opencode config file location, but you can use the one from AIStack using command `./aistack och connect aistack`. If you do so, OpenChamber will use opencode binary from AIStack.

## Links

* **Source**: [github.com/openchamber/openchamber](https://github.com/openchamber/openchamber)
* **Documentation**: [docs.openchamber.dev](https://docs.openchamber.dev/)
* **Website**: [openchamber.dev](https://openchamber.dev/)


## NOTES

- OpenChamber installs its own opencode binary tool and use the standard opencode config file location
- OpenChamber uses the login shell, adds the OpenCode binary to `PATH`, and requires a full restart after any environment or `PATH` changes.
- `OPENCODE_BINARY` allow to specify opencode binary and takes precedence over the default bundled binary, but the `settings.opencodeBinary` setting can override it.
- MacOS: When launched from Finder, OpenChamber initially receives the minimal macOS `PATH`: `/usr/bin:/bin:/usr/sbin:/sbin`. It then starts `/bin/zsh` as an interactive login shell and merges the resulting environment.
  
