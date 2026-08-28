#!/bin/bash
. "$(dirname "$0")/env.sh"
pkill -f "llama-server.*--port $PORT" && echo stopped || echo "not running"
