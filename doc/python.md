# runtime python


## python package tiktoken

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is tiktoken 0.11.0 https://pypi.org/project/tiktoken/0.11.0/
* tiktoken needs rust to compile source which might be a problem
* aistack integrations affected : sktor, ciss
  
## python package numpy

* installed with pip or uv, there is existing prebuilt wheel. But the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is numpy 2.26 
* aistack integrations affected : sktors


## ciss and yara-x

* ciss needs a recent version of yara-x python package
* the last compatible version for glibc 2.17 (RHEL/Centos 7) version avaiblable is 1.0.1
* build from source

  ```
  command -v cargo
  command -v rustc

  git clone --branch v1.19.0 --depth 1 https://github.com/VirusTotal/yara-x.git
  cd yara-x

  export MATURIN_NO_INSTALL_RUST=1
  python -m pip install maturin
  python -m maturin build \
      --release \
      --locked \
      --manifest-path py/Cargo.toml \
      --interpreter "$(command -v python)"

  python -m pip install \
      --force-reinstall \
      target/wheels/yara_x-*.whl
  ```

## force build python package

* to avoid problem of non existing system dependencies, this might be usefull to force build package instead of download precompiled version
  * uv:
    * `uv pip install --system --reinstall --no-binary tiktoken tiktoken` [OK]
    * `uv pip install --system --reinstall --no-binary :all: tiktoken cryptography` [OK]
    * `uv pip install --system --reinstall --no-binary tiktoken --no-binary cryptography tiktoken cryptography requests` [OK]
    * `uv pip install --system --reinstall --only-binary tiktoken tiktoken` [OK]
    * `uv pip install --system --reinstall --no-build tiktoken` [OK]
    * `UV_NO_BINARY=1 uv pip --system --reinstall install tiktoken` [KO]
    * `UV_NO_BINARY_PACKAGE="tiktoken cryptography" uv pip install tiktoken cryptography requests` [KO]
  * pip:
    * `PIP_NO_BINARY=:all: pip install tiktoken` [OK]
    * `pip install --no-binary=:all: tiktoken` [OK]
    * `PIP_NO_BINARY="tiktoken,cryptography" pip install tiktoken cryptography` [OK]
    * `pip install --no-binary=tiktoken,cryptography tiktoken cryptography requests` [OK]