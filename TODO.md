# NOTES, TODO and TO EXPLORE

## ressources links and information

* various AI tools catalog and cartography : https://stackmap.shipwithai.xyz/
* various AI topics and tools in french ; https://korben.info/categories/intelligence-artificielle/

## features TODO

* CPA : add a way to set port and host

* bun runtime : support bun configuration file and for bunx

* implements a generic gateway with a reverse proxy for all exposed component (cpa, opencode, ...)

* allow cpa to register ai endpoint with a command

* get llm metadata context size and prices
  * https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json

* in lib.sh, add tool require and detection same as module/runtime
  * aistack_tool_is_detected
  * aistack_tool_require
  * aistack_tool_uninstall
  * aistack_tool_install
    ```
    aistack_tool_install() {
        local t="$1"
        shift
        if ! xxx_install "$@"; then
            echo "ERROR: TOOL not installed"
            return 1
        else
            echo "Configuring TOOL"
            xxx_settings_configure
            vscode_settings_configure "xxx"
            xxx_launcher_manage
        fi
        aistack_tool_detect
        aistack_tool_context_file_generate
    }
    ```
  * add support for AISTACK_xxxx_TOOL_REQUIRED

* problem with cpa_daemon_restart, we want to keep the same args used for up command. Store args in file ?

* add a way to disable feature management in stella framework, to gain speed.

## TO EXPLORE

* ghostdesk
  * MCP server over a linux desktop
  * https://korben.info/ghostdesk-agent-ia-bureau-linux-docker.html
  * https://github.com/YV17labs/GhostDesk

* Pi
  * agent toolkit
  * https://github.com/earendil-works/pi
  * https://pi.dev/

* Swival
  * Coding Agent designed for tight context windows and limited resources. Reliable with small models. Context management is one of Swival's strengths
  * Manage context size with 7 level of compression, crypt password and key from context, optimize output of reading files
  * https://github.com/swival/swival
  * https://swival.dev/


* OSD - Osmantic Deployment System (a.k.a Dream Server)
  * https://github.com/Light-Heart-Labs/ODS
  * https://korben.info/dream-server-ia-locale-auto-hebergee.html
  * complete local stack installer
  * Open WebUI, llama-server, Whisper, Kokoro, ComfyUI, Qdrant, SearXNG, n8n, ...
  * install.sh genere des conf avec des virgules au lieu de points . à contourner en relançant l'installeur avec LC_ALL=C : `LC_ALL=C ./install.sh`

* CyberStrikeAI
  * https://github.com/Ed1s0nZ/CyberStrikeAI



* openclaw and cliproxyapiplus Deployment Guide https://developer.tenten.co/openclaw-multi-agent-cliproxyapiplus-complete-deployment-guide

* n8n
  * automation tool

* goreman
  * https://github.com/mattn/goreman
  * process manager

* MCP
  * MCP-cli
    * https://github.com/IBM/mcp-cli
    * CLI to connect and interact with MCP (Model Context Protocol) servers.
    * Manages conversation, tool invocation, session handling.
    * Supports chat, interactive shell, and automation via MCP.
    * Integrates with LLMs for reasoning and tool-based workflows.

  * Chrome DevTools MCP
    * https://github.com/ChromeDevTools/chrome-devtools-mcp
    * disable telemetry: `--no-usage-statistics`
    * mcp command to register: `npx -y "chrome-devtools-mcp@latest"`


* host LLM
  * Lemonade
    * https://github.com/lemonade-sdk/lemonade
    * https://korben.info/lemonade-sdk-serveur-llm-local-npu-amd.html
    * Compared to Ollama, you gain the NPU Ryzen AI as well as audio functions (text-to-speech, transcription) and a graphical template manager for selecting your templates.
  * Serving LLM - Ollama vs vLLM : https://developers.redhat.com/articles/2025/08/08/ollama-vs-vllm-deep-dive-performance-benchmarking#comparison_2__tuned_ollama_versus_vllm
    * Ollama excels in its intended role: a simple, accessible tool for local development, prototyping, and single-user applications. Its strength lies in its ease of use, not its ability to handle high-concurrency production traffic, where it struggles even when tuned.
    * vLLM is unequivocally the superior choice for production deployment. It is built for performance, delivering significantly higher throughput and lower latency under heavy load. Its dynamic batching and efficient resource management make it the ideal engine for scalable, enterprise-grade AI applications.
  * Rapid-MLX 
    * https://github.com/raullenchai/Rapid-MLX
    * only for macos with Apple Silicon
    * direclty use kernel MLX without intermediary
  * llama.cpp
    * `llama-server --reasoning auto --fit on -hf unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_XL`
      * (use --fit on to auto-size context to available memory)
  * ollama
    * https://github.com/ollama/ollama
    * ollama.com



* memory management
  * memvid
    * https://github.com/memvid/memvid
    * https://stackmap.shipwithai.xyz/repos/memvid/memvid?utm_source=substack&utm_medium=email
    * single-file memory layer for AI agents with instant retrieval and long-term memory. Persistent, versioned, and portable memory, without databases.

* neuledge/context
  * local doc querying through a mcp server
  * context7 alternative
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

* router
  * litellm
    * https://github.com/BerriAI/litellm


