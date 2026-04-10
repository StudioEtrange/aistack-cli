
#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd )"

uname -a

export DEBIAN_FRONTEND="noninteractive"
apt-get update >/dev/null
apt-get install -y curl xz-utils jq >/dev/null
apt-get install -y libuv1 >/dev/null

cd "$_CURRENT_FILE_DIR"
. "$_CURRENT_FILE_DIR/stella-link.sh" include
$STELLA_API install_features

echo " ** Available features:"
vhs --version
ttyd --version
ffmpeg -version | head -n 1
export _STELLA_CONF_INCLUDED_=""

#$STELLA_API install_features
echo " ** Generate records **"
cd "$_CURRENT_FILE_DIR/tape"
for t in *.tape; do
  echo " -- generate record for $t"
  #( bash -c "vhs $t -o $(basename "$t" .tape).gif" )
  env -i USER=$USER PATH="$PATH" HOME="$HOME" bash -c "vhs $t -o $(basename "$t" .tape).gif"
done
