# VS Code

## VS Code Remote SSH to older linux system
  
* vs code server needs linux minimal requirements : kernel >= 4.18, glibc >=2.28, libstdc++ >= 3.4.25, binutils >= 2.29. If you do not meet these requirements you have two solutions

* Solution A : Use old vs code desktop version (downgrade actual version)
  * vs code version 1.96.4 supports glibc 2.17, you could downgrade vs code if you wish to connect to older linux system with glibc 2.17

* Solution B : 
  * Use this solution https://github.com/StudioEtrange/glibc-binary-compat


## Custom LLM

* [Extension : OAI Compatible Provider for Copilot](oaicopilotprovider)

## VS Code Various Notes

* VS Code Server download
  * By default the Remote SSH extension will download VS Code Server on the remote host and fail back to downloading VS Code Server locally and transferring it remotely once a connection is established. (Setting : `remote.SSH.localServerDownload`)
  * https://code.visualstudio.com/docs/remote/faq#_what-are-the-connectivity-requirements-for-vs-code-server
  * Manual VS Code server download : https://stackoverflow.com/questions/77068802/how-do-i-install-vscode-server-offline-on-a-server-for-vs-code-version-1-82-0-or/79823034#79823034


* VS Code extension Gemini cli companion specification
  * discovery files for MCP server : $TMPDIR/gemini/ide/gemini-ide-server-${PID}-${PORT}.json
  * https://geminicli.com/docs/ide-integration/ide-companion-spec/


* Shell integration
  * environment variable in current shell VSCODE_SHELL_INTEGRATION value "1" means shell integration is enabled in current shell. Maybe by the command "code --locate-shell-integration-path bash"
  * some documentation about VS Code shell integration https://kilo.ai/docs/automate/extending/shell-integration
