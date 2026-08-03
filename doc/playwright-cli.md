# Playwright CLI

Playwright CLI is a command-line browser automation tool designed for coding agents. AIStack installs it with its isolated managed Node.js runtime and exposes it through the `plw` abbreviation.

## Links

* **Source**: [github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)
* **Documentation**: [playwright.dev/agent-cli/introduction](https://playwright.dev/agent-cli/introduction)

## Quickstart

Install the latest version:

```bash
./aistack plw install
```

Install a specific npm version:

```bash
./aistack plw install @1.2.3
```

Show installation information and version:

```bash
./aistack plw info
```

Launch commands in the current directory:

```bash
./aistack plw launch -- open https://playwright.dev --headed
./aistack plw launch -- screenshot
./aistack plw launch -- close
```

Launch in a specific project directory:

```bash
./aistack plw launch /path/to/project -- open https://playwright.dev
```

Install the optional Playwright skills for coding agents:

```bash
./aistack plw launch -- install --skills
```

Register the generated launcher in a shell PATH:

```bash
./aistack plw register bash
playwright-cli --help
```

Uninstall the tool and unregister its launcher:

```bash
./aistack plw uninstall
```


## skills


* official skill for playwright
  * microsoft/playwright-cli
  * `npm install -g @playwright/cli@latest`
  * Use `playwright-cli install --skills` to install those skills
* testdino-hq/playwright-skill
  * https://github.com/testdino-hq/playwright-skill
  * TestDino Playwright Skill: AI-powered guides for Playwright best practices, made by testdino.com.
* lackeyjb/playwright-skill
  * https://github.com/lackeyjb/playwright-skill/tree/main


## Notes

* The npm package is `@playwright/cli`; the installed command is `playwright-cli`.
* Playwright CLI requires Node.js 18 or newer. AIStack uses its managed Node.js runtime.
* Browser sessions, profiles, screenshots and other generated files are managed by Playwright CLI in the selected working directory or its own upstream defaults.