* optimization
  * headroom
    * https://github.com/headroomlabs-ai/headroom
    * https://docs.headroomlabs.ai/docs
    * context optimization layer
    * LLM request compression
    * act as a proxy
    * expose a MCP server
    ```
    Your agent / app
    (Claude Code, Cursor, Codex, LangChain, Agno, Strands, your own code)...
          │   prompts · tool outputs · logs · RAG results · files
          ▼
      ┌────────────────────────────────────────────────────┐
      │  Headroom   (runs locally — your data stays here)  │
      │  ────────────────────────────────────────────────  │
      │  CacheAligner  →  ContentRouter  →  CCR            │
      │                    ├─ SmartCrusher   (JSON)        │
      │                    ├─ CodeCompressor (AST)         │
      │                    └─ Kompress-v2-base (text, HF)  │
      │                                                    │
      │  Cross-agent memory  ·  headroom learn  ·  MCP     │
      └────────────────────────────────────────────────────┘
          │   compressed prompt  +  retrieval tool
          ▼
    LLM provider  (Anthropic · OpenAI · Bedrock...)
    ```

  * caveman
    * https://github.com/juliusbrussee/caveman
    * skills
    * reduce request size by removing useless word

  * optillm
    * Optimizing inference proxy for LLMs
    * https://github.com/algorithmicsuperintelligence/optillm

* web browser
  * BrowserClaw and BrowserOS
    * https://github.com/browseros-ai/browseros
    * BrowserClaw : MCP-compatible browser
    * BrowserOS : Chromium fork with an AI agent built into every new ta to chat with
  * browserwing
    * https://github.com/browserwing/browserwing
    * Native MCP & Skills protocol support
    * Visual Script Recording: Record browser actions, edit visually, and replay with precision
  * browser-use
    * https://github.com/browser-use/browser-use
    * Python library (`uv add browser-use`) with human described task to interact with browser
    * integration with ai agent with a skill https://github.com/browser-use/browser-harness/blob/main/install.md




* llamafile
  * https://github.com/mozilla-ai/llamafile
  * make LLM distributable as executable. To interact with LLM it includes a chat box (in TUI), a cli and an OpenAI Compatible API

* OpenRAG
  * https://github.com/langflow-ai/openrag  
  * RAG Platform. Ingestion, indexing, search and Q&A, Interface drag-and-drop
  * Built on Langflow, Docling, and Opensearch.

* privacy-filter
  * https://github.com/openai/privacy-filter
  * https://huggingface.co/openai/privacy-filter
  * open source model that detect privacy data
  * best work on english text


* Text To Speech
  * Qwen3-TTS
    * https://github.com/QwenLM/Qwen3-TTS
    * Qwen3-TTS is an open-source series of TTS models developed by the Qwen team at Alibaba Cloud, supporting stable, expressive, and streaming speech generation, free-form voice design, and vivid voice cloning.
  * LuxTTS
    * https://github.com/ysharma3501/LuxTTS
    * fast model
  * Chatterbox Multilingual TTS
    * https://github.com/resemble-ai/chatterbox
    * Chatterbox is a family of state-of-the-art, open-source text-to-speech models 
  * Voicebox
    * https://github.com/jamiepine/voicebox
    * Desktop App - Clone voices, generate speech across seven TTS engines
    * https://voicebox.sh/


* subwave
  * https://github.com/perminder-klair/subwave
  * https://www.getsubwave.com/
  * Personal internet radio with AI - stream music (icecast), not a playlist
  * use liquidsoap (https://www.liquidsoap.info/)
  * use navidrome : 
    * streaming audio service
    * https://github.com/navidrome/navidrome/
    * https://www.navidrome.org

* Alexandria
  * https://korben.info/alexandria-ebook-livre-audio-multivoix.html
  * at least 8 GB of VRAM (16+ GB for decent performance);
  * generate multi-voice audiobooks entirely locally, using an LLM to annotate the text for each character and the Qwen3-TTS (https://github.com/QwenLM/Qwen3-TTS) to generate audio. Offers 9 pre-trained voices, voice cloning from 5–15 seconds of audio, voice generation via text description. 



* Spec-Driven Development Methodology framework
  * superpowers
    * https://github.com/obra/superpowers
  * conductor
    * https://github.com/gemini-cli-extensions/conductor



* agent orchestrator
  * oh-my-openagent (aka OmO) (formely oh-my-opencode)
    * https://github.com/code-yeongyu/oh-my-openagent
    * for OpenCode
    * telemetry: set "telemetry": false in oh-my-openagent config, OMO_DISABLE_POSTHOG=1, or OMO_SEND_ANONYMOUS_TELEMETRY=0
  * LazyCodex
    * https://lazycodex.ai/
    * https://github.com/code-yeongyu/lazycodex
    * LazyCodex is a light version of OmO but for Codex cli
    * telemetry: OMO_CODEX_DISABLE_POSTHOG=1 or OMO_CODEX_SEND_ANONYMOUS_TELEMETRY=0
  * oh-my-codex (aka OmX)
    * https://github.com/Yeachan-Heo/oh-my-codex
    * https://oh-my-codex.dev/
    * Multi-agent orchestration layer for OpenAI Codex CLI. Build faster with staged team pipelines, persistent memory/state MCP servers, and extensible hooks.
  * oh-my-claudecode (aka OmC)
    * https://github.com/yeachan-heo/oh-my-claudecode
    * https://oh-my-claudecode.dev/
    * Claude, Codex, and Gemini CLI workers running in parallel tmux panes — each doing what it does best.
  * oh-my-antigravity
    * for gemini-cli and antigravity cli
    * https://github.com/Joonghyun-Lee-Frieren/oh-my-antigravity
  * oh-my-opencode-slim
    * https://github.com/alvinunreal/oh-my-opencode-slim
    * https://ohmyopencodeslim.com/
    * Lean, fine tuned Opencode multi agent suite · Mix any models · Auto delegate tasks