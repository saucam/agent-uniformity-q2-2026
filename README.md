# Agent Almanac — Code Uniformity Q2 2026

> Inaugural Agent Almanac empirical report. How AI authorship reshapes the structure of public open-source code. 48 repositories, 5 languages, 3 AI-authorship strata.

**Run ID:** `2026-05-09T15-02-36Z-4931`
**Methodology version:** `0.1.0`
**Run date:** 2026-05-09
**Author:** Yash Datta · saucam — [agentalmanac.com](https://agentalmanac.com)

---

## What we measured

For every public function in 48 OSS repositories, we compute its semantic similarity to other functions in the same repo (via [semble](https://github.com/MinishLab/semble)'s hybrid retrieval — Model2Vec embeddings + BM25 + Reciprocal Rank Fusion), the function's cohesion vs coupling profile, and its cyclomatic complexity (Python only, via radon). We then attribute every line of every function to AI or human authorship via `git blame` against commits carrying `Co-Authored-By: Claude` or the `Generated with [Claude Code]` footer. Functions are split into AI-authored (≥70% AI lines), human-authored (≤10% AI lines), and mixed. Per-repo metrics aggregate across all functions; per-language and per-AI-bucket metrics aggregate across the sample.

The methodology document (frozen v0.1.0 before any sampling) is at [`methodology.md`](methodology.md). The 48 sampled repos with their HEAD SHAs at run time are in [`sampling.md`](sampling.md).

## Findings

### AI code is the outlier in human codebases. AI code is the norm in AI codebases.

Across 45 repos with both AI- and human-authored functions in sufficient volume, the within-repo gap between AI-function uniformity and human-function uniformity correlates with the repo's overall AI authorship ratio at **Pearson r = 0.58**.

| Bucket | Mean AI-vs-human gap |
|---|---|
| Low-AI repos (<30% AI authored) | **−0.0023** (AI is the outlier) |
| Mid-AI (30–70%) | +0.0008 |
| High-AI (>70% AI authored) | **+0.0028** (AI is the norm) |

The gap reverses sign across the AI ratio range. AI code does not have a fixed style. Whether it stands out as the outlier or fits in as the norm depends on whether AI wrote the rest. For an engineer integrating AI into an existing codebase: expect AI commits to look structurally different from the surrounding code, and design code review accordingly. For a greenfield AI-driven project: human contributions become the structural outliers.

### AI converges in JavaScript. AI varies in TypeScript. The other languages sit in between.

Per-language AI-vs-human uniformity gap (positive = AI more uniform than human, negative = AI less uniform):

| Language | Gap | What this means |
|---|---|---|
| JavaScript | **+0.0038** | AI converges hard onto a single pattern |
| Python | +0.0018 | AI slightly more uniform than human |
| Go | +0.0001 | Indistinguishable |
| Rust | +0.0003 | Indistinguishable |
| TypeScript | **−0.0025** | AI is *less* uniform than human |

The 6× magnitude swing between TypeScript and JavaScript is unexpected. The likely explanation: TypeScript's type system forces explicit structural choices, so humans converge to type-driven idioms while AI takes the structural freedom and varies. JavaScript has weaker conventions and AI imposes its own pattern rigidly. Go and Rust both have strong cultural conventions (gofmt, rustfmt, idiomatic style guides) that flatten the AI-vs-human distinction.

For language selection in an AI-heavy project: TypeScript preserves stylistic diversity, JavaScript converges. The two are not equivalent for AI-assisted development.

### AI does not generate more duplicate code than humans

Pattern-cluster density (DRY pairs above per-language calibrated threshold, divided by function count):

| Bucket | Mean DRY density |
|---|---|
| Low-AI repos | 8.24 pairs / function |
| Mid-AI | 8.36 |
| High-AI | 7.37 |

The slight inverse trend (high-AI repos have *fewer* DRY-style pairs per function) runs counter to the common assumption that AI generates lots of duplicate code. AI-generated functions cluster differently from each other than human functions do, but they don't cluster *more*. The "AI generates 14 versions of pagination" concern is not visible at this benchmark's scale.

### The most-isolated functions in AI-heavy repos are not disproportionately human

We expected: in AI-dominated codebases, the rare hand-coded functions (custom infrastructure, one-off utilities) would survive as the most-isolated tail, with humans over-represented relative to the repo's overall AI rate.

Across 15 high-AI repos, the bottom 10% most-isolated functions had AI authorship within ±10% of the repo's overall AI rate in 10 of 15 repos. Only 3 of 15 showed a meaningful human surplus in the isolated tail (notably `bmad-module-skill-forge`: 81% AI overall, only 54% AI in the isolated functions). 2 of 15 went the other direction, with AI over-represented in isolation.

The "humans hand-craft the rare edges" mental model is wrong on average, though it does apply in specific repos. AI writes its share of the rare-shaped code too.

### AI Python is slightly simpler at most function sizes — except the 21–50-line band

For Python functions across 5 repos with both AI and human samples (cyclomatic complexity via radon):

| Function size | AI mean CC | Human mean CC | Δ (AI − Human) |
|---|---|---|---|
| 4–10 lines | 1.73 | 1.79 | **−3%** AI simpler |
| 11–20 lines | 2.67 | 2.72 | **−2%** AI simpler |
| 21–50 lines | **5.07** | **4.57** | **+11%** AI more complex |
| 51+ lines | 12.82 | 12.95 | **−1%** AI simpler |

At small sizes (≤20 lines) and very large sizes (51+), AI Python has slightly lower cyclomatic complexity than human Python at matched function size. In the 21–50-line band — which contains most "real function" sizes in production code — AI is 11% more complex per function. The directional reversal in this specific size band warrants further investigation in the next quarterly run.

## Hypothesis tests

The five pre-registered hypotheses from the methodology and how the data fell:

| # | Pre-registered direction | Direction in data | Magnitude |
|---|---|---|---|
| H1 | AI more uniform than human within repo | ✓ confirmed | +0.00034 mean (CI95 [−0.0013, +0.0020]) |
| H2 | Gap correlates with repo AI ratio | ✓ confirmed | Pearson r = 0.579 |
| H3 | DRY density higher in AI-heavy | ✗ counter-prediction | High = 7.37, Low = 8.24 |
| H4 | Isolated functions disproportionately human | ✗ counter-prediction | Mean surplus = +0.002, 3/15 repos show human surplus |
| H5 | AI lower CC than human at matched size | ✓ confirmed (3/4 bins) | Reversed in 21–50-line band |

Full test details: [`analysis/hypotheses.json`](analysis/hypotheses.json).

## Layout

```
agent-uniformity-q2-2026/
├── methodology.md          frozen at v0.1.0
├── sampling.md             48 repos with HEAD SHAs at run time
├── manifest.json           run-time environment snapshot
└── analysis/
    ├── hypotheses.json
    ├── summary.csv         one row per repo
    ├── by_language.csv     per-language aggregates
    ├── by_bucket.csv       per AI-bucket aggregates
    ├── most_isolated.csv   top-50 most-isolated functions across all repos
    ├── dry_pairs_top.csv   top-100 DRY-cluster pairs by similarity
    ├── H4_isolation_by_authorship.csv
    └── H5_complexity_by_authorship.csv
```

## Raw data

Per-repo function-level outputs (~120 MB) — every function with its AI ratio, similarity scores, cyclomatic complexity, comment density, line range, plus the per-repo DRY pair list — are published as a HuggingFace dataset:

🤗 **[saucam/agent-uniformity-q2-2026](https://huggingface.co/datasets/saucam/agent-uniformity-q2-2026)**

The dataset also contains the regenerated `report.json` (~125 MB) covering all 48 task results in the canonical schema.

## Reproduction

The analysis code that produced these numbers lives in a separate public package:

📦 **[saucam/agent-uniformity](https://github.com/saucam/agent-uniformity)** (MIT-licensed Python package)

Install and re-run any single repo against the locked SHA:

```bash
pip install agent-uniformity
agent-uniformity run-one davila7-claude-code-templates --output ./out
```

The published numbers in `analysis/summary.csv` were produced by the same code path. The `agent-uniformity` package is what we use internally; you run identical analysis on identical SHAs and should get matching numbers within semble's small non-determinism (~1%).

To re-run the full 48-repo benchmark sequentially:

```bash
agent-uniformity run-all --output ./out  # ~6–8 hours single-process
agent-uniformity aggregate ./out          # writes analysis CSVs + hypotheses.json
```

## License

| Component | License |
|---|---|
| Methodology, sampling, README, analysis CSVs | CC BY 4.0 |
| HuggingFace dataset (partials + report.json) | CC BY 4.0 |
| `agent-uniformity` package | MIT |
| Per-repo source code referenced in sampling | original upstream licenses |

## Citation

```
Datta, Y. (saucam). (2026). Code Uniformity Q2 2026 — How AI authorship
reshapes the structure of public open-source code. Agent Almanac.
https://github.com/saucam/agent-uniformity-q2-2026
```

## Contact

Issues and corrections: open an issue here.
General correspondence: agentalmanac.com — saucam on GitHub and X.

## Changelog

| Date | Run ID | Notes |
|---|---|---|
| 2026-05-10 | 2026-05-09T15-02-36Z-4931 | Initial publication. 48 repos sampled, 47 with full data; `BoundaryML/baml` excluded from aggregates due to per-task time-out at 60 min. |
