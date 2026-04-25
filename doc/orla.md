****# Orla

* https://github.com/dorcha-inc/orla
* doc : https://orlaserver.github.io/#/


## Quickstart

install
```
./aistack orla install
```

info
```
./aistack orla info
```

* Use orla in agent mode

  connect orla agent mode to cpa
  ```
  ./aistack orla connect agent cpa # cpa should be launched first to determine the default model for agent mode
  ./aistack orla info
  ./aistack orla show-config
  ```

  launch orla standalone agent
  ```
  # use a model of the default backend
  ./aistack orla agent "tell me a short story in two sentences and 512 caracters max" -m "openai:gpt-5.2"

  # use the default model of the default backend
  ./aistack orla agent "tell me a short story in two sentences and 512 caracters max"


  ```

* Use orla in service mode

  launch orla API service
  - NOTE : The Orla API service do not use the default backend registered in config file
  ```
  ./aistack orla serve
  ```

  get service health
  ```
  curl -s http://localhost:8081/api/v1/health
  ```

  register a backend
  ```
  ./aistack orla connect serve cpa gemini-2.5-flash-lite
  ```

  manualy register a backend
  - NOTE : the must be defined in the orla context server - AISTACK_CLIPROXYAPI_KEY_FOR_ORLA is auto generated aistack-cli when `./aistack orla connect cpa`
  ```
  curl -X POST http://localhost:8081/api/v1/backends \
    -H "Content-Type: application/json" \
    -d '{
      "name": "cpa",
      "endpoint": "http://localhost:8317/v1",
      "type": "openai",
      "api_key_env_var": "AISTACK_CLIPROXYAPI_KEY_FOR_ORLA",
      "model_id": "openai:gemini-2.5-flash"
    }'
  ```


  list registed backend into orla API service
  ```
  curl -s http://localhost:8081/api/v1/backends
  ```

  request orla API service
  ```
  curl -X POST http://localhost:8081/api/v1/execute \
    -H "Content-Type: application/json" \
    -d '{
      "backend": "cpa",
      "prompt": "Tell me a short, cheerful story about a cat called Lily. One or Two sentences is enough.",
      "max_tokens": 512,
      "stream": false
    }'
  ```