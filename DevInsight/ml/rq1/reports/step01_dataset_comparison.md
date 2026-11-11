# RQ1 Step 1 — Versioned benchmark comparison

**Research and acquisition date:** 2026-11-12

## Selected source and provenance

**Selected:** JEdit class-level releases from [Zenodo record 4625975](https://zenodo.org/records/4625975), “Software Defect Prediction Datasets,” Sultan Alhusain, version 1, DOI [10.5281/zenodo.4625975](https://doi.org/10.5281/zenodo.4625975). Zenodo metadata identifies the record as open access under **CC BY 4.0**. Its description says the 36 datasets represent versions of 13 open-source Java systems and cites:

> S. Alhusain, “Predicting Relative Thresholds for Object Oriented Metrics,” 2021 IEEE/ACM International Conference on Technical Debt (TechDebt), 2021, pp. 55–63. DOI: [10.1109/TechDebt52882.2021.00015](https://doi.org/10.1109/TechDebt52882.2021.00015); author manuscript: [arXiv:2103.11442](https://arxiv.org/abs/2103.11442).

The paper’s Dataset Preparation section states that each source dataset contains classes and their defect counts, and that classes are relabeled faulty when defect count is **at least one**, otherwise not faulty. It says the PROMISE and Bug Prediction Dataset source tables were regenerated using a common tool and that the regenerated tables are the Zenodo workbook. This supports the binary semantics used below. The workbook sheet identifier `jedit_4_1` etc. establishes project/version labels, but actual release dates were not independently verified; this is a **release-order** design, not a fully verified temporal split.

## Dataset candidates investigated

| Candidate | Observed evidence | Decision |
|---|---|---|
| Zenodo 4625975 regenerated PROMISE/BPD workbook | Downloadable `.xlsx`; CC BY 4.0 in Zenodo metadata; paper cited by the record explains class defect-count binarization and common regeneration; versioned JEdit class sheets with numeric metrics | **Selected.** The licensed workbook is the acquired source. |
| `feiwww/PROMISE-backup` GitHub mirror | Public mirror with Ant/Camel/JEdit release files; repository reports no license. Sample count-style `bug` values include values greater than one. Mirror is not treated as original provenance or license evidence. | Not acquired or used. Numeric `bug` is not assumed to be binary. |
| `jalaxy33/PROMISE-dataset` GitHub mirror | README describes `name`/`version`, source path, handcrafted features, and a final file-wise `bug` label. Its JEdit sample contains values greater than one; GitHub reports no license. It references source code versions but is a community mirror. | Used only to corroborate file/class-oriented schema context; not acquired, copied, or treated as licensed. |
| PROMISE/NASA JM1, OpenML 1053 v1 | Prior acquired module-level C benchmark; no release identifiers; source class counts conflicted with downloaded counts; 88 conflicting duplicate-feature groups | Retained unchanged as a prior candidate, **not selected**. The versioned JEdit benchmark better supports a release-order holdout and class-level unit. |
| PROMISE/NASA KC1, OpenML 1067 v1 | Prior acquired comparison module-level benchmark; no release identifiers | Retained unchanged as a prior comparison, not selected. |

No license or provenance from either GitHub mirror is inferred from the Zenodo record. No new raw data was copied from those mirrors.

## Selected schema and prediction unit

- **Project:** JEdit (Java).
- **Prediction unit:** class in a specific project release; one row per `ClassName` per release sheet.
- **Identifier:** `ClassName`, for audit only; exclude from predictors.
- **Six numeric features:** `CBO`, `DCC`, `ExportCoupling`, `ImportCoupling`, `NOM`, `WMC`.
- **Target:** `Defect`, observed as binary `0`/`1`.
- **Label mapping verified from the cited paper:** `Defect=1` means a class had one or more defects; `Defect=0` means not-faulty/zero defects. The workbook uses a binary target; it does not preserve the underlying defect count.
- **Missing target semantics:** a blank target would be unknown, not a negative label. No target or feature cells are missing in any inspected JEdit release.
- **Project/version information:** release is encoded in the sheet name, not a row-level column. `ClassName` is present within each sheet.

## Release-order holdout candidate

Proposed sequence: **train `jedit_4_1` → validate `jedit_4_2` → test `jedit_4_3`**. This uses the latest available release as the final holdout and preserves ordered release identifiers. Dates and label collection windows are not independently established, so do not call it a verified temporal split. The test release has only 11 positive examples and is highly imbalanced (459 negative / 11 positive); performance estimates would be uncertain.

The workbook contains repeated class identifiers, feature vectors, and full rows across releases. Proposed leakage policy for Main Step 2:

1. Keep raw workbook and all release rows unchanged. Do not remove a class simply because it occurs in multiple releases.
2. Keep releases partitioned by version; never randomly mix rows from one release across partitions. Exclude `ClassName` from model features.
3. Report the full release-order evaluation and separately report a novel-feature-vector cohort that excludes test inputs exactly observed in earlier releases. This is an evaluation cohort policy, not raw-data deletion. In the proposed `jedit_4_3` test, 360 rows (including all 11 positive rows) have feature vectors not seen in earlier JEdit releases; 110 rows have a previously seen vector.
4. Preserve repeated observations and label changes as longitudinal evidence. Do not silently deduplicate, overwrite labels, or treat a matching feature vector as a matching class.
5. Before Main Step 2, decide how to handle within-release repeated feature vectors with conflicting labels (one conflicting vector group each in `jedit_4_0` and `jedit_4_3`). Keep the rows and original labels intact; any exclusion/grouping policy must be explicit and sensitivity-reported.

This is a feasible, leakage-aware release-order design, but it does not establish unseen-project generalization or certified temporal prediction. The underlying defect-observation windows and whether the count is cumulative or version-bounded are not stated in the workbook. The small, imbalanced `jedit_4_3` target further limits conclusions.

## Relevance and limitations for DevInsight

The dataset offers six object-oriented static metrics, binary class-level defect labels, and repeated versions, so it is a better preliminary benchmark than JM1 for a version-held-out class-level experiment. It is Java and does not contain DevInsight’s selected Python/Dart GitHub files or operational GitHub signals. It does not establish the performance of a live DevInsight model.

| Official proposal feature | Status | Evidence / boundary |
|---|---|---|
| Commit frequency | UNAVAILABLE | No commits or timestamps. |
| Changed lines | UNAVAILABLE | Features are class-level object-oriented metrics, not change deltas. |
| Number of contributing developers | UNAVAILABLE | No contributor/author data. |
| Historical bug information | PROXY_ONLY | Binary class defect target derived from defect counts; no counts, issue links, dates, or fixing relationships are retained. |
| Static analysis indicators | PROXY_ONLY | Six static object-oriented metrics; not analyzer warnings/findings. |
| CI/CD failure links | UNAVAILABLE | No build, test, or pipeline fields. |

No prediction, ranking, model metric, SHAP, LLM inference, or root-cause claim is supported by this dataset-selection step.
