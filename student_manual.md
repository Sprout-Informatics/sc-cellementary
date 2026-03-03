# From Counts to Cell Types
## Single-Cell RNA-Seq Workshop — Student Manual
**Boston Women in Bioinformatics | Sponsored by Sprout Informatics**
April 2026 | 2-Day Hands-On Workshop

---

## The Central Question

> **What is the most abundant cell type in a PBMC dataset?**
> By the end of this workshop you will answer this question with data, plots, and marker gene evidence — and explain exactly how you know.

---

## Workshop Overview

Everything we do across both days answers one of three guiding questions:

| Question | Analysis Step |
|---|---|
| Is this a real, healthy cell? | Quality control (UMIs, genes, % mitochondrial) |
| Can we compare cells fairly? | Normalization and scaling |
| Which cells are most similar? | PCA, UMAP, and clustering |

**Dataset:** PBMC 5k from 10x Genomics (GEM-X Multiplex, 3' v3) — peripheral blood mononuclear cells from a healthy donor, containing T cells, B cells, NK cells, monocytes, and more.

**Software:** R, RStudio, Seurat v5, ggplot2
**GitHub:** https://github.com/Sprout-Informatics/sc-cellelementary
**Seurat docs:** https://satijalab.org/seurat/

---

# Day 1: From Raw Counts to Clean Data

## Learning Objectives

By the end of Day 1 you will be able to:

1. Open and inspect a real 10x single-cell count matrix in Seurat
2. Compute and visualize three core QC metrics (nFeature_RNA, nCount_RNA, percent.mt)
3. Apply biologically motivated filtering thresholds to remove low-quality barcodes
4. Explain what each QC metric tells you about cell quality

---

## Background: Bulk vs Single-Cell RNA-Seq

In **bulk RNA-seq**, RNA from thousands of cells is pooled together. The result is a single averaged signal — you cannot tell which gene came from which cell type.

In **scRNA-seq**, each cell gets its own barcode, producing thousands of individual expression profiles from a single experiment. This lets you distinguish T cells from B cells, find rare populations, and study cell-to-cell variation.

> **Discussion:** What biological information is lost in bulk RNA-seq? Would bulk RNA-seq distinguish T cells from B cells in blood? Why or why not?

---

## The 10x Genomics Experiment

Cells are captured in oil droplets with barcoded beads. Each droplet ideally contains one cell. The bead **barcode** labels all RNA molecules from that cell, and a **UMI** (Unique Molecular Identifier) labels each individual transcript. After sequencing, reads are assigned back to barcodes, producing a **gene × cell count matrix**.

| Term | Meaning |
|---|---|
| Barcode | Unique DNA sequence identifying one cell |
| UMI | Unique Molecular Identifier — counts individual transcript molecules (not reads) |
| Count matrix | Grid of genes (rows) × cells (columns) filled with UMI counts |
| nFeature_RNA | Number of distinct genes detected in a cell |
| nCount_RNA | Total UMI count in a cell (sequencing depth) |
| percent.mt | Fraction of UMIs from mitochondrial genes |

---

## Step 1: Load Data into Seurat

```r
library(Seurat)
library(ggplot2)
library(Matrix)

# Load the raw 10x H5 file
pbmc.data <- Read10X_h5("path/to/raw_feature_bc_matrix.h5")

# Create a Seurat object
pbmc <- CreateSeuratObject(pbmc.data, project = "PBMC")

# Inspect the object
pbmc
```

> **Exercise 1.1:** After running `pbmc`, record:
> - How many genes (features) are in the object?
> - How many barcodes (cells) are loaded?
> - What does one column of the count matrix represent?

---

## Step 2: Compute QC Metrics

```r
# Mitochondrial gene percentage
pbmc[["percent.mt"]] <- PercentageFeatureSet(pbmc, pattern = "^MT-")

# Ribosomal gene percentage (optional but informative)
pbmc[["percent.ribo"]] <- PercentageFeatureSet(pbmc, pattern = "^RPL|^RPS")
```

---

## Step 3: Visualize QC Metrics

Run the plotting code in `workshop.R` to generate violin plots and scatter plots. Your output files will be:
- `qc_violin_nFeature_RNA.png`
- `qc_violin_nCount_RNA.png`
- `qc_violin_percent_mt.png`
- `qc_scatter_counts_vs_genes.png`
- `qc_scatter_counts_vs_mito.png`

### QC Plot Interpretation Guide

Use this table when examining your plots:

| What you see | What it likely means |
|---|---|
| nFeature_RNA peak near 0 | Empty droplets — no real cell captured |
| nFeature_RNA > 5,000 | Potential doublet (two cells in one droplet) |
| percent.mt > 20% | Dying or damaged cells — cytoplasm has leaked |
| Tight diagonal in count vs gene scatter | Good quality — UMIs and genes are correlated as expected |
| Points far above the diagonal | Possible doublets or unusual cell states |
| Very low UMI + high percent.mt | Dead cells — remove these |
| Bimodal nCount_RNA distribution | Mix of real cells and ambient RNA in empty droplets |

### Typical PBMC Values

| Metric | Real Cells (typical) | Filter Out |
|---|---|---|
| nFeature_RNA | 500–4,000 genes | < 200 (empty) or > 5,000 (doublet) |
| nCount_RNA | 1,000–30,000 UMIs | Correlated with nFeature |
| percent.mt | < 10–15% | > 10–20% (dying) |

> **Exercise 1.2 — Interpret your QC plots:**
> 1. What percent.mt threshold would you choose, and why?
> 2. Do you see a clear separation between real cells and empty droplets in nCount_RNA?
> 3. What would happen if you set `min_genes = 100` instead of 200?

---

## Step 4: Filter Low-Quality Cells

```r
# Set thresholds
min_genes <- 200
max_genes <- 3000
max_mito  <- 10

pbmc <- subset(pbmc,
  subset = nFeature_RNA > min_genes &
           nFeature_RNA < max_genes &
           percent.mt < max_mito)
```

After filtering, this dataset retains **1,700 high-quality cells**.

> **Think about it:**
> - Why do we set both a minimum AND a maximum gene threshold?
> - What happens if we filter too aggressively — could we accidentally remove a rare cell type?

---

## Day 1 Summary

By the end of Day 1 you should have:

- ✅ A Seurat object loaded from raw 10x data
- ✅ QC metrics computed and plotted
- ✅ A filtered, clean dataset with 1,700 cells

**Overnight question:** What do you think a "cluster" of cells represents biologically?

---

# Day 2: From Clean Data to Cell Identity

## Learning Objectives

By the end of Day 2 you will be able to:

1. Normalize expression data and explain why it is necessary
2. Identify highly variable genes and understand their role in dimensionality reduction
3. Read an elbow plot and select an appropriate number of PCs
4. Interpret a UMAP: what proximity means and what it does not
5. Use marker gene output to assign cell type identities to clusters
6. Identify and justify the most abundant cell type in the dataset

---

## Step 5: Normalize Expression

Cells are sequenced to different depths — one cell might have 3,000 UMIs while another has 10,000. Raw counts cannot be directly compared. `NormalizeData` scales each cell to a common total (default: 10,000 UMIs), then log-transforms the result.

```r
pbmc <- NormalizeData(pbmc)
```

> **Why log-transform?** Gene expression is highly skewed — a few genes are expressed thousands of times while most genes have near-zero counts. Log transformation compresses extreme values and makes the distribution more symmetric, improving downstream statistics.

---

## Step 6: Identify Highly Variable Genes

Not all genes are useful for distinguishing cell types. We select the 2,000 genes with the most variation across cells — these carry the most information about cell identity.

```r
pbmc <- FindVariableFeatures(pbmc,
  selection.method = "vst",
  nfeatures = 2000)
```

> **Discussion:** Why not use all ~33,000 genes? Most genes are either not expressed or equally expressed across all cell types. Including them adds noise without adding signal and dramatically slows computation.

---

## Step 7: Scale Data and Run PCA

Scaling centers each gene to mean 0 and standard deviation 1, so highly expressed genes don't dominate PCA. PCA then compresses 2,000 variable genes into a smaller set of principal components (PCs).

```r
pbmc <- ScaleData(pbmc)
pbmc <- RunPCA(pbmc, npcs = 50, verbose = FALSE)
```

### Reading the Elbow Plot

```r
ElbowPlot(pbmc, ndims = 50)
```

The elbow plot shows standard deviation explained by each PC. Look for the "elbow" — the point where the curve flattens. PCs to the left of the elbow capture meaningful biological variation; PCs to the right mostly capture noise.

> **Exercise 2.1:** Look at `pca_elbowplot.png`.
> - Where does the curve begin to flatten?
> - How many PCs would you use for downstream analysis?
> - The workshop uses `dims 1:30` — does this seem reasonable?

---

## Step 8: Cluster Cells

We first build a shared nearest-neighbor graph connecting cells with similar expression profiles, then group tightly connected cells into clusters. The `resolution` parameter controls granularity — higher values create more (smaller) clusters.

```r
dims_use <- 1:30
pbmc <- FindNeighbors(pbmc, dims = dims_use)
pbmc <- FindClusters(pbmc, resolution = 0.5)
```

---

## Step 9: UMAP Visualization

UMAP projects high-dimensional PCA space into 2D for visualization. Cells that are transcriptionally similar end up near each other.

```r
pbmc <- RunUMAP(pbmc, dims = dims_use)
DimPlot(pbmc, reduction = "umap", label = TRUE) + NoLegend()
```

> **Important:** Distances between distant clusters on UMAP are **not** quantitatively meaningful. UMAP preserves local structure (nearby cells are similar), not global distances (don't interpret cluster separation as a measure of biological difference).

### Cluster Cell Counts (this dataset)

| Cluster | Cells |
|---|---|
| 0 | 279 ← largest |
| 1 | 248 |
| 2 | 244 |
| 3 | 173 |
| 4 | 157 |
| 5 | 130 |
| 6 | 126 |
| 7 | 114 |
| 8 | 78 |
| 9 | 57 |
| 10 | 49 |
| 11 | 45 |

---

## Step 10: Find Marker Genes

`FindAllMarkers` tests every gene in each cluster against all other cells, identifying genes significantly more expressed in that cluster.

```r
markers <- FindAllMarkers(pbmc,
  only.pos = TRUE,
  min.pct = 0.25,
  logfc.threshold = 0.25)

write.csv(markers, "results/all_markers.csv", row.names = FALSE)
```

### Understanding the Marker Table

| Column | Meaning |
|---|---|
| gene | Gene name |
| avg_log2FC | Log2 fold change vs all other clusters — higher = more cluster-specific |
| pct.1 | Fraction of cells in **this** cluster expressing the gene |
| pct.2 | Fraction of **all other** cells expressing the gene |
| p_val_adj | Adjusted p-value — statistical significance |

A **good marker gene** has: high avg_log2FC, high pct.1, low pct.2, and a significant p_val_adj.

---

## Step 11: Cell Type Annotation Reference Table

Use canonical marker genes to match clusters to known cell types. Check expression on the UMAP feature plot (`umap_canonical_markers.png`).

```r
canonical <- c("CD3D","CD3E","TRAC","IL7R","CCR7",
               "CD8A","NKG7","GNLY","MS4A1","LYZ","LST1")

FeaturePlot(pbmc, features = canonical, ncol = 4)
```

### Canonical PBMC Marker Genes

| Cell Type | Key Marker Genes | Notes |
|---|---|---|
| T cells (general) | CD3D, CD3E, TRAC | All T cells express the CD3 complex |
| Naive / Memory CD4+ T cells | IL7R, CCR7, LEF1 | CCR7 marks naive and central memory |
| CD8+ Cytotoxic T cells | CD8A, CD8B | Cytotoxic effector T cells |
| NK cells | NKG7, GNLY, FCGR3A | Natural killer cells — no CD3 |
| B cells | MS4A1 (CD20), CD79A | Clearly separated on UMAP |
| Classical Monocytes | LYZ, S100A8, S100A9 | High LYZ expression |
| Non-classical Monocytes | LYZ, LST1, FCGR3A | Lower LYZ, distinct cluster |
| Plasmacytoid DCs | IL3RA, GZMB | Rare, may not appear at this resolution |

> **Exercise 2.2 — Annotate your UMAP:**
> 1. Which clusters express CD3D / CD3E? What cell type are these?
> 2. Which cluster strongly expresses MS4A1? What does that tell you?
> 3. Which cluster has the highest LYZ expression?
> 4. Cluster 0 is the largest (279 cells). What markers does it express?
> 5. Based on all evidence, what is the most abundant cell type in this dataset?

---

## Cluster 0: Top Markers

The top markers by logFC for Cluster 0 (the largest cluster with 279 cells):

| Gene | avg_log2FC | Biological Significance |
|---|---|---|
| FHIT | 1.53 | Expressed in naive T cells |
| LEF1 | 1.28 | Key transcription factor for naive T cell identity |
| MAL | 1.95 | T cell differentiation marker |
| GIMAP7 / GIMAP5 | 1.66 / 1.65 | GTPases in T cell survival signaling |
| LDHB | 1.69 | Metabolic enzyme upregulated in naive lymphocytes |
| CD40LG | 1.50 | CD40 Ligand — expressed on activated CD4+ T cells |
| SCML1 | 1.57 | T cell marker |

> **Conclusion:** Cluster 0's marker genes (LEF1, FHIT, MAL, GIMAP7, CD40LG) point strongly to **naive CD4+ T cells**. Combined with broad CD3D/CD3E expression across the T cell region, T cells collectively represent the dominant population — consistent with known PBMC biology (~60–70% of PBMCs are T cells).

---

## Day 2 Summary

| Step | What & Why |
|---|---|
| Normalize | Corrected for differences in sequencing depth |
| Variable Genes | Selected the 2,000 most informative genes |
| PCA | Compressed 2,000 genes into ~30 meaningful dimensions |
| UMAP | Visualized clusters in 2D |
| Clustering | Grouped transcriptionally similar cells |
| Markers | Identified defining genes per cluster |
| Annotation | Matched clusters to known cell types |

---

## R Command Reference

| Command | What it does |
|---|---|
| `Read10X_h5(file)` | Load 10x H5 count matrix |
| `CreateSeuratObject(data)` | Create Seurat object |
| `PercentageFeatureSet(pbmc, pattern)` | Compute percent expression from gene name pattern |
| `subset(pbmc, subset = ...)` | Filter cells based on metadata thresholds |
| `NormalizeData(pbmc)` | Normalize to 10,000 UMIs/cell + log transform |
| `FindVariableFeatures(pbmc, nfeatures=2000)` | Select top 2,000 variable genes |
| `ScaleData(pbmc)` | Center and scale each gene across cells |
| `RunPCA(pbmc, npcs=50)` | Compute 50 principal components |
| `ElbowPlot(pbmc, ndims=50)` | Plot variance by PC for dimension selection |
| `FindNeighbors(pbmc, dims=1:30)` | Build cell-cell similarity graph |
| `FindClusters(pbmc, resolution=0.5)` | Cluster cells by community detection |
| `RunUMAP(pbmc, dims=1:30)` | Compute 2D UMAP embedding |
| `DimPlot(pbmc, label=TRUE)` | Plot UMAP with cluster labels |
| `FindAllMarkers(pbmc, only.pos=TRUE)` | Find marker genes for all clusters |
| `FeaturePlot(pbmc, features=...)` | Plot gene expression on UMAP |
| `saveRDS(pbmc, file)` | Save Seurat object for Part 2 |

---

## Optional Assignment

Submit a short analysis summary for a waived registration fee. Your submission should include:

1. QC violin plots with your chosen thresholds and written reasoning
2. Your UMAP plot colored by cluster
3. A feature plot showing 2–3 key marker genes
4. A short paragraph (~150 words) identifying the dominant cell type and justifying your answer with marker gene evidence

Submit via the workshop GitHub repository as a PDF or HTML report.

---

*Boston Women in Bioinformatics | Sponsored by Sprout Informatics | April 2026*
