#!/bin/bash
# Portable entry point: put this repo + llama.cpp build + model on the external drive,
# plug the drive into any Apple Silicon Mac with Xcode CLT, run this. Builds if needed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export MOE_WORK="${MOE_WORK:-$HERE/work}"
. "$HERE/scripts/env.sh"
[ -x "$LLAMA_DIR/build/bin/llama-server" ] || "$HERE/scripts/build.sh"
[ -f "$MODEL" ] || "$HERE/scripts/download-model.sh"
exec "$HERE/scripts/serve.sh" "$@"
