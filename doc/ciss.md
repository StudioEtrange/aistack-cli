# Cisco AI Skill Scanner

Cisco AI Skill Scanner is a security scanner for AI agent skills. It combines static analysis, behavioral dataflow analysis, LLM semantic analysis, and optional cloud-based scanning.

* https://github.com/cisco-ai-defense/skill-scanner

## Installation

```bash
./aistack ciss install
./aistack ciss register bash
```

The `skill-scanner` command is then available in new Bash sessions. It can also be run without registering it in `PATH`:

```bash
./aistack ciss launch -- --help
```

## LLM Analysis

Connect to CLIProxyAPI using its first available model, or pass a model explicitly:

```bash
./aistack ciss connect cpa
./aistack ciss connect cpa gpt-5.4-mini
```

The integration configures the LLM analyzer through `SKILL_SCANNER_LLM_API_KEY`, `SKILL_SCANNER_LLM_MODEL`, `SKILL_SCANNER_LLM_PROVIDER`, and `SKILL_SCANNER_LLM_BASE_URL`. Launch scans with `--use-llm` to enable it:

```bash
skill-scanner scan ./my-skill --use-llm
```

Connect to another OpenAI-compatible provider:

```bash
./aistack ciss connect openai gpt-4o YOUR_API_KEY https://api.openai.com/v1
```

Disconnect any configured LLM:

```bash
./aistack ciss disconnect
```

## Scan Examples

```bash
# Core static, bytecode, and pipeline analyzers
skill-scanner scan ./my-skill

# Add dataflow analysis
skill-scanner scan ./my-skill --use-behavioral

# Analyze a repository with an LLM
skill-scanner scan-repo https://github.com/anthropics/skills --use-llm

# Produce a Markdown report
skill-scanner scan ./my-skill --use-behavioral --use-llm --format markdown
```
