# moe-stream-mac — a self-contained AI on an external USB drive

Plug a USB SSD into any Apple-silicon Mac (or, with a CPU build, any x86 box — no CUDA)
and get a working local AI whose **weights, working memory, long-term memory and logs all
live on the drive**. The host contributes CPU/GPU cycles and a few GB of RAM; the user
gets only the final answer.

```
/Volumes/x10/LLMs/moe-stream/          (= $MOE_WORK, the drive)
├── llama.cpp/build/bin/   runtime (llama.cpp PR #25294 --moe-stream, Metal + CPU)
├── models/*.gguf          weight files, mmap'd straight off the drive (never copied to RAM)
├── memory/memory.db       long-term memory: SQLite FTS5, every Q/A + explicit facts
├── memory/kv/             KV-cache slot saves (the model's working memory, on the drive)
└── logs/                  server.log, guard.log
```

## Use

```bash
scripts/serve.sh                     # picks the model that fits THIS host's RAM, serves :8080 (API + web UI)
scripts/ask "What's my dog's name?"  # memory recall -> model -> stores the turn -> prints ONLY the answer
scripts/drive_ai.py remember "..."   # store a fact
scripts/drive_ai.py recall  "..."    # see what memory would inject
scripts/stop.sh
```
Or double-click **Drive AI.app** (in /Applications; built by `scripts/make-app.sh`) — it starts
the server from the drive and opens the chat UI.

First run on a new machine: `scripts/run-from-drive.sh` (builds llama.cpp on the drive if
needed, needs Xcode CLT). Everything is relative to `MOE_WORK`; override in `config.local.sh`.

## How it copes with small RAM

| RAM on host | model picked by `pick-model.sh` | mechanism |
|---|---|---|
| 8 GB | Qwen3-4B-Instruct Q4 (2.5 GB) | plain mmap; ~13 tok/s on M1 |
| 16 GB | Qwen3.5-35B-A3B Q4 (22 GB) | `--moe-stream`: experts streamed per token, 24 slots/layer |
| 32 GB+ | same, 4 GiB expert cache | |

`scripts/guard.sh` runs beside every server and kills it if swap grows > 2.5 GB or free RAM
< 200 MB. **Never run llama-* bare on an 8 GB host** — an unguarded run rebooted the Mac.

## Status / plan
- `docs/FINDINGS.md` — measured numbers, what fits and what doesn't, and why.
- `docs/PATHWAYS.md` — ranked next steps + the GitHub projects worth building on.
- `docs/HANDOFF.md` — for the next AI/human: state of the tree, how to verify, gotchas.
- `archive/` — attempts that did not work on this hardware, kept for reference.

## License

PolyForm Noncommercial 1.0.0 + commercial rider (10% of revenue). All rights reserved,
Copyright (c) 2026 Daniel Bates / Bates LLC. Contact help@batesai.org · https://batesai.org.
