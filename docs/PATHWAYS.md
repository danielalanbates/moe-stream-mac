# Pathways for continuing this work

Goal restated: an external USB SSD that hosts an LLM and does the heavy lifting, with the
Mac only assembling the final answer. Physics check: the *compute* still has to happen on
the Mac's CPU/GPU — a USB drive has no compute — so the achievable version of the goal is
"drive = weight store, RAM = small working set, USB link carries only the active experts."
That is exactly what expert streaming does. Ranked pathways:

## A. PR #25294 `--moe-stream` (this repo — do this first)
- Status: OPEN, `mergeable: CONFLICTING` against master as of 2026-08-28. Pin to commit
  `1248fd8` (env.sh). Re-merge upstream only if you need a newer arch.
- Tune: `--moe-stream-cache 1..2` (GiB) on 8 GB; `--moe-stream-io-threads 4..8`;
  try `--moe-stream-direct` (O_DIRECT → `F_NOCACHE` on macOS) once the model is >> RAM.
- Upstream it: the loader zero-pad patch is small and upstreamable on its own.

## B. Metal expert-slot PoC (ggml-org discussion #23324)
- 13 tok/s on Qwen3-30B-A3B Q6_K, M1 Pro 16 GB, internal NVMe. Closest data point.
- Not a branch you can clone as-is; it's a design. Port its "experts in Metal shared
  buffers + pread on miss" idea onto #25294 if #25294's Metal path underperforms.

## C. TinyGiant re-layout (discussion #27149, github.com/jerryjokesalot/tinygiant)
- Re-packs GGUF so each expert is contiguous → 36x fewer page touches with stock mmap.
- Complementary: a re-laid-out file makes #25294's slab reads sequential per expert.
- Also gives calibrated expert pinning (hit-rate 6% → 56%). Worth adding as a
  preprocessing step for the drive.

## D. Bigger models (gpt-oss-120b, GLM-4.5-Air, Qwen3-235B)
- Not on 8 GB. Shared weights + KV alone exceed the ~5 GB post-macOS budget. This is a
  RAM problem, not a drive problem. Needs 32 GB+ unified memory. Document, don't attempt.

## E. Reduce the resident set to fit more
- Q3_K / UD-Q3_K_XL cuts shared weights ~25%. KV in q8_0 (`-ctk q8_0 -ctv q8_0`).
- Free swap on the internal disk: only 6 GB free on `/`. macOS 8 GB leans on swap.

## F. Make it "self-contained"
- Put llama.cpp build + model + `scripts/` on the drive (already the layout). A
  `run-from-drive.sh` that only needs Xcode CLT on the host = the drive is portable
  between Macs. Ship an OpenAI-compatible endpoint (`serve.sh`) so any client works.

## Non-goals / dead ends
- Ollama's GGUF blobs: converter divergence, don't fight it.
- Faster cable: USB 3.2 Gen 2 is saturated but is NOT the bottleneck below 32 GB RAM.
