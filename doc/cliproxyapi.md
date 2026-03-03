
# CLIProxyAPI

CLIProxyAPI is a tool that bridges the gap between command-line interfaces and AI models, enabling seamless integration and interaction.

## Links

  * https://help.router-for.me/
  * https://github.com/router-for-me/CLIProxyAPI
  * https://github.com/router-for-me/CLIProxyAPIPlus
  * Installer project : https://github.com/brokechubb/cliproxyapi-installer

## Quickstart

install
```
./aistack cpa install
```

launch
```
./aistack cpa launch
```

authenticate to gemini cli
requirements : gemini-cli configured `./aistack gc install`
note : The local OAuth callback for Gemini via OAuth uses port 8085.
```
./aistack cpa login gemini [--project_id <your_project_id>]
```
choose Google One to use free tier with google personnal account
alternative : go to http://localhost:8317/management.html go to OAuth login / Gemini CLI OAuth

info
```
./aistack cpa info
```

list endpoints sample test
```
curl -s http://localhost:8317
```

list available models
```
YOUR_TOKEN="xxxx"
curl -X GET "http://localhost:8317/v1/models" \
    -H "Authorization: Bearer $YOUR_TOKEN" \
    -H "Content-Type: application/json"
```

test chat completion
```
curl -X POST http://localhost:8317/v1/chat/completions \
    -H "Authorization: Bearer $YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gemini-2.5-pro",
        "messages": [
        {"role": "user", "content": "Hello from test"}
        ]
    }'
```

## Gemini OAuth and special case when using remote SSH in vscode 

You will have to use the web browser of your current host to auth to gemini. And launch a local port forwarding with ssh to establish a tunnel

On your current host, where run your vscode desktop, use a ssh client and launch `ssh -L 127.0.0.1:8085:127.0.0.1:8085 root@xxx.xxx.xxx.xxx -p 22`.

- Launch `ssh -L 127.0.0.1:8085:127.0.0.1:8085 remote_ssh_user@remote_ssh_host -p remote_ssh_port`
- Then `./aistack cpa launch -- --login --no-browser`
- Then open the browser by following the link to auth

Instead ssh command you can use the "forward port" functionnality in vscode :

* Ports/Add port :
    * Port : localhost:8085
    * Change Local Adress Port : 8085
    * remote_ssh_host:remote_ssh_port is the SSH address you are currently connected through VS Code remote SSH


About SSH port forwarding : https://gist.github.com/StudioEtrange/d10c0b4f17a60b219e0b5722968d5b8c


## Connect KiloCode VS Code extension 
  
* In KiloCode extension settings
  * API Provider : OpenAI Compatible
  * Base URL : http://127.0.0.1:8317/v1
  * API Key : <YOUR_TOKEN>
  * Model : Kilo Code will load list of available modeles (ex:gemini-2.5-pro)
  * Context Window Size : Get size by selecting API Provider of the proxified LLM (ie: Google Gemini default setup for gemini-2.5-pro is 1048576)
