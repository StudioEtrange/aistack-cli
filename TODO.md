# TODO and VARIOUS NOTES

* process manager : goreman https://github.com/mattn/goreman
* MCP-cli
  * https://github.com/IBM/mcp-cli
  * CLI to connect and interact with MCP (Model Context Protocol) servers.
  * Manages conversation, tool invocation, session handling.
  * Supports chat, interactive shell, and automation via MCP.
  * Integrates with LLMs for reasoning and tool-based workflows.

* serving LLM
  * Lemonade
    * https://github.com/lemonade-sdk/lemonade
    * https://korben.info/lemonade-sdk-serveur-llm-local-npu-amd.html
    * Compared to Ollama, you gain the NPU Ryzen AI as well as audio functions (text-to-speech, transcription) and a graphical template manager for selecting your templates.
  * Serving LLM - Ollama vs vLLM : https://developers.redhat.com/articles/2025/08/08/ollama-vs-vllm-deep-dive-performance-benchmarking#comparison_2__tuned_ollama_versus_vllm
    * Ollama excels in its intended role: a simple, accessible tool for local development, prototyping, and single-user applications. Its strength lies in its ease of use, not its ability to handle high-concurrency production traffic, where it struggles even when tuned.
    * vLLM is unequivocally the superior choice for production deployment. It is built for performance, delivering significantly higher throughput and lower latency under heavy load. Its dynamic batching and efficient resource management make it the ideal engine for scalable, enterprise-grade AI applications.
* security tool : https://github.com/TheAuditorTool/Auditor
* Chrome DevTools MCP https://korben.info/chrome-devtools-mcp.html
* openclaw and cliproxyapi https://developer.tenten.co/openclaw-multi-agent-cliproxyapiplus-complete-deployment-guide
* n8n
* ollama
* voltagent
* litellm
* superpowers
* support bun configuration file and for bunx
* cam
* local doc querying through a mcp server : 
  * https://github.com/neuledge/context
  * npm package @neuledge/context
  * The search is currently keyword-based (FTS5 + BM25). It works well for direct queries like “middleware authentication” 
  * no semantic search
  * https://medium.com/@moshesimantov/i-built-a-context7-local-first-alternative-with-claude-code-eb14c9fd654f
  ```
  # Install
  npm install -g @neuledge/context

  # Add some docs
  context add https://github.com/vercel/next.js
  context add https://github.com/vercel/ai

  # Connect to your AI agent (Claude Code example)
  claude mcp add context -- context serve
  ```

* ghostdesk
  * MCP server over a linux desktop
  * https://korben.info/ghostdesk-agent-ia-bureau-linux-docker.html
  * https://github.com/YV17labs/GhostDesk
* Pi
  * agent tookkit
  * https://github.com/earendil-works/pi
  * https://pi.dev/
* OSD - Osmantic Deployment System (a.k.a Dream Server)
  * https://github.com/Light-Heart-Labs/ODS
  * https://korben.info/dream-server-ia-locale-auto-hebergee.html
  * complete local stack installer
  * Open WebUI, llama-server, Whisper, Kokoro, ComfyUI, Qdrant, SearXNG, n8n, ...
  * install.sh genere des conf avec des virgules au lieu de points . à contourner en relançant l'installeur avec LC_ALL=C : `LC_ALL=C ./install.sh`