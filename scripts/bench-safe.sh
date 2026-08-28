#!/bin/bash
# Benchmark with memory watchdog: kill llama-cli if swap used > 1500 MB or free+inactive < 150 MB.
W=/Volumes/x10/LLMs/moe-stream; B=$W/llama.cpp/build/bin/llama-cli
LOG=$W/run6.log
$B -m $W/Qwen3.5-35B-A3B-Q4_K_M.gguf --moe-stream --moe-stream-cache 24s --moe-stream-io-threads 4 \
  -ngl 0 --no-warmup -c 1024 -n 48 -no-cnv -p "Explain in two sentences why the sky is blue." >$LOG 2>&1 &
PID=$!
SW0=$(sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | cut -d. -f1)
while kill -0 $PID 2>/dev/null; do
  SW=$(sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | cut -d. -f1)
  FREE=$(vm_stat | awk '/Pages free/{f=$3}/Pages inactive/{i=$3}END{gsub(/\./,"",f);gsub(/\./,"",i);print (f+i)*16/1024}' | cut -d. -f1)
  echo "$(date +%T) swap=${SW}MB free+inact=${FREE}MB" >> $W/watchdog.log
  if [ $((SW-SW0)) -gt 900 ] || [ "$FREE" -lt 150 ]; then echo "WATCHDOG KILL swap=$SW free=$FREE" | tee -a $LOG >> $W/watchdog.log; kill -9 $PID; break; fi
  sleep 1
done
wait $PID; echo "RUN_EXIT=$?" >> $LOG
