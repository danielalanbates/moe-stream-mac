#!/bin/bash
# Memory guard. Usage: guard.sh <pid>   — kills <pid> if swap grows > $SWAP_DELTA_MB or free+inactive < 150 MB.
# Every llama process on a small-RAM host MUST run under this (an unguarded run took an 8 GB Mac down on 2026-08-28).
. "$(dirname "$0")/env.sh"
PID=$1; swap(){ sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | cut -d. -f1; }
free(){ vm_stat | awk '/Pages free/{f=$3}/Pages inactive/{i=$3}END{gsub(/\./,"",f);gsub(/\./,"",i);print int((f+i)*16/1024)}'; }
SW0=$(swap)
while kill -0 "$PID" 2>/dev/null; do
  SW=$(swap); FR=$(free)
  if [ $((SW-SW0)) -gt "$SWAP_DELTA_MB" ] || [ "$FR" -lt 200 ]; then
    echo "$(date +%T) GUARD KILL pid=$PID swap=${SW}MB (+$((SW-SW0))) free=${FR}MB" >&2
    kill -9 "$PID"; exit 99
  fi
  sleep 1
done
