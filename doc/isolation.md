# Agent and process isolation

* container based
  * yolobox - security boundary is the container - use docker/podman - https://github.com/finbarr/yolobox 
  * gVisor 18kstars - go - https://github.com/google/gvisor - a container runtime that improve your container security
    * docker run --runtime=runsc ubuntu
  * distrobox - bash - https://github.com/89luca89/distrobox launch a linux distribution in a container in an integrated way of current session - use docker/podman/lilipod

* microvm based
  * docker sandboxes - based on microvm (docker 4.58+) and with a docker engine
    * default network allow list ~/.docker/sandboxes/vm/<vm-name>/proxy-config.json
    * microvm vs container : https://www.ajeetraina.com/docker-sandboxes-containers-vs-microvms-when-to-use-what/?utm_source=chatgpt.com
  * Kata Containers : microvm + container engine : https://katacontainers.io/
  * https://github.com/trycua/cua
    * Open-source infrastructure for Computer-Use Agents. Sandboxes, SDKs, and benchmarks to train and evaluate AI agents that can control full desktops (macOS, Linux, Windows).
  * smol machines
    * https://smolmachines.com/
    * https://github.com/smol-machines/smolvm
    * based on linux KVM, macos Hypervisor.framework

* os based
  * firejail - https://github.com/netblue30/firejail  https://firejail.wordpress.com/ - use linux kernel functionality
  * bubblewrap - https://github.com/containers/bubblewrap - attempts to allow unprivileged users to use container features - Low-level unprivileged sandboxing tool
  * fence - 567stars - macos/linux - go - Lightweight, container-free sandbox for running commands with network and filesystem restrictions https://github.com/Use-Tusk/fence https://korben.info/fence-sandbox-agents-ia-cli.html - macos (use sandbox-exec) / linux (use bubblewrap) - inspired by srt
    * https://github.com/Use-Tusk/fence/blob/main/docs/agents.md
  * srt - Anthropic Sandbox Runtime - BETA - 3,5k stars - nodejs -  https://github.com/anthropic-experimental/sandbox-runtime A lightweight sandboxing tool for enforcing filesystem and network restrictions on arbitrary processes at the OS level without container - macos (use sandbox-exec) / linux (use bubblewrap)
  

---

* linux kvm setup
  * To enable KVM:
    * 1. Ensure virtualization is enabled in your BIOS/UEFI
    * 2. Load the KVM kernel module:
    *    sudo modprobe kvm
    *    sudo modprobe kvm_intel  # For Intel CPUs
    *    sudo modprobe kvm_amd    # For AMD CPUs
  * For persistent loading, add to /etc/modules-load.d/kvm.conf:
    *    kvm
    *    kvm_intel  # or kvm_amd
  * Add your user to the 'kvm' group:
    * sudo usermod -aG kvm $USER"

  
