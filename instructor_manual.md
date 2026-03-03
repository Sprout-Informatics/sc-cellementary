# From Counts to Cell Types
## Single-Cell RNA-Seq Workshop — Instructor Manual
**Boston Women in Bioinformatics | Sponsored by Sprout Informatics**
⚠️ **CONFIDENTIAL — NOT FOR DISTRIBUTION TO STUDENTS**

---

## Contents

1. [Workshop Logistics & Timing](#logistics)
2. [Day 1 Teaching Guide](#day1)
3. [Day 2 Teaching Guide](#day2)
4. [Complete Answer Keys](#answers)
5. [QC Plot Interpretation Guide (Instructor)](#qc)
6. [Cell Type Annotation Reference](#annotation)
7. [Troubleshooting Guide](#troubleshooting)
8. [Extension Exercises](#extensions)
9. [Series Preview: Parts 2 & 3](#preview)

---

## 1. Workshop Logistics & Timing {#logistics}

### Full Learning Objectives

By the end of both days, participants should be able to:

1. Explain why scRNA-seq is used over bulk RNA-seq for heterogeneous samples
2. Load and inspect a 10x Genomics count matrix in Seurat
3. Compute nFeature_RNA, nCount_RNA, and percent.mt; interpret each biologically
4. Choose and justify filtering thresholds; understand the risk of over-filtering
5. Normalize gene expression and explain the need for log transformation
6. Identify highly variable genes and explain their role in dimensionality reduction
7. Read an elbow plot and select an appropriate number of PCs
8. Interpret a UMAP — what proximity means and what it does not
9. Use FindAllMarkers output (logFC, pct.1, pct.2, p_val_adj) to identify cell types
10. Identify the dominant PBMC cell type with evidence from cluster size and markers

### Recommended Timing

| Time Block | Content |
|---|---|
| **Day 1** | |
| 0:00–0:15 | Welcome, introductions, workshop goals |
| 0:15–0:35 | Conceptual: bulk vs scRNA-seq, 10x experiment, PBMC dataset |
| 0:35–1:00 | Hands-on: load data, explore Seurat object (Exercise 1.1) |
| 1:00–1:30 | Hands-on: QC metrics, violin & scatter plots (Exercise 1.2) |
| 1:30–1:45 | Hands-on: apply filters, discuss thresholds |
| 1:45–1:55 | Group discussion: overnight reflection question |
| 1:55–2:00 | Wrap-up & preview of Day 2 |
| **Day 2** | |
| 0:00–0:10 | Recap quiz, Q&A on Day 1 |
| 0:10–0:35 | Hands-on: normalize, variable genes, PCA, elbow plot (Exercise 2.1) |
| 0:35–1:00 | Hands-on: clustering, UMAP, visual exploration |
| 1:00–1:25 | Hands-on: FindAllMarkers, feature plots (Exercise 2.2) |
| 1:25–1:50 | Group work: annotate clusters, identify dominant cell type |
| 1:50–2:00 | Debrief, assignment overview, series preview |

### Compute & Technical Setup

- Google Cloud VMs (4–5 instances), pre-loaded with R, RStudio, Seurat v5
- Data pre-downloaded to `/home/prisnirath/singlecell/data/raw/` on each VM
- `workshop.R` available via GitHub

> **💡 Instructor Tip:** Pre-run the entire script before Day 1 and save `pbmc_part1_clustered.rds`. If a student's session crashes or compute is slow on the expensive steps (PCA, UMAP, FindAllMarkers), they can skip ahead with:
> ```r
> pbmc <- readRDS("results/pbmc_part1_clustered.rds")
> ```

---

## 2. Day 1 Teaching Guide {#day1}

### Opening (0–15 min)

**Facilitation suggestions:**
- Ask the room: "How many of you have done bulk RNA-seq before?" vs "How many have touched scRNA-seq data?" — calibrate depth accordingly
- Use the bulk vs scRNA-seq slide as a discussion anchor. Let participants answer before you explain
- State the central question early and return to it at every step: "Everything we do answers one biological question"

---

### Conceptual Background (15–35 min)

**Key teaching points:**

- **The droplet concept:** "One droplet ≈ one cell — ideally." Emphasize *ideally*. Doublets are real, common (~1–10% of captures depending on cell loading density), and something we actively try to detect.
- **Two layers of barcoding:** Barcode = which cell; UMI = which individual RNA molecule. Students often confuse these. Analogy: barcode = your library card; UMI = the stamp on each book that tells you it's a unique copy.
- **The matrix is sparse:** In a typical scRNA-seq experiment, >90% of the gene×cell matrix entries are zero. This is a feature, not a bug — it reflects real biology. Most genes are not expressed in any given cell at any given moment.

> **⚠️ Common Misconception:** Students assume all barcodes = real cells. Clarify: the RAW matrix contains hundreds of thousands of barcodes, most of them empty droplets. CellRanger's filtered matrix applies a cell-calling algorithm, but we still need to QC the filtered output.

---

### Exercise 1.1 — Answer Key: Load Data

**Expected Seurat object output (approximate):**

```
An object of class Seurat
33538 features across 737280 samples within 1 assay
```

Numbers vary with dataset version. The key takeaway is that barcodes >> real cells.

| Question | Expected Answer |
|---|---|
| How many genes? | ~33,000–36,000 (full human transcriptome from 10x panel) |
| How many barcodes? | ~700,000+ — the vast majority are empty droplets |
| What does one column represent? | The expression profile of ONE barcode: a vector of UMI counts, one value per gene |

> **💡 Teaching Prompt:** Ask: "If there are 700,000 barcodes, does that mean we sequenced 700,000 cells?" Let them discuss. Drive home that QC is how we identify real cells within this barcode pool.

---

### QC Metrics — Teaching Notes (35–60 min)

#### Interpreting Each Metric

| Metric | Biology | Typical PBMC Values |
|---|---|---|
| nFeature_RNA | Distinct genes detected per cell. Low = empty/dead. High = doublet. | 500–3,500 real cells |
| nCount_RNA | Total UMIs per cell (sequencing depth). Correlated with nFeature — outliers off the diagonal are suspicious. | 1,000–15,000 real cells |
| percent.mt | In dying cells, cytoplasmic membrane ruptures and cytoplasmic RNA leaks out. Only mitochondrial RNA remains (protected inside organelles). So dying cells appear enriched for MT genes. | < 10% in healthy blood cells |

#### Analogy for nFeature vs nCount

> "nFeature_RNA = number of different book titles in a library. nCount_RNA = total number of books (including duplicate copies). A big library might have many copies of a few popular titles (high nCount, low nFeature) — that would be suspicious."

---

### Exercise 1.2 — Answer Key: QC Plot Interpretation

**What students should observe in this dataset's plots:**

- **nFeature_RNA violin (log scale):** Bimodal — large spike near 1 (empty droplets) and a distribution centered around 2,000–4,000 for real cells. The log scale reveals this separation clearly.
- **nCount_RNA violin (log scale):** Similarly bimodal. Real cells cluster above ~1,000 UMIs.
- **percent.mt violin:** Most cells near 0–10%; a long tail reaching 100% marks clearly dead cells.
- **nCount vs nFeature scatter:** Tight diagonal — confirms UMI and gene counts are correlated as expected in healthy cells.
- **nCount vs percent.mt scatter:** Inverse relationship visible — the classic "low UMI + high mito = dying cell" signature appears in the upper-left of the plot.

**Model threshold justification (what students should write):**

```
Thresholds applied: min_genes = 200, max_genes = 3000, max_mito = 10%
Result: 1,700 cells retained

min_genes = 200: Removes empty droplets and barcodes with negligible transcriptional content.
max_genes = 3,000: Removes likely doublets (conservative for PBMCs; some activated cell types
  may legitimately exceed this, so this could be relaxed to 4,000 with justification).
max_mito = 10%: Standard PBMC threshold. Circulating blood cells are not normally
  mitochondria-rich; values above 10% suggest damaged or dying cells.
```

> **⚠️ Discussion Prompt — Over-filtering Risk:** Ask: "If we set max_genes = 2,000, what might we lose?" Answer: Monocytes and activated T cells can express 3,000+ genes. Over-filtering could remove these populations entirely — potentially leading to the false conclusion that no monocytes are present in the sample. This is a real concern in rare cell type discovery.

---

### Common Student Mistakes — Day 1

| Mistake | How to Address It |
|---|---|
| Setting percent.mt < 5% (too strict) | Show they lose 20–30% of real cells. Ask them to re-run with 10% and compare cell counts. |
| Setting min_genes = 100 and seeing a messy UMAP | Low-quality cells add noise. Explain that downstream clustering is sensitive to this input quality. |
| Confusing nFeature_RNA with nCount_RNA | Use the library book analogy above. |
| Not understanding what percent.mt biologically means | Draw the dying cell model: cytoplasm leaks → cytoplasmic RNA lost → MT RNA enriched. |
| Worried about "losing" data by filtering | Reassure: 1,700 clean cells gives better biological signal than 50,000 noisy barcodes. Quality > quantity. |

---

## 3. Day 2 Teaching Guide {#day2}

### Day 2 Opening Recap (0–10 min)

**Quick verbal quiz — ask the room:**
- "What does percent.mt measure, and why do we care?"
- "What is the difference between nFeature_RNA and nCount_RNA?"
- "Overnight question: what do you think a cluster represents?"

Expected answer to the last question: a cluster = a group of cells with similar transcriptional profiles, often corresponding to a cell type or cell state.

---

### Normalization — Teaching Notes (10–20 min)

**Analogy:**

> "If Cell A was sequenced to 2,000 UMIs and Cell B to 10,000 UMIs, comparing raw gene counts is like comparing 'how many apples' between a corner store and a supermarket — the supermarket will always look like it has more of everything, even if the proportions are identical. Normalization divides each cell's counts by its total, multiplies by 10,000, then log-transforms. After this, a count of 2 for Gene X in Cell A means the same thing as 2 in Cell B."

**Common question:** "Why 10,000?" — Convention. Sometimes called CPM or TP10K. The exact number matters less than consistency across all cells in your experiment.

---

### Highly Variable Genes — Teaching Notes

- **Biological reason:** Housekeeping genes (GAPDH, ACTB, ACTG1) are expressed at similar levels in every cell type. They don't help distinguish a T cell from a B cell — they just add noise.
- **Computational reason:** 30,000 genes in PCA means 30,000 dimensions. That is computationally expensive and most of those dimensions are pure noise. 2,000 informative genes is enough.
- **VST method:** Variance-stabilizing transformation accounts for the mean-variance relationship. High-count genes tend to show high variance just from count statistics, not biology. VST corrects for this, so the 2,000 selected genes are genuinely biologically variable, not just highly expressed.

---

### PCA — Teaching Notes (20–35 min)

PCA takes 2,000 gene dimensions and compresses them into principal components. PC1 captures the most variation, PC2 the second most, and so on. In a typical scRNA-seq dataset, the first ~15–30 PCs capture meaningful cell type differences; the rest is mostly technical noise.

**What do individual PCs represent?** PCs don't have clean biological interpretations, but you can check which genes load most strongly onto each PC with `VizDimLoadings(pbmc, dims = 1:4)`. PC1 often separates myeloid from lymphoid cells; PC2 might separate T from B cells.

---

### Exercise 2.1 — Answer Key: Elbow Plot

**Observed in `pca_elbowplot.png` for this dataset:**

- PC1 standard deviation: ~10.5 (large — captures major cell type differences)
- PC2–4: ~8.2, ~7.9, ~7.5 (still informative)
- PC5: ~6.5 (notable drop)
- PC6–8: ~4.2, ~3.2, ~3.1 (second, gentler inflection)
- PC9 onward: gradual plateau toward ~2.0
- PC20+: essentially flat

**Model answer:**

> PCs 1:15 clearly capture biological structure, with visible inflections at PC5 and PC7–8. Using 1:30 is a conservative, standard choice — it captures all the signal and includes some near-noise PCs that rarely hurt results. Using 1:10 risks missing rare populations (NK cells, plasmacytoid DCs). Students should be comfortable with the range 1:15 to 1:30 for this dataset.

> **⚠️ Students ask:** "Is there a correct answer?" Tell them: the elbow plot is a guide, not a rule. Seurat's implicit default of 1:20–30 is reasonable. Sensitivity analysis (try 10, 20, 30 and compare final cluster numbers) is good practice.

---

### UMAP — Teaching Notes

> **Critical concept to reinforce repeatedly:** UMAP preserves **local** structure. If two cells are near each other, they are transcriptionally similar. But the distance *between* clusters is not quantitatively meaningful — don't interpret "Cluster 7 is far from Cluster 0" as biologically significant distance.

Also: UMAP is stochastic. Running with a different random seed gives a different visual layout. Cluster identities are stable, but the visual arrangement may look completely different. Always use `set.seed()` before `RunUMAP()` for reproducibility.

---

### Clustering — Teaching Notes

Seurat uses a graph-based Louvain (or Leiden) community detection algorithm. Resolution is the key tuning parameter:

| Resolution | Effect |
|---|---|
| 0.1–0.3 | Few large clusters — good for broad cell type overview |
| 0.5 (workshop default) | Moderate — 12 clusters for this dataset, appropriate granularity |
| 1.0–2.0 | Many small clusters — may over-split biologically similar states |

For this 1,700-cell dataset, resolution 0.5 yields 12 clusters, which maps cleanly to expected PBMC populations.

---

### Exercise 2.2 — Answer Key: Cluster Annotation

**Canonical marker → cluster mapping:**

| Marker Gene | Where expressed (this dataset) | Cell Type |
|---|---|---|
| CD3D, CD3E, TRAC | Broadly across the large main UMAP body — clusters 0, 1, 2, 4, 5, 6, 9 | T cells (general) |
| IL7R, CCR7 | Clusters 0, 2 — overlapping with CD3D+ region | Naive / Central Memory CD4+ T cells |
| CD8A | Clusters 4, 5 — subset of CD3D+ cells | CD8+ Cytotoxic T cells |
| NKG7, GNLY | Cluster 3 — bottom of UMAP, isolated from T cell body | NK cells |
| MS4A1 | Clusters 7/11 — isolated at top of UMAP | B cells |
| LYZ | Cluster 10 / isolated top point — well separated | Classical Monocytes |
| LST1 | Overlapping with LYZ cluster | Non-classical Monocytes |

**Dominant Cell Type — Full Model Answer:**

> **Answer: T cells are the most abundant cell type.**
>
> **Evidence:**
> 1. **Cluster size:** Cluster 0 is the single largest cluster with 279 cells. Clusters 1, 2, 4, 5, 6, and 9 also contain CD3+ T cells. Collectively, T cell clusters account for the clear majority of the 1,700 retained cells.
> 2. **Marker genes for Cluster 0:** Top markers by logFC include LEF1 (key naive T cell transcription factor), FHIT (expressed in naive T cells), MAL (T cell differentiation marker), GIMAP7/GIMAP5 (T cell GTPases), LDHB (metabolically quiescent naive lymphocytes), and CD40LG (CD4+ T cell activation marker).
> 3. **Feature plots:** CD3D and CD3E show expression across a large region of the UMAP encompassing multiple clusters, confirming T cell identity across clusters 0, 1, 2, 5, 6, 9.
> 4. **Specific annotation for Cluster 0:** Naive CD4+ T cells — LEF1 and CCR7 co-expression marks naive/central memory CD4+ T cells; LDHB upregulation is consistent with metabolically quiescent naive T cells.
>
> **Biological context:** In healthy donor blood, T cells comprise approximately 60–70% of PBMCs, with CD4+ T cells being the dominant subset. This dataset is consistent with that expectation.

---

### Common Student Mistakes — Day 2

| Mistake | How to Address It |
|---|---|
| Interpreting UMAP distance as quantitative | Remind them: use marker genes and cluster composition to make biological claims, not visual distance on UMAP. |
| Confusing avg_log2FC with percent expressed | logFC = magnitude; pct.1 vs pct.2 = specificity. A gene can have high FC but only be in 10% of cells — that's not a great marker. |
| Calling Cluster 0 "monocytes" based on LYZ alone | LYZ appears at low levels in some T cell subsets. Always use multiple markers. Check the feature plot — where is the strong LYZ signal concentrated? |
| Not understanding what pct.2 means | pct.2 = fraction of all *other* cells expressing the gene. Low pct.2 + high pct.1 = very specific marker. Walk them through a concrete example using the marker table. |
| Confused that Cluster 0 top markers are ribosomal (RPS/RPL) | In `all_markers.csv`, ribosomal genes rank highest statistically in Cluster 0 because these cells are transcriptionally active. The biologically informative T cell markers are in `top_markers_cluster_0.csv` when sorted by logFC. Both files are useful for different purposes. |

---

## 4. Complete Answer Keys {#answers}

### Day 1 Discussion Questions

| Question | Model Answer |
|---|---|
| What biological information is lost in bulk RNA-seq? | Cell type identity, cell state heterogeneity, rare cell populations, and cell-to-cell variation. Bulk averages across all cells — Gene X might be high in T cells and low in B cells, but bulk shows only the average. |
| Would bulk RNA-seq distinguish T cells vs B cells? | No — unless cells are pre-sorted by FACS before sequencing. Bulk shows mixed expression of T and B cell markers, impossible to attribute to individual cell types. |
| What does high mitochondrial % indicate? | A dying or damaged cell. The cytoplasmic membrane is compromised, cytoplasmic RNA leaks out. What remains is enriched for mitochondrial transcripts, which are protected inside intact mitochondria. |
| What might very low gene counts indicate? | An empty droplet (ambient RNA only, no real cell captured), or a very small or quiescent cell. Below ~200 genes, the barcode likely does not represent a real cell. |
| What might very high gene counts indicate? | A doublet — two cells captured in the same droplet sharing one barcode. The expressed genes appear as the union of two cell types, inflating gene count. |
| What happens if we filter too aggressively? | Risk removing rare biology: rare cell types (plasmacytoid DCs, basophils, NK-T cells) may have legitimate low gene counts or slightly elevated mitochondrial content and could be filtered out. |

### Day 2 Discussion Questions

| Question | Model Answer |
|---|---|
| Why can't we cluster raw counts? | Differences in sequencing depth would dominate clustering. High-depth cells would cluster together simply because they have more counts — not because they are the same cell type. |
| What does each PC represent? | A linear combination of gene expression values that captures a direction of maximum variance across cells. PC1 might separate lymphoid from myeloid; PC2 might separate T from B cells. |
| How do we decide how many PCs to use? | Use the elbow plot — select PCs where standard deviation begins to plateau. Common practice: 10–30 PCs. Run sensitivity analysis (try 10, 20, 30) and compare cluster stability. |
| What does distance mean in UMAP? | Within a cluster, proximity = transcriptional similarity. Between clusters, distances are NOT quantitatively meaningful — UMAP is a non-linear projection that preserves local, not global structure. |
| What makes a good marker gene? | High avg_log2FC (strong effect size), high pct.1 (expressed in most cells in the cluster), low pct.2 (not widely expressed elsewhere), and significant p_val_adj. |
| How does resolution change clusters? | Higher resolution = more, smaller clusters. Lower = fewer, larger. No universally correct value — depends on the biological question and how granular you need to be. |

---

## 5. QC Plot Interpretation Guide (Instructor Detail) {#qc}

### What to Point Out on Each Plot

**nFeature_RNA violin (log scale)**
- Point out the two populations: the dense spike near 1 (empty droplets) and the main distribution of real cells around 2,000–4,000 genes
- Ask students to identify where they would draw the minimum cutoff on the plot before you show the filter code
- The log scale is important here — on a linear scale, the empty droplet spike dominates and the real cell distribution is invisible

**nCount_RNA violin (log scale)**
- Structurally similar to nFeature — same bimodal pattern
- Real cells should cluster above 1,000 UMIs; this PBMC dataset has most cells around 3,000–10,000

**percent.mt violin**
- Most of the distribution sits near 0–5%. The long upper tail (up to 100%) is the critical signal
- Cells at exactly 100% mt are almost certainly dead — all detectable RNA in that barcode is mitochondrial
- Ask students: "At what percent.mt would you start to worry? At what point is it definitely a dead cell?"

**nCount vs nFeature scatter**
- Should be a tight, upward-sloping diagonal
- Points far above the line (high genes per UMI) can indicate doublets
- Points below the line (many UMIs but few genes — e.g., high expression of a very small number of genes) can indicate ambient RNA or stressed cells
- Black dots in the plot are cells that fall outside the filter thresholds

**nCount vs percent.mt scatter**
- Classic inverse "hockey stick" pattern: as UMI count increases, percent.mt decreases
- Cells in the upper-left quadrant (low UMI, high MT) are dead — these are the cells we most urgently need to remove
- Cells with very high UMI but moderate MT (~20–40%) in the upper-right could be metabolically active monocytes — worth checking rather than blindly removing

---

## 6. Cell Type Annotation Reference {#annotation}

### Complete PBMC Marker Gene Reference

| Cell Type | Key Markers | Expression Pattern | Cluster in This Dataset |
|---|---|---|---|
| T cells (all) | CD3D, CD3E, TRAC, CD2 | Pan-T, broad expression | Clusters 0, 1, 2, 4, 5, 6, 9 |
| Naive CD4+ T cells | IL7R, CCR7, LEF1, SELL | High CCR7 distinguishes naive from effector | Cluster 0, 2 |
| Memory CD4+ T cells | IL7R, CCR7 (lower), S100A4 | Lower CCR7 than naive | Overlaps with cluster 2 |
| Activated CD4+ T cells | CD40LG, IL2RA (CD25) | Upregulated upon activation | Subset of cluster 0 |
| CD8+ Cytotoxic T cells | CD8A, CD8B, GZMK | Cytotoxic effectors | Clusters 4, 5 |
| Effector Memory CD8+ | GZMB, PRF1, NKG7 | High cytotoxic gene expression | Cluster 5 |
| NK cells | NKG7, GNLY, FCGR3A (CD16), NCAM1 (CD56) | No CD3; high cytotoxic genes | Cluster 3 |
| B cells | MS4A1 (CD20), CD79A, CD79B, CD19 | Clearly separated on UMAP | Clusters 7, 11 |
| Classical Monocytes | LYZ, S100A8, S100A9, CD14 | High LYZ and S100 proteins | Cluster 10 |
| Non-classical Monocytes | LYZ (lower), LST1, FCGR3A, MS4A7 | Lower LYZ, higher FCGR3A | Overlaps cluster 10 |
| Plasmacytoid DCs | IL3RA, GZMB, TCF4 | Rare; may not appear at res=0.5 | May be in cluster 8 or 10 |
| Conventional DCs | FCER1A, CLEC10A | Rare; high MHCII expression | Rare in this dataset |

### Notes on This Dataset's Cluster Assignments

Cluster 10 is isolated at the top of the UMAP and expresses LYZ strongly — this is the clearest monocyte cluster. Cluster 8 is a small, separate cluster that may represent a rare population (could be pDCs, NK-T cells, or transitional cells) — worth examining the full marker list.

Cluster 3 at the bottom of the UMAP shows strong NKG7 and GNLY with no CD3 expression — this is the NK cell cluster.

The top-left isolated points (clusters 7 and 11) show clear MS4A1 expression — B cells, as expected in PBMCs.

---

## 7. Troubleshooting Guide {#troubleshooting}

| Problem | Likely Cause | Solution |
|---|---|---|
| `Read10X_h5()` fails with "file not found" | Wrong path | Check path: `list.files("/home/prisnirath/singlecell/data/raw/")`. Confirm the H5 file is present and the path matches exactly (case-sensitive). |
| Seurat v5 warning about "layers" | Seurat v4 vs v5 syntax | Use `layer = "counts"` (not `slot = "counts"`). Seurat v5 restructured the data access API. |
| `RunUMAP()` error about `umap-learn` | Missing Python package | Run `pip install umap-learn` in terminal. Alternatively: `RunUMAP(pbmc, dims=1:30, umap.method="uwot")` — uwot is a pure R implementation. |
| `FindAllMarkers()` is very slow (>30 min) | Large dataset, many clusters | Pre-run and distribute results: `markers <- read.csv("results/all_markers.csv")`. For future reference, `presto::wilcoxauc()` is dramatically faster than Seurat's default Wilcoxon test. |
| UMAP looks like a blob with no structure | QC filtering issue, or PCA didn't run | Check `cells_post_filter` in `qc_filter_summary.csv` — should be 1,000+. Confirm `ScaleData()` and `RunPCA()` both ran without error. Check `Reductions(pbmc)` — should list "pca". |
| Cluster numbers differ from workshop key | Stochastic UMAP/clustering | Normal. Use `set.seed(42)` before `RunUMAP()` and `FindClusters()` for reproducibility. Cell type identities should be the same even if cluster numbers differ. |
| Memory error / R crashes on VM | Insufficient RAM for large matrix | Reduce PCA: `RunPCA(pbmc, npcs=30)`. Or load pre-computed object: `pbmc <- readRDS("results/pbmc_part1_clustered.rds")` |
| `FeaturePlot()` shows all grey for a gene | Gene name not found in object | Check: `"CD3D" %in% rownames(pbmc)`. Gene names are case-sensitive and use hyphens in some versions. Try: `grep("CD3D", rownames(pbmc), value=TRUE)` to find the exact name. |
| Extremely high cell counts after filtering | Student used lenient thresholds | This is a teaching moment — show them their UMAP with and without stricter filtering. Noisier input → noisier clusters. |
| `percent.mt` is all zero | Gene names don't start with "MT-" | Check: `grep("^MT-", rownames(pbmc), value=TRUE)`. If empty, gene names may use a different format (e.g., "mt-" lowercase for mouse data). |

---

## 8. Extension Exercises {#extensions}

### Extension 1: QC Threshold Sensitivity Analysis

Ask students to re-run filtering with different thresholds and compare the resulting UMAPs.

```r
# Save the pre-filter object first
pbmc_raw <- pbmc

# Lenient filtering
pbmc_lenient <- subset(pbmc_raw,
  subset = nFeature_RNA > 100 & percent.mt < 25)

# Strict filtering
pbmc_strict <- subset(pbmc_raw,
  subset = nFeature_RNA > 500 & nFeature_RNA < 2500 & percent.mt < 5)

# Run the full pipeline on each and compare UMAPs
```

**Questions to ask:** How many cells remain in each? Does the UMAP structure change? Do different clusters appear or disappear? What does this tell you about the sensitivity of your biological conclusions to QC choices?

---

### Extension 2: Doublet Detection

Introduce computational doublet detection. In a real analysis, this would follow QC.

```r
# Install if needed: install.packages("scDblFinder")
library(scDblFinder)

# Convert Seurat to SingleCellExperiment for scDblFinder
sce <- as.SingleCellExperiment(pbmc_raw)
sce <- scDblFinder(sce)
table(sce$scDblFinder.class)
```

**Questions:** Do computationally predicted doublets overlap with cells that have very high nFeature_RNA? What fraction of your "real" cells does scDblFinder flag? How does removing predicted doublets change your UMAP?

---

### Extension 3: Clustering Resolution Sweep

```r
set.seed(42)
for (res in c(0.1, 0.3, 0.5, 0.8, 1.2)) {
  pbmc <- FindClusters(pbmc, resolution = res)
  cat(sprintf("Resolution %.1f: %d clusters\n",
    res, length(unique(pbmc$seurat_clusters))))
}
```

**Questions:** At what resolution does a new biologically meaningful cluster first appear — e.g., when do NK cells split from other lymphocytes? Is there a "correct" resolution? How do you decide?

---

### Extension 4: Marker Gene Deep Dive

For Cluster 0's top 5 markers by logFC (LEF1, FHIT, MAL, GIMAP7, LDHB):

1. Look up each gene in the Human Protein Atlas (proteinatlas.org)
2. Record: which tissues it's expressed in, its known function, whether it's documented as a T cell marker
3. Check the T cell Wikipedia article or the ENCODE T cell expression data
4. Write one sentence per gene explaining why its presence in Cluster 0 supports or complicates the "naive CD4+ T cell" annotation

---

### Extension 5: Cell Type Proportion Estimation

```r
# From the annotated object
cell_type_labels <- c(
  "0" = "Naive CD4+ T", "1" = "CD4+ T", "2" = "Naive CD4+ T",
  "3" = "NK", "4" = "CD8+ T", "5" = "CD8+ T",
  "6" = "CD4+ T", "7" = "B cell", "8" = "Unknown",
  "9" = "CD4+ T", "10" = "Monocyte", "11" = "B cell"
)

pbmc$cell_type <- cell_type_labels[as.character(pbmc$seurat_clusters)]
prop.table(table(pbmc$cell_type))
```

**Questions:** How do your proportions compare to published PBMC composition data from the Human Cell Atlas? Are they consistent with expected healthy donor blood? What might explain deviations?

---

### Extension 6: Marker Gene Visualization Variety

Beyond FeaturePlot, explore other ways to visualize marker expression:

```r
# Violin plot per cluster
VlnPlot(pbmc, features = c("CD3D", "MS4A1", "LYZ"), pt.size = 0)

# Dot plot — compact multi-gene multi-cluster view
DotPlot(pbmc, features = c("CD3D","IL7R","CD8A","NKG7","MS4A1","LYZ")) +
  RotatedAxis()

# Heatmap of top 3 markers per cluster
top3 <- markers %>% group_by(cluster) %>% top_n(3, avg_log2FC)
DoHeatmap(pbmc, features = top3$gene)
```

**Questions:** Which visualization communicates specificity most clearly? When would you use DotPlot vs FeaturePlot vs VlnPlot?

---

## 9. Series Preview: Parts 2 & 3 {#preview}

### Part 2 (June 2026 — Festival of Genomics, 90 min)

Building on the clustered object from Part 1:

- Cell type annotation using reference datasets (SingleR, Azimuth)
- Differential expression between conditions (pseudo-bulk vs single-cell DE)
- Pathway enrichment analysis and gene set scoring (`AddModuleScore`)
- Introduction to trajectory analysis concepts
- Producing publication-quality figures with captions

**Deliverable:** a 3-slide "figure + story" mini-deck per participant or group.

**Logistics:** 4–5 Google Cloud VMs, same infrastructure as Part 1. Students will load `pbmc_part1_clustered.rds` as their starting point.

### Part 3 (Date TBD)

Machine learning applications in scRNA-seq:

- Dimensionality reduction with variational autoencoders (scVI)
- Cell type classification with supervised ML models
- Multi-sample integration
- Introduction to spatial transcriptomics

---

### Frequently Asked Instructor Questions

**"Should I use Seurat or Scanpy for Part 2?"**
The workshop series uses R/Seurat throughout for consistency. Seurat v5 and Python/Scanpy are conceptually equivalent; if participants request Python, the same workflow maps 1:1 using `scanpy.tl.rank_genes_groups()` for marker finding, `scanpy.pp.neighbors()` + `scanpy.tl.umap()` for embedding, etc.

**"A student wants to use their own data — is that okay?"**
For Parts 1 and 2, encourage it after the structured exercises. The QC thresholds and clustering parameters will need adjustment, but the pipeline is identical. Key difference: percent.mt pattern `"^MT-"` is human; for mouse data use `"^mt-"`.

**"How do I handle a student who rushes ahead and finishes early?"**
Direct them to Extension Exercises 1 through 6 above. Extension 3 (resolution sweep) and Extension 5 (proportion estimation) tend to generate the most discussion.

---

*Boston Women in Bioinformatics | Sponsored by Sprout Informatics | April 2026*
*Instructor manual — confidential, not for distribution*
