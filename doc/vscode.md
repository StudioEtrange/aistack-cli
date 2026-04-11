# VS Code


## VS Code Remote SSH to older linux system
  
* vs code server needs linux minimal requirements : kernel >= 4.18, glibc >=2.28, libstdc++ >= 3.4.25, binutils >= 2.29. If you do not meet these requirements you have two solutions

* Solution A : Use old vs code version (downgrade actual version)
  * vs code version 1.96.4 supports glibc 2.17, you could downgrade vs code if you wish to connect to older linux system with glibc 2.17

* Solution B : 
  * Deploy vs code server patch mechanism
  * Tweak some settings
  * Connect with SSH Remote to the host

### Solution B : How-to

* *Deploy vs code server patch mechanism*
  * 1.connect with SSH to remote host
    ```
    cd $HOME
    git clone https://github.com/StudioEtrange/aistack
    ```

  * 2.build custom glibc runtime. Default parameters are suitable for rhel/centos 7 with glibc2.28 with gcc 8.5.0 for kernel 3.10
    ```
    cd $HOME/aistack/pool/scripts
    export NB_PROC="AUTO" # AUTO to use all your processor at build time
    ./build-custom-glibc-runtime.sh $HOME/custom-glibc2228-runtime

    # copy it in a shared folder to have to do this step only once by machine
    sudo cp -R $HOME/custom-glibc228-runtime /opt
    sudo chmod -R a+rx /opt/custom-glibc228-runtime

    # clean cache and build folder
    rm -rf $HOME/.build-custom-glibc-runtime
    ```

  * 3.install a hook to patch vs code server at each SSH connection
    ```
    cd $HOME/aistack/pool/scripts
    ./install-vscode-server-patch-hook.sh
    # To uninstall hook use : ./install-vscode-server-patch-hook.sh uninstall
    ```

* *Tweak Some settings*
    * MANDATORY : VS Code / User Settings / Remote.SSH : uncheck Use Exec Server (OR in settings.json : `"remote.SSH.useExecServer" : false`)

    * If you have error with wget at connection `wget unrecognized option "--no-config"` because wget is too old
      * VS Code / User Settings / Remote.SSH : check Curl And Wget Configuration Files (OR in settings.json : `"remote.SSH.useCurlAndWgetConfigurationFiles" : true`)
      
    * git integration in VS Code may not work if you have an old git version (<2.x) in the PATH of your old linux system, you should update it or provide a new version in settings.json : `"git.path" : "/opt/git/bin/git"`

* *Connect with SSH Remote to the host*
  * first time and at each new VS Code version you have to connect to the host first and it will fail because VS Code server is not yet patched
    * At this step you could close connection after first attempt to launch vs code server mentionning "GLIBC ERROR"
  * Then connect to the host and the patch will apply

### Solution B : design notes
  
* links
  * https://code.visualstudio.com/docs/remote/faq#_can-i-run-vs-code-server-on-older-linux-distributions 
  * https://github.com/microsoft/vscode/pull/235232
  * https://github.com/microsoft/vscode/issues/238873


* needs to patch vs code server with glibc 2.28
* needs patchelf to patch vs code server binaries (patchelf >=v0.18.x) (https://github.com/NixOS/patchelf)
* needs to provide a sysroot with glibc 2.28
  * Classic build glibc 2.28
  * OR Build glibc using crosstool-NG 
    * crosstool ng configs from https://github.com/microsoft/vscode-linux-build-agent or https://github.com/hsfzxjy/vscode-remote-glibc-patch/tree/master/configs
  * OR Extract a precompiled sysroot from https://github.com/microsoft/vscode-linux-build-agent/releases

* about vs code server check requirements at launch : https://github.com/microsoft/vscode/blob/e6e9958f8fc8edd2f509ada8b3cf11f88ac8b06d/resources/server/bin/helpers/check-requirements-linux.sh#L20

* METHOD 1 : autopatch method by vs code server based on environment variables  
  * Use environment variable
    ```
    VSCODE_SERVER_CUSTOM_GLIBC_LINKER : path to the dynamic linker (ld-linux.so) in the sysroot (used for --set-interpreter option with patchelf)
    VSCODE_SERVER_CUSTOM_GLIBC_PATH : path to the library locations in the sysroot (used as --set-rpath option with patchelf)
    VSCODE_SERVER_PATCHELF_PATH : path to the patchelf binary on the remote host
    ```
  * But it could be tricky to set these environnment variables at each SSH connection depending on your ssh server config or on your shell. in this case use method 2
  * https://github.com/microsoft/vscode/blob/e6e9958f8fc8edd2f509ada8b3cf11f88ac8b06d/resources/server/bin/code-server-linux.sh#L14
  * https://github.com/hsfzxjy/vscode-remote-glibc-patch

* METHOD 2 : apply patch manually with script
  * https://github.com/ziwenhahaha/scripts/blob/master/setup_vscode_patch.sh




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
