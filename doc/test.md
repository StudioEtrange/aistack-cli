# Unit test

## How to launch unit tests

  ```
  cd $HOME
  git clone https://github.com/StudioEtrange/aistack-cli.git
  cd aistack-cli
  ./test/launch_test.sh all
  ```

## Test various linux systems - using docker and distrobox

* **requirements**

  *docker engine* - you could use rancher-desktop on macos https://rancherdesktop.io/

* **install distrobox**

  ```
  cd aistack-cli
  ./stella-link.sh feature install distrobox
  ./stella-link.sh shell
  ```

* **create a test container**

  ```
  distrobox create \
    --name aistack-test \
    --image ubuntu:24.04 \
    --yes
  ```



*NOTE*: distrobox mount your current $HOME folder as home inside container*

*NOTE*: to test support of glibc 2.17 use image oraclelinux:7.9

* **prepare the test container**

  ```
  distrobox enter aistack-test --verbose
  ```

  ```
  sudo apt-get update
  sudo apt-get install -y \
    git curl wget ca-certificates \
    tar gzip bzip2 xz-utils unzip \
    build-essential
  ```

* **prepare the test container**

  ```
  cd $HOME/aistack-cli
  ./test/launch_test.sh json
  ```

* **purge**

  ```
  distrobox rm aistack-test -Y
  ```
