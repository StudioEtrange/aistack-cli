
#!/usr/bin/env bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd )"

set -euo pipefail

echo "** Launch container **"
docker run --rm --entrypoint "" \
                -v "$_CURRENT_FILE_DIR/../":/aistack-cli \
                ghcr.io/charmbracelet/vhs bash /aistack-cli/demo/generate.sh