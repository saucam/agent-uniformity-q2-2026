# Reproduction Kit — Code Uniformity Q2 2026

For any single number cited in the report, this kit lets a reader reproduce that number from scratch on their own machine — without access to the closed-source benchmark harness.

## What you need

- Python 3.11+
- `git`, `gh` (optional, for some commands)
- ~2 GB of disk per repo cloned
- `pip install semble>=0.1.3 radon>=6.0 'tree-sitter>=0.23,<0.26' 'tree-sitter-language-pack>=1.6,<1.8'`

## What you can reproduce

| Metric | Where it is published | How to verify |
|---|---|---|
| Per-repo `function_count`, `repo_uniformity_index`, `pattern_cluster_density`, `same_file_cohesion`, `cross_file_coupling`, `isolation_rate`, `ai_uniformity_gap`, `lines_per_function_*`, `cc_mean_python`, `comment_density_mean` | `analysis/summary.csv` | `bash reproduce.sh <task_id>` |
| Per-language aggregates | `analysis/by_language.csv` | derived from summary.csv |
| Per-AI-bucket aggregates | `analysis/by_bucket.csv` | derived from summary.csv |
| Hypothesis tests H1–H5 | `analysis/hypotheses.json` | derived from summary.csv + per-function detail in HuggingFace partial |
| H4 isolation-by-authorship | `analysis/H4_isolation_by_authorship.csv` | derived from HuggingFace partial |
| H5 complexity-by-authorship | `analysis/H5_complexity_by_authorship.csv` | derived from HuggingFace partial |

## Single-repo reproduction

```bash
bash reproduce.sh <task_id>
```

Where `<task_id>` is one of the 48 IDs in `sampling.md` (e.g., `davila7-claude-code-templates`). The script:

1. Reads the locked `base_sha` from `sampling.md`
2. Clones the repo at that exact SHA
3. Runs the same Python analysis used in the original run (function extraction, similarity queries via semble, git blame against the same Claude-footer-detection logic, radon for Python CC)
4. Prints the per-repo summary metrics
5. Compares with what's published in `analysis/summary.csv` for the same repo

If a number doesn't reproduce within reasonable variance (semble's hybrid retrieval has ~1% non-determinism from BM25 randomness), open an issue with the diff.

## Why no full harness

Per Agent Almanac's [open/closed policy](https://agentalmanac.com/methodology), the methodology is the moat. The full benchmark harness is closed; the methodology document is canonical and public; the per-report repro kit (this) lets anyone verify any single published number. The combination — public methodology + public per-number reproducibility + closed harness — keeps the report defensible without making it trivially clonable.

## License

MIT — see `../LICENSE`.
