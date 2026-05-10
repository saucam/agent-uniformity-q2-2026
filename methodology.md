# Methodology — *State of AI-Generated Code* (Q2 2026)

**Version:** `0.1.0`
**Frozen on:** 2026-05-08 (before any sampling or measurement)
**Canonical URL:** `agentalmanac.com/methodology/code-uniformity-q2-2026`
**Authors:** Yash Datta · saucam
**License:** CC BY 4.0 (methodology) — see `repro_kit/` for code license

---

## 1. What this report measures

The structural impact of AI authorship on production code. Specifically: when AI agents (Claude Code, Cursor, Aider, etc.) author code that ends up merged into public repositories, how does that code differ from human-written code in the same repo, across the same language, and across languages?

The report is **descriptive empirical**, not prescriptive. We measure observed properties; we do not claim AI code is "better" or "worse" without an explicit quality proxy attached.

## 2. The wedge

Most takes about AI-generated code are speculative or anecdotal. We measure what AI authorship does to the code that humans (and other agents) read, debug, and modify next month: uniformity, repetition, cohesion, isolation, naming consistency, complexity. These are the levers of downstream readability and maintenance cost.

## 3. Pre-registered hypotheses

Locked at methodology-freeze time, before sampling. We will report results whether or not these hold.

| # | Hypothesis | Direction predicted | Why |
|---|---|---|---|
| H1 | AI-authored functions have higher mean top-K similarity to other functions in the same repo than human-authored functions | AI > human | AI tools converge on shared patterns from training data |
| H2 | The AI-vs-human similarity gap (H1 magnitude) grows with the repo's overall AI authorship ratio | Positive correlation | More AI code = AI patterns dominate the repo |
| H3 | DRY-cluster density is higher in AI-heavy repos | AI-heavy > human-heavy | AI generates lookalike functions instead of factoring shared helpers |
| H4 | The most-isolated functions in AI-heavy repos are disproportionately human-authored | Yes | Hand-coded edges (provider integrations, rare utilities) survive as the unique parts |
| H5 | AI code has lower cyclomatic complexity per function than human code at matched function size | AI < human | AI tools default to simple control flow |
| H6 | Across languages, the AI uniformity gap (H1) varies — some languages produce more native-feeling AI output than others | Variation present | Different training-data densities, idiom complexity |

We additionally pre-register exploratory questions where we have no directional prediction:

- E1: Does cross-language semantic mirroring scale with AI ratio in multilingual repos?
- E2: Is there a U-curve between repo uniformity and project popularity (stars × commit cadence)?
- E3: Does comment density correlate with AI authorship?

## 4. Definitions

### 4.1 AI authorship — ground truth

A commit is classified as **AI-authored** if any of the following hold:

1. Commit message contains literal text `Co-Authored-By: Claude` (the Claude Code default footer)
2. Commit message contains literal text `Generated with [Claude Code]`
3. Author name contains a parenthetical AI tag: `(aider)`, `(claude-...)`, `(claude-sonnet-...)`, `(claude-opus-...)`, `(gpt-...)`

A line of code is AI-authored if its `git blame` SHA is in the AI-authored commit set.

A function's **AI ratio** = (count of AI-authored lines within the function's line range) / (total lines in function range).

We acknowledge this signal is conservative: AI commits without these markers are not detected. False positive rate is near zero (the markers are explicit). False negative rate is unknown but likely substantial.

### 4.2 Function selection

We extract top-level functions and class methods using language-specific AST/tree-sitter parsers:

- Python: `ast` module
- JavaScript / TypeScript: `tree-sitter-javascript`, `tree-sitter-typescript`
- Go: `tree-sitter-go`
- Rust: `tree-sitter-rust`

Inclusion criteria:
- Function body ≥ 4 source lines (excludes one-line stubs)
- Not in test directories (any path containing `/test`, `/tests`, `/spec`, `__tests__`)
- Not in vendored code (`/vendor`, `/node_modules`, `/dist`, `/build`, `/__pycache__`, `/venv`)
- Not in migrations (`/migrations` for Django/Rails-shaped repos)
- Public name (not starting with `_` for Python, except dunders); language-appropriate visibility for others

### 4.3 Similarity

Computed by **semble** (`MinishLab/semble`, version locked per run). Semble's hybrid retrieval combines:

- Static embeddings via Model2Vec (`potion-code-16M` model)
- Lexical matching via BM25
- Reciprocal Rank Fusion to combine

Semble version is captured per run (`semble.__version__`). We use semble's defaults for indexing; no manual hyperparameter tuning. This locks results to a known, reproducible configuration.

For each function we query semble with the function body (truncated to 1500 chars) and read the top-15 nearest chunks. We exclude self-matches (same file with overlapping line range). The remaining 10 are the function's **siblings**.

### 4.4 The metrics

#### Axis 1 — Pattern Uniformity

