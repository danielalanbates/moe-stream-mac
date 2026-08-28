# Archived: Qwen3.5-35B-A3B expert streaming on an 8 GB M1 (2026-08-28)

Does not work on this host — see docs/FINDINGS.md. Logs kept locally (run2..run6, watchdog.log;
*.log is gitignored). The scripts are still valid for a 16 GB+ host; `scripts/pick-model.sh`
selects the 35B streamed path automatically there. `bench-safe.sh` was folded into
`scripts/guard.sh`.
