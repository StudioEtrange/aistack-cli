# runtime python


## python package tiktoken

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is tiktoken 0.11.0 https://pypi.org/project/tiktoken/0.11.0/
* tiktoken needs rust to compile source which might be a problem
* aistack integrations affected : sktor, ciss
  
## python package numpy

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is numpy 2.26 
* aistack integrations affected : sktors

## force build python package

* to avoid problem of non existing system dependencies, this might be usefull to force build package instead of download precompiled version


    * uv : for all packages
      * `UV_NO_BINARY=1 uv pip install tiktoken`
      * `uv pip install --no-binary :all: tiktoken`
    * uv : for a packages list
      * `UV_NO_BINARY_PACKAGE="tiktoken cryptography" uv pip install tiktoken cryptography requests`
      * `uv pip install --no-binary-package tiktoken --no-binary-package cryptography tiktoken cryptography requests`
    * pip : for all packages
      * `PIP_NO_BINARY=:all: pip install tiktoken`
      * `pip install --no-binary=:all: tiktoken`
    * pip : for a packages list
      * `PIP_NO_BINARY="tiktoken,cryptography" pip install tiktoken cryptography` 
      * `pip install --no-binary=tiktoken,cryptography tiktoken cryptography requests`