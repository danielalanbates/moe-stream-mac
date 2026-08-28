#!/bin/bash
# Serve the drive-resident model. OpenAI-compatible API + web UI on http://localhost:$PORT
# Weights: mmap'd straight off the drive.  KV cache: saved/restored to $MEMORY/kv (on the drive).
set -euo pipefail
. "$(dirname "$0")/env.sh"; eval "$("$(dirname "$0")/pick-model.sh")"
if pgrep -f "llama-server.*--port $PORT" >/dev/null; then echo "already running on :$PORT (one instance rule)"; exit 0; fi
LOG="$LOGS/server.log"; echo "host ${HOST_GB}GB -> $(basename "$MODEL") $EXTRA" | tee "$LOG"
"$BIN/llama-server" -m "$MODEL" $EXTRA --no-warmup -c "$CTX" --port "$PORT" --host 127.0.0.1 \
  --slot-save-path "$MEMORY/kv" --slots --cache-reuse 256 -ctk q8_0 -ctv q8_0 "$@" >>"$LOG" 2>&1 &
PID=$!; echo $PID > "$LOGS/server.pid"
"$(dirname "$0")/guard.sh" $PID >>"$LOGS/guard.log" 2>&1 &
sleep 0.5
for i in $(seq 1 120); do curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && { echo "ready: http://localhost:$PORT (pid $PID)"; exit 0; }; kill -0 $PID 2>/dev/null || { echo "server died, see $LOG"; exit 1; }; sleep 1; done
echo "timeout waiting for /health"; exit 1
