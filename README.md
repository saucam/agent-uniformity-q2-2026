# Agent Almanac — Code Uniformity Q2 2026

> Inaugural Agent Almanac empirical report. Methodology, sampling, analysis CSVs, and reproduction kit for the inaugural structural-uniformity benchmark across 48 public OSS repositories.

**Run ID:** `2026-05-09T15-02-36Z-4931`
**Methodology version:** `0.1.0`
**Date of run:** 2026-05-09
**Sample:** 48 repos × 5 languages (Python / TypeScript / JavaScript / Go / Rust) × 3 AI-authorship strata
**Bylined:** Yash Datta · saucam ([agentalmanac.com](https://agentalmanac.com))

---

## What this is

A benchmark of how AI authorship reshapes the structure of production code. We measured each public function in 48 OSS repos along several axes (similarity to other functions in the same repo, cohesion vs coupling, isolation, cyclomatic complexity, comment density), then split functions into AI-authored (Claude commits) vs human-authored (everyone else) and compared.

Methodology pre-registered before any sampling — see [`methodology.md`](methodology.md). Five hypotheses (H1–H6) were locked at v0.1.0; we report results regardless of direction.

## Findings

| # | Plain-language headline | Direction |
|---|---|---|
| 1 | **AI code is the outlier in human codebases. AI code is the norm in AI codebases.** Same code, opposite role. | ✓ Confirmed (Pearson r = 0.58 between AI ratio and AI-vs-human uniformity gap) |
| 2 | **AI converges in JavaScript, varies in TypeScript.** Per-language imprint differs by 6× magnitude. | ✓ Confirmed |
| 3 | AI does not generate more duplicate code than humans. DRY-cluster density is roughly equal across AI buckets (slightly lower in AI-heavy repos). | ✗ Counter-prediction |
| 4 | The most-isolated functions in AI-heavy repos are *not* disproportionately human. AI writes its share of the rare-shaped code too. | ✗ Counter-prediction |
| 5 | AI Python is slightly simpler than human Python at most function sizes (3 of 4 line-count bins). The exception is the 21–50-line band, where AI is 11% more complex. | Partially ✓ |

Full hypothesis-test JSON: [`analysis/hypotheses.json`](analysis/hypotheses.json).

## Layout

```
agent-uniformity-q2-2026/
├── methodology.md         ← canonical methodology, frozen at v0.1.0
├── sampling.md            ← 48 repos selected with HEAD SHAs at run time
├── manifest.json          ← run-time environment snapshot
├── analysis/              ← all hypothesis tests + summary CSVs
│   ├── hypotheses.json
│   ├── summary.csv
│   ├── by_language.csv
│   ├── by_bucket.csv
│   ├── most_isolated.csv
│   ├── dry_pairs_top.csv
│   ├── H4_isolation_by_authorship.csv
│   └── H5_complexity_by_authorship.csv
└── repro_kit/             ← scripts to regenerate any single number
```

## Raw data

Per-repo function-level metrics (~120 MB) are published as a HuggingFace dataset:
**🤗 [saucam/agent-uniformity-q2-2026](https://huggingface.co/datasets/saucam/agent-uniformity-q2-2026)**

Each row is one repo's full output (every function with its language, line range, AI ratio, mean top-K similarity, cyclomatic complexity, comment density, plus the repo-level DRY pair list).

## Reproduction

For any single number cited in the report:

1. Clone this repo
2. `cd repro_kit && bash reproduce.sh <task_id>` — clones the same SHA, runs semble + git blame, prints the metric
3. The harness code that runs the full pipeline is closed-source ([open/closed policy](https://agentalmanac.com/methodology) — methodology is the moat). The repro kit is a minimal single-task subset that anyone can run.

For methodology disagreements or replication requests, open an issue.

## License

| Component | License |
|---|---|
| Methodology document | CC BY 4.0 |
| Analysis CSVs | CC BY 4.0 |
| Repro kit code | MIT |
| HuggingFace dataset | CC BY 4.0 |
| Per-repo content (within partials) | Original licenses of each upstream repo (see `sampling.md`) |

## Citation

```
Datta, Y. (saucam). (2026). Code Uniformity Q2 2026 — How AI authorship reshapes
the structure of public open-source code. Agent Almanac.
https://github.com/saucam/agent-uniformity-q2-2026
```

## Contact

Issues + corrections: open an issue here.
General correspondence: agentalmanac.com / saucam on GitHub + X.

## Changelog

| Date | Run ID | Notes |
|---|---|---|
| 2026-05-10 | 2026-05-09T15-02-36Z-4931 | Initial publication. 48 repos. Methodology v0.1.0. 1 repo (`BoundaryML/baml`) excluded due to per-task time-out — reported separately, not used in aggregates. |