| Metric | Formula | Range | Interpretation |
|---|---|---|---|
| `mean_topk_sim` | mean(score for top-10 siblings excluding self) | 0..1 (typically 0.005–0.05 in semble) | Function fits a common pattern (high) vs unusual (low). **Raw signal — context-dependent.** |
| `top1_sim` | score of nearest sibling | 0..1 | If high with cross-file pair → DRY merge candidate |
| `repo_uniformity_index` | mean(`mean_topk_sim`) across all functions | 0..1 | Codebase-level convergence |
| `pattern_cluster_density` | (DRY pairs above per-language threshold) / (function count) | ≥0 | **Lower is better for maintainability** (less duplicated structure) |

#### Axis 2 — Cohesion vs Coupling

| Metric | Formula | Interpretation |
|---|---|---|
| `same_file_cohesion` | mean(score) for sibling pairs in same file | **Higher is generally better** — related code stays together |
| `cross_file_coupling` | mean(score) for sibling pairs in different files | Lower is better (less structural duplication across the codebase) |
| `cohesion_coupling_ratio` | `same_file_cohesion` / `cross_file_coupling` | **Higher is better** — code organized by responsibility |

#### Axis 3 — Isolation

| Metric | Formula | Interpretation |
|---|---|---|
| `isolation_rate` | % of functions with `mean_topk_sim` below 1st percentile of repo | Raw signal; both extremes interesting |
| `most_isolated_top_n` | bottom-N functions by `mean_topk_sim` | The repo's "hand-curated edges" — protect during refactors |

#### Axis 4 — AI Authorship Correlation

| Metric | Formula | Interpretation |
|---|---|---|
| `ai_ratio` | (AI-authored lines) / (total lines) at repo level | Raw signal — used to stratify all other metrics |
| `ai_uniformity_gap` | mean(`mean_topk_sim` \| AI ratio ≥ 0.7) − mean(`mean_topk_sim` \| AI ratio ≤ 0.1) | H1 magnitude. Positive = AI code is more uniform |
| `ai_cluster_contribution` | % of DRY pairs where ≥1 function has AI ratio ≥ 0.7 | Higher = AI is the source of duplication |
| `ai_isolation_rate` | % of high-AI functions that are isolated | Lower expected; surprisingly high values would be interesting |

#### Axis 5 — Cross-Language (multilingual repos only)

| Metric | Formula | Interpretation |
|---|---|---|
| `cross_lang_pair_count` | # of DRY pairs above threshold where source.language ≠ target.language | High → shared logic mirrored across languages |
| `cross_lang_pair_score` | mean score of cross-language pairs | Tightness of the mirroring |

#### Axis 6 — Per-Language Comparison (across all 50+ repos)

| Metric | Formula | Interpretation |
|---|---|---|
| `language_uniformity_index` | mean(`repo_uniformity_index`) across repos in this language | Raw signal — language tendency |
| `language_ai_gap` | mean(`ai_uniformity_gap`) across repos in this language | Lower = AI writes natively in this language; higher = AI imposes alien pattern |
| `ai_friendliness_rank` | composite ranking (see Axis 7) | Headline leaderboard for the report |

#### Axis 7 — Composite

| Score | Components | Use |
|---|---|---|
| `ai_code_health_score` (per repo) | `(cohesion - coupling) × (1 - cluster_density) × (1 - ai_uniformity_gap)`, normalized | One-number summary for "how cleanly is AI integrated" |
| `ai_friendliness_rank` (per language) | mean(`ai_code_health_score`) across repos in language | The leaderboard chart |

#### Axis 8 — Quality Proxies (added per decision 1)

These come from independent tooling and let us cross-reference uniformity findings with traditional quality signals.

| Metric | Tool | Interpretation |
|---|---|---|
| `cyclomatic_complexity_per_function` | `radon` (Python), `lizard` (multi-lang) | Lower generally easier to read |
| `lines_per_function` | AST | Distribution shape; outliers are interesting |
| `comment_density` | line counter | Lines starting with `#`/`//`/`/*` ÷ total non-blank lines |
| `project_popularity` | GitHub API | log(stars) + log(commits last 90d) + log(PRs last 90d) |
| `test_ratio` | path-based count | (lines under `/tests/` or `/test/`) / (total lines) |

### 4.5 Per-language similarity threshold (decision 4)

Different languages have different inherent similarity densities (Python has dense embeddings; Rust has more lexical variance). We **calibrate the DRY threshold per language** at the **95th percentile of the within-repo pair-similarity distribution** for repos at that language's bottom AI bucket (low-AI baseline). This bucket establishes "natural" similarity for human code in that language. The threshold is then applied uniformly to all repos in that language.

Thresholds are reported in the methodology output and can be inspected per-language.

## 5. Sampling

### 5.1 Universe

Public GitHub repositories where the AI ratio can be computed (i.e., commits include detectable AI authorship signals or are clearly absent). Excludes:

- Private / archived repos
- Repos whose primary language is not in the v1 set (Python, JavaScript, TypeScript, Go, Rust)
- Repos under 100 functions (per inclusion criteria above)
- Repos over 2 GB on disk
- Forks (we use the canonical upstream)
- Repos where commit history is unavailable / squashed-only (<= 50 visible commits)

