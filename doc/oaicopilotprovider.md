# OAI Compatible Provider for Copilot

* VS Code extension to use Openai/Ollama/Anthropic/Gemini API Providers in GitHub Copilot Chat
* https://github.com/JohnnyZ93/oai-compatible-copilot
* marketplace extension id : johnny-zhao.oai-compatible-copilot
* https://marketplace.visualstudio.com/items?itemName=johnny-zhao.oai-compatible-copilot
* configuration is in settings.json
    ```
    "oaicopilot.models": [
        {
            "id": "modelid",
            "owned_by": "aistack-cpa",
            "baseUrl": "http://127.0.0.1/v1",
            "context_length": 128000,
            "max_tokens": 4096,
            "apiMode": "openai",
            "temperature": 0
        }
    ]
    ```

## Supported procotols

* openai (default) - OpenAI Chat Completions API
  * Endpoint: /chat/completions
  * Header: Authorization: Bearer <apiKey>
  * Use for: Most OpenAI-compatible providers (ModelScope, SiliconFlow, etc.)

* openai-responses - OpenAI Responses API
  * Endpoint: /responses
  * Header: Authorization: Bearer <apiKey>
  * Use for: OpenAI official Responses API (and compatible gateways like rsp4copilot) 

* ollama - Ollama native API
  * Endpoint: /api/chat
  * Header: Authorization: Bearer <apiKey> (or no header for local Ollama)
  * Use for: Local Ollama instances

* anthropic - Anthropic Claude API
  * Endpoint: /v1/messages
  * Header: x-api-key: <apiKey>
  * Use for: Anthropic Claude models

* gemini - Gemini native API
  * Endpoint: /v1beta/models/{model}:streamGenerateContent?alt=sse
  * Header: x-goog-api-key: <apiKey>
  * Use for: Google Gemini models (and compatible gateways like rsp4copilot)

## Quickstart

* install
```
./aistack vs install johnny-zhao.oai-compatible-copilot
```

