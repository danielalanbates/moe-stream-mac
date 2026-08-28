# moe-stream-mac

Run a Mixture-of-Experts LLM that is far larger than your Mac's RAM by keeping the
model on an external USB SSD and streaming only the active experts per token.
Target machine: **M1 MacBook Pro, 8 GB unified memory, 4 TB USB 3.2 Gen 2 SSD** —
consumer hardware, no CUDA.

Built on top of llama.cpp **PR #25294** (`--moe-stream`, by @freedomljc), the most
complete of the expert-streaming prototypes. This repo adds the glue, the patches that
make it load real-world GGUFs, an 8 GB memory recipe, measured numbers, and a written
plan for whoever continues the work (human or AI). See `docs/`.

## Quick start

```bash
scripts/build.sh            # clones the PR branch to the external drive, patches, builds (Metal)
scripts/download-model.sh   # Qwen3.5-35B-A3B Q4_K_M (22 GB) from HuggingFace
scripts/bench.sh 64 1       # 64 tokens, 1 GiB expert cache — prints tok/s
scripts/serve.sh            # OpenAI-compatible server on :8080
```

Everything lives under `MOE_WORK` (default `/Volumes/x10/LLMs/moe-stream`) so the internal
disk isn't touched. Override paths in `config.local.sh` (gitignored).

## What "streaming" means here

A 35B-A3B MoE has 256 experts per layer but only 8 fire per token. The 20 GB of expert
weights stay on the SSD; a small per-layer slot cache (1–2 GiB) holds the hot experts;
misses are fetched with large explicit `pread`s by an I/O thread pool while the graph
waits. Routing is unchanged, so outputs are identical to a fully-resident run — only
latency differs. The shared (non-expert) weights and KV cache still live in RAM.

## Status

See `docs/FINDINGS.md` for measured results and `docs/PATHWAYS.md` for what to do next.

## License

PolyForm Noncommercial 1.0.0 + commercial rider (10% of revenue). All rights reserved,
Copyright (c) 2026 Daniel Bates / Bates LLC. Contact help@batesai.org · https://batesai.org.
llama.cpp itself is MIT (ggml-org); the PR branch is @freedomljc's work.
