# AIStack CLI — AGENTS.md

## 1. Project Overview

### Goal
AIStack CLI is a **Bash-based tool** that installs and configures AI tools (Gemini CLI, Opencode, Orla, CLIProxyAPI, MCP servers, etc.) in an **isolated environment**, without polluting the host system.

### Tech Stack
- **Language**: Bash (MUST be compatible with bash 3.2)
- **Entrypoint**: `./aistack`
- **Framework**: Stella  
  https://github.com/StudioEtrange/stella
- **Internal Libraries**: `lib/*.sh`
- **Tests**: Bats (`test/launch_test.sh`, `test/test/*.bats`)
- **Docs**: `README.md`, `doc/*.md`

---

## 2. Getting Started

### Initialization (MANDATORY)
Before using any command:

```bash
./aistack init
```

This installs dependencies and prepares the environment. This MUST be launch only once before using any AIStack CLI commands.

### Available Commands
All commands are defined in:
```
./aistack
```

---

## 3. Architecture & Design Principles

### Core Principles
- Keep `aistack` **thin** (menu only)
- Delegate logic to **domain modules**:
  ```
  lib/lib_<domain>.sh
  ```
- Use **submain scripts** for command wiring:
  ```
  lib/main_<domain>.sh
  ```

### Feature Addition Workflow
When adding a new feature:

1. Implement logic in:
   ```
   lib/lib_<domain>.sh
   ```
2. Expose command in:
   ```
   lib/main_<domain>.sh
   ```
3. Keep `aistack` minimal
4. Add documentation in:
   - `README.md`
   - `doc/<domain>.md`

---

## 4. Coding Standards

### Shell Compatibility
- MUST support **bash 3.2** (Linux + macOS)
- Avoid modern bash features (`mapfile`, associative arrays, etc.)

### Style Rules
- Always quote variables:
  ```bash
  "$VAR"
  ```
- Use **tabs** for indentation
- Prefer:
  ```bash
  local var="value"
  ```

### Error Handling
- Inside functions:
  ```bash
  return <code>
  ```
- Only CLI entrypoints may use:
  ```bash
  exit <code>
  ```

### Logging Convention
Use explicit prefixes:
```
ERROR: ...
WARN: ...
INFO: ...
```

### Environment Safety
- Minimize global side effects
- Keep `PATH` modifications controlled and scoped

---

## 5. Development Workflow

### While Coding
- Keep changes **small and focused**
- Avoid large refactors unless explicitly requested

### After Coding
- Run tests
- Validate CLI behavior
- Update documentation if needed

---

## 6. Testing

### Setup
```bash
./aistack init
```

### Minimum Checks
```bash
./test/launch_test.sh json
./test/launch_test.sh yaml
```

### Testing Policy
- Add/update Bats tests for functional changes
- Cover:
  - missing arguments
  - missing dependencies
  - invalid inputs
- Avoid reliance on network when possible

### Notes
Tests may depend on:
- network
- proxy
- certificates

If tests cannot run → document clearly.

---

## 7. Agent Behavior Rules

### General Behavior
- **Proactivity**: HIGH
- **Tone**: Professional, concise, technical

### Critical Rule
MUST ask for confirmation before:
- creating files (`write_file`)
- modifying files (`replace`)

### Commit Messages
Use **Conventional Commits**:
```
feat: add htop v3.2.2
fix: handle missing dependency
```

---

## 8. CLI UX Rules

- Never degrade CLI usability
- Always update:
  - help output
  - README
- Keep commands predictable and consistent

---

## 9. What to Avoid

- Adding global system dependencies without justification
- Mixing in the same commit:
  - style changes
  - functional changes
- Adding undocumented scripts

---

## 10. PR Checklist (REQUIRED)

- [ ] Changes are targeted and readable
- [ ] Documentation updated (README / doc/*)
- [ ] Tests executed (or limitation explained)
- [ ] No sensitive data added

---

## 11. Guiding Principle

When in doubt:
- Prefer small, testable, and reversible changes (`git revert` friendly)