### 5.2 Stratification

5 single-language buckets × 3 AI-ratio strata × ~3.3 repos per cell = **50 single-language repos**. Plus ~5 multilingual repos for Axis 5 = **~55 total**.

|  | Low AI (<30%) | Mid AI (30–70%) | High AI (>70%) | Total |
|---|---|---|---|---|
| Python | ~3 | ~3-4 | ~3 | 10 |
| TypeScript | ~3 | ~3-4 | ~3 | 10 |
| JavaScript | ~3 | ~3-4 | ~3 | 10 |
| Go | ~3 | ~3-4 | ~3 | 10 |
| Rust | ~3 | ~3-4 | ~3 | 10 |
| Multilingual | ~2 | ~2 | ~1 | ~5 |
| **Total** | ~17 | ~19 | ~16 | **~55** |

Within each cell:
- Half by GitHub stars (popularity-weighted)
- Half by recent commit activity (last 90 days)

This avoids over-sampling famous-but-stale repos and no-name-but-AI-heavy repos. The selected repo list is published in `sampling.md` after discovery; the SHA of each repo at clone time is captured.

### 5.3 Reproducibility per repo

For each repo, we capture and publish:

- Full URL
- `git rev-parse HEAD` (commit SHA at time of analysis)
- `git describe --tags --always` (nearest tag)
- Repo size in MB
- Function count (after inclusion filtering)
- AI ratio (computed)
- Language(s) detected
- Run timestamp
- semble version
- methodology version

These let any reader fully reproduce the run. The harness is closed-source (methodology is the moat, per Agent Almanac's open/closed policy); the per-report **repro kit** includes a single-repo reproduction script for any number challenged in the report.

## 6. Statistical handling

- Confidence intervals: **bootstrap (1000 iterations)** for any reported mean
- Multiple-comparison correction: **Benjamini-Hochberg** at α=0.05 across all hypothesis tests reported
- Outliers: never silently removed; reported separately if dropped from a chart
- Tied scores: reported as ties; ranks use mean-rank handling
- Per-language thresholds: published, not buried

## 7. What this methodology does NOT cover (v1 scope)

- Functional correctness (does the code work?)
- Type / bug density (would need static analysis or runtime tests)
- Security (would need SAST tools)
- Performance (would need profiling)
- Long-tail languages beyond top 5

These are out of scope for v1. v2 may add complexity-density combined metrics (Axis 8) and security proxies.

## 8. Bias and caveats

- **AI detection is conservative.** Our ground truth catches Claude-tagged commits. Cursor, Copilot, Aider-without-tag, GPT-via-curl, and Claude-via-API-without-footer are missed. Real AI ratios are likely **higher than reported**.
- **Repo selection bias.** Repos that publicly use AI footers self-select for "willing to advertise AI use." This may skew the high-AI bucket toward indie / hobby / agentic-tool projects. Documented as a caveat.
- **Semble similarity is not "true" semantic similarity.** It's hybrid lexical+embedding retrieval. Functions with shared variable names will score higher even if logically distinct.
- **Language coverage.** Top 5 languages cover most modern web/infra/ML, but exclude C/C++/Java/PHP/Ruby/Swift/Kotlin. v2 expansion planned.
- **Static analysis.** semble does not see runtime behavior, dynamic dispatch, reflection, or metaprogramming. Languages with heavy runtime polymorphism (Ruby, JavaScript) may underestimate true similarity.

## 9. Versioning

Any change to:
- Hypothesis set
- Metric definition
- Threshold formula
- Sampling stratification
- AI detection signal set

…requires a methodology version bump (`0.1.0` → `0.2.0`). Old reports remain published with their methodology version stamped; new reports cite the new methodology.

Patch versions (`0.1.0` → `0.1.1`) are reserved for non-substantive corrections (typos, broken links, clarifications).

## 10. Open / closed policy

| Component | License / access |
|---|---|
| This methodology document | CC BY 4.0 — public, citable |
| Per-report **repro kit** (single-repo reproduction) | MIT — `github.com/saucam/agent-bench/<report-slug>` |
| Full benchmark **harness** | Closed source. Available to subscribers via the report's appendix. |
| Per-repo metric output JSON | Public, attached to the free post |
| Combined CSV (50+ repos × all metrics) | **Paid report exclusive.** |
| Raw per-function CSVs | **Paid report exclusive.** |

## 11. Changelog

| Version | Date | Change |
|---|---|---|
| `0.1.0` | 2026-05-08 | Initial methodology. Pre-registered hypotheses. 50+5 repo stratified sample across Python / TypeScript / JavaScript / Go / Rust + multilingual. Per-language calibrated DRY thresholds. Bootstrap CIs, Benjamini-Hochberg correction. |

---

*Methodology questions, corrections, or replication notes:* open an issue at `github.com/saucam/agent-bench`.
