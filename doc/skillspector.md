# NVIDIA skillspector

Security scanner for AI agent skills. Detect vulnerabilities, malicious patterns, and security risks. Can use a LLM for analysis.

* https://github.com/nvidia/skillspector

## Use LLM

* doc : https://github.com/NVIDIA/SkillSpector/blob/c2d09df019e358d3dc12d980b82c798b87cb9f56/docs/LLM_ANALYZER_BASE_GUIDE.md?plain=1#L579

* registered known models in yaml file
  * default file model_registry.yaml : https://github.com/NVIDIA/SkillSpector/blob/c2d09df019e358d3dc12d980b82c798b87cb9f56/model_registry.yaml
  * SKILLSPECTOR_MODEL_REGISTRY set a specific model file
  * model registry format :
    ```
    Format:
    models:
        "<model-label>":
        context_length: <int>          # total context window in tokens (required)
        max_output_tokens: <int>       # model's max output cap (optional)
    ```

* Use an OpenAI compatible endpoint sample

```
export SKILLSPECTOR_PROVIDER="openai"
export OPENAI_API_KEY="xxxxxxxxx"
export OPENAI_BASE_URL="http://localhost:11434/v1"
export SKILLSPECTOR_MODEL="llama3.1:8b"
skillspector scan ./my-skill/
```