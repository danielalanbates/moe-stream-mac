# Findings (2026-08-28)

## Hardware, measured

| | |
|---|---|
| Machine | MacBookPro17,1 (M1), 8 GB unified, ~68 GB/s |
| Drive | 4 TB USB 3.2 Gen 2 SSD; `/Volumes/x10` HFS+ journaled, `/Volumes/Games` APFS |
| Seq read | 926 MB/s |
| 8 MB random | 903 MB/s |
| 1 MB random | 693 MB/s |
| 64 KB random | 236 MB/s |
| 4 KB random | 19.6 MB/s |

The drive is fine at large granularity; page-sized mmap faults are 47x slower than
1 MB reads. Every viable approach therefore does explicit large reads of contiguous
per-expert slabs, which PR #25294 does.

## Model

Qwen3.5-35B-A3B, Q4_K_M: 40 layers × 256 experts, 8 used/token, expert slab ≈ 2 MB
(gate/up Q4_K 0.59 MB each + down Q6_K 0.86 MB). Cold cost per token ≈ 40 × 8 × 2 MB
= **~650 MB of reads** → ~0.9 tok/s worst case at 693 MB/s; better with cache hits.
Non-expert weights ≈ 3.5 GB (must be resident) + KV.

## Problems hit

1. **Ollama GGUFs don't load in llama.cpp.** The 24 GB `qwen3.6:35b` blob already on the
   drive is an Ollama-converted `qwen35moe` file: 3-element `rope.dimension_sections`
   (llama.cpp wants 4) and different tensor names (`ssm_dt` vs `ssm_dt.bias`, fused
   `attn_qkv`, split `ssm_alpha`/`ssm_beta` vs fused `ssm_ba`). Patched the first
   (`patches/0001`), the rest is a converter divergence — downloaded a native GGUF instead.
2. **Stale swap files.** 182 GB (`.swap` 32 GB + `.swap-750k` 150 GB) from an earlier
   attempt in `/Volumes/x10/LLMs`; deleted. x10 free: 261 → 443 GB.
3. **TCC.** `/Volumes/Games` and `/Volumes/x10` root refuse writes from this Terminal
   (Full Disk Access); `/Volumes/x10/LLMs` (owned by daniel) is writable. Quit + reopen
   Terminal to fix.
4. `timeout` doesn't exist on macOS — don't wrap runs in it.

## Results

**Verdict (2026-08-28): does not fit on the 8 GB M1.** All runs below used `--moe-stream-cache 24s`
(the minimum the PR accepts: 3 × n_expert_used slots per layer; `1` GiB gave 14 slots and aborts
at graph reserve). 24 slots × 40 layers × ~2 MB ≈ 1.9 GB of cache.

| run | flags | outcome |
|---|---|---|
| run2/3 | `--moe-stream-cache 1 --no-mmap` | abort: "need 24 slots, have 14" |
| run4 | `24s --no-mmap` (Metal) | 4 s into load: swap +960 MB, free 94 MB → watchdog kill. **This is what took the whole Mac down on the unguarded attempt.** |
| run6 | `24s -ngl 0` (mmap, CPU) | loads, emits ~10 tokens of thinking in ~85 s (~0.1 tok/s), then swap +950 MB → watchdog kill |

Arithmetic: ~3.5 GB non-expert weights resident + 1.9 GB expert cache + KV/compute buffers
≈ 6 GB, against ~1.7–3.4 GB actually free on this machine with the desktop up. mmap only
delays the death — the resident weights get paged back in every token.

What would work: a 16 GB+ Mac (same drive, same scripts), or a much smaller MoE
(e.g. a ~10–16 B-total A2B model whose dense part is < 1.5 GB). Any run on this machine must go
through `scripts/bench-safe.sh` (swap-delta watchdog) — never bare `llama-cli`.
