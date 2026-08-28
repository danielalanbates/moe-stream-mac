#!/bin/bash
. "$(dirname "$0")/env.sh"
pkill -f "llama-server.*--port $PORT" && echo stopped || echo "not running"
pkill -f "scripts/guard.sh" 2>/dev/null; rm -f "$LOGS/server.pid"
