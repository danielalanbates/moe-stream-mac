#!/bin/bash
# Clone llama.cpp PR #25294 (MoE expert streaming), apply our patches, build with Metal.
set -euo pipefail
. "$(dirname "$0")/env.sh"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$WORK"
if [ ! -d "$LLAMA_DIR/.git" ]; then
  git clone --depth 1 -b "$PR_BRANCH" "$PR_FORK" "$LLAMA_DIR"
fi
cd "$LLAMA_DIR"
for p in "$HERE"/patches/*.patch; do
  git apply --check "$p" 2>/dev/null && git apply "$p" && echo "applied $(basename "$p")" || echo "skip $(basename "$p") (already applied?)"
done
cmake -B build -DGGML_METAL=ON -DLLAMA_CURL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --target llama-server llama-cli llama-bench -j "$(sysctl -n hw.ncpu)"
echo "built: $LLAMA_DIR/build/bin"
