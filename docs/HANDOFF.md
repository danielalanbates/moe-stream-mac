# Handoff — read this first (for the next AI or human)

State on 2026-08-28: **working**. `scripts/serve.sh` + `scripts/ask` deliver a drive-resident AI
on an 8 GB M1 (Qwen3-4B-Instruct, 13–15 tok/s, SQLite memory recall verified). `Drive AI.app`
in /Applications launches it. Screenshot: `docs/screenshot-drive-ai-app.png`.

## Layout
- Repo working copy: `~/Downloads/moe-stream-mac` (git; iCloud breaks git — do not clone into iCloud).
  Read-only mirror for browsing: iCloud `Code/moe-stream-mac` (rsync'd, no .git).
- Drive root `$MOE_WORK` = `/Volumes/x10/LLMs/moe-stream` — runtime, models, memory, logs.
- Models: `models/*.gguf` (symlinks into `/Volumes/x10/LLMs/blobs` for Ollama-origin files).

## Verify in 60 seconds
```
scripts/serve.sh && scripts/ask "What is my dog's name?"     # expects: Biscuit (from memory.db)
scripts/drive_ai.py stats ; tail logs/guard.log              # no GUARD KILL lines
```

## Hard rules learned the hard way
1. Never run `llama-*` bare on an 8 GB host — always via `serve.sh` (guard attached). An unguarded
   `--no-mmap` run of the 35B model pushed swap +1 GB in 4 s and took the whole Mac down.
2. `timeout` does not exist on macOS.
3. Ollama blobs: fine for `qwen3`/`gemma2` archs, broken for `qwen35*`.
4. The guard's stdout must be redirected, or `serve.sh | tail` hangs forever (fixed in serve.sh).
5. Quit + reopen Terminal if `/Volumes/x10` root refuses writes (TCC).
6. Don't close FFXI/WoW or other apps to free RAM; the AI must coexist.

## Open work (see PATHWAYS.md for detail)
- KV slot save/restore from `drive_ai.py`; embeddings in memory.db; nightly fact summarisation.
- A small MoE that streams on 8 GB; AirLLM "slow-but-huge" mode; x86 Vulkan build on the drive.
