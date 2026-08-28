# Pathways for continuing this work

Goal (Daniel, 2026-08-28): *turn a macOS-journaled external USB drive into a self-contained AI —
the drive hosts the LLM and acts as its memory; the host only supplies compute and receives the
finalized answer; consumer non-CUDA hardware.*

Physics check, stated once: a USB SSD has no compute, so "runs on the drive" means
**everything persistent is on the drive** (runtime, weights, KV/working memory, long-term memory,
logs) and the host's RAM holds only a transient working set. USB bandwidth (900 MB/s here) is not
the limiter until the resident set exceeds host RAM — then it is the *only* limiter.
What ships today is exactly that layout (see README). Ranked next steps:

## 1. Bigger brains on small hosts (the hard problem)
- **PR #25294 `--moe-stream`** (this repo's runtime). Works; floor is 3×n_expert_used cache
  slots/layer + the dense part resident. 35B-A3B needs ~6 GB → 16 GB host minimum. Status of the
  PR: open, conflicting with master; pinned to `1248fd8`.
- **Smaller MoEs** whose dense part < 1.5 GB would stream on 8 GB: candidates to test
  `OLMoE-1B-7B`, `granite-3.1-3b-a800m`, `DeepSeek-V2-Lite (16B-A2.4B)`. Untested here.
- **AirLLM** (github.com/lyogavin/airllm, Apache-2.0, 33k★): layer-by-layer loading, runs 70B on
  4 GB, has an Apple-silicon (MLX) path. Slow (seconds/token) but is the *only* proven way to run
  a 70B dense model on this Mac. Fork-worthy for a "slow but huge" mode; `airllm-plus` adds
  prefetch/super-block residency. Not integrated yet.
- **TinyGiant re-layout** (github.com/jerryjokesalot/tinygiant, ggml discussion #27149): repacks
  GGUF so each expert is contiguous → far fewer page touches with plain mmap; complements #25294.
- Metal expert-slot PoC (ggml discussion #23324): 13 tok/s on a 30B-A3B on 16 GB — design only.

## 2. Memory on the drive (works, extend it)
- Today: SQLite FTS5 (`memory/memory.db`) with BM25 recall + recency; KV slot saves in `memory/kv`.
- Next: embeddings via `llama-embedding` with a small model (nomic-embed ~140 MB) stored in the
  same SQLite (vector column, brute-force cosine is fine to ~100k rows); summarise old turns into
  facts nightly. **Letta** (Apache-2.0) and **mem0** (Apache-2.0) are the reference designs for
  memory blocks / fact extraction — borrow the schema, don't import the frameworks (RAM).
- Use llama-server `/slots/{id}?action=save|restore` to persist the *conversation KV* across
  server restarts so long chats resume instantly from the drive. Wiring exists (`--slot-save-path`),
  `drive_ai.py` does not call it yet.

## 3. Portability (mostly done)
- `run-from-drive.sh` builds on any Apple-silicon host with Xcode CLT. For x86/Linux add a
  second build dir (`build-x86-vulkan`) so the same drive works on a Windows/Linux box — llama.cpp
  supports Vulkan (AMD/Intel/NVIDIA without CUDA).
- `pick-model.sh` chooses by `hw.memsize`; extend with a Linux branch (`/proc/meminfo`).

## 4. Make swap live on the drive?
- macOS no longer lets you point the swapfile at a non-root volume without disabling SIP
  (`dynamic_pager` is gone). Not worth it: mmap already gives "weights paged from the drive" for
  free, and the guard prevents the anonymous-memory runaway that crashed the Mac.

## Non-goals / dead ends
- Ollama GGUFs for Qwen3.5+ archs (converter divergence).
- Thinking models for the final-answer contract.
- Faster cable / Thunderbolt: irrelevant below the RAM cliff.
