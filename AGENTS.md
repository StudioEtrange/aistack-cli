# AIStack CLI

## 1) Project goal

AIStack CLI is a Bash-based orchestrator that installs and configures AI tools (Gemini CLI, Opencode, Orla, CLIProxyAPI, MCP servers and others) in an isolated environment, without polluting the host system.

## 2) Stack & repository structure

- **Primary language**: Bash
- **CLI entrypoint**: `./aistack`
- **Domain libraries**: `lib/*.sh`
- **Underlying bash framework**: Stella (`pool/stella/...`, `stella-link.sh`) https://github.com/StudioEtrange/stella
- **Tests**: Bats (`test/launch_test.sh`, `test/test/*.bats`)
- **Docs**: `README.md` and `doc/*.md`

## 3) Contribution rules

1. **Preserve Bash portability** (Linux/macOS): avoid non-portable shell features.
2. **Minimize global side effects**:
   - prefer `local` inside functions,
   - keep `PATH` mutations scoped and intentional.
3. **Use consistent error handling**:
   - prefer `return <code>` inside functions,
   - reserve `exit <code>` for CLI entrypoints.
4. **Keep logs actionable**:
   - recommended prefixes: `ERROR: ...`, `WARN: ...`, `INFO: ...`.
5. **Do not regress CLI UX**:
   - keep help/usage output updated when commands change.

## 4) Recommended workflow

While coding:
- keep changes small and focused;
- avoid broad refactors unless explicitly requested.

After coding:
- run relevant checks (see section 6);
- update user documentation when behavior changes.


## 5) AIStack CLI usage

Before using any AIStack CLI commands:
- the current execution environment must be initialized before using any aistack commands at least once to install needed dependencies, using command 
```bash
./aistack init
```

Available commands:
- Available commands are listed in `aistack` file.

## 6) Test commands

Before testing:
- the current execution environment must be initialized at least once to install needed dependencies, using command 
```bash
./aistack init
```

### Minimum checks

```bash
./aistack init
./test/launch_test.sh json
./test/launch_test.sh yaml
```

### Useful optional checks (if available)

Notes:
- Tests may depend on network/proxy/certificate setup during dependency bootstrap.
- If environment constraints block a check, document that clearly in your summary.

## 7) Guidelines for new features

- Add new functions in the closest domain module (`lib/lib_<domain>.sh`).
- Keep orchestration logic in `aistack` lightweight.
- If you add a subcommand:
  1. implement behavior in the proper module,
  2. wire the command in `aistack`,
  3. document it in `README.md`.

## 8) Testing policy

For functional changes:
- add or update at least one Bats test when reasonable;
- cover error cases (missing arguments, missing files, missing dependencies);
- avoid coupling unit tests to live network downloads.

## 9) PR checklist (required)

- [ ] Changes are targeted and readable.
- [ ] Help/README updated when needed.
- [ ] Relevant tests executed (or environment limitation explained).
- [ ] No sensitive data added (tokens, API keys, private paths).

## 10) What to avoid

- Adding non-isolated global system dependencies without clear justification.
- Adding ad hoc scripts without documentation.
- Mixing large style-only edits with functional changes in the same commit.


When in doubt :
- prefer small, testable, and easily reversible changes (`git revert`).