# From Counts to Cell Types
### A 2-Day Hands-On Introduction to Single-Cell RNA-Seq
**Boston Women in Bioinformatics (BWiB)** · Delivered via Zoom · April 2026
*Sponsored by Sprout Informatics*

---

## Team

**Hosted by Boston Women in Bioinformatics (BWiB)**
*Supporting accessible, hands-on bioinformatics education.*

| Name | Role |
|---|---|
| **Prisni Rath** | Course Developer & Instructor |
| **Liyang Dao** | Resource Planning |
| **Maryanne** | Facilitator |

Prisni is a translational genomics professional with 11+ years of experience in bioinformatics and precision medicine. → [linkedin.com/in/prisni-r/](https://linkedin.com/in/prisni-r/)

---

## Agenda: Day 1
*Understanding the data before interpreting it*

1. Workshop goals and central question
2. Bulk RNA-seq vs Single-cell RNA-seq
3. History and evolution of scRNA-seq
4. 10x Genomics experiment overview
5. Dataset introduction (PBMC 5k)
6. Environment setup (RStudio + GitHub)
7. Loading data into Seurat
8. Quality control — UMIs, genes, % mitochondrial
9. Filtering strategy and biological reasoning

> **Day 1 Outcome:** You will leave Day 1 with a clean, filtered dataset — and a question to think about overnight.
>
> 💭 *What does a "cluster" represent biologically?*

---

## Agenda: Day 2
*Turning numbers into biological insight*

1. Recap of QC decisions from Day 1
2. Normalization and why it matters
3. Identifying highly variable genes
4. PCA and dimensionality reduction
5. UMAP visualization
6. Clustering cells
7. Marker gene analysis
8. Identifying the most abundant cell type

> **Day 2 Outcome:** Confidently determine the dominant cell type in the PBMC dataset — and justify your reasoning with data.

---

## Resources & Setup

**Code & Materials**
- GitHub: [github.com/Sprout-Informatics/sc-cellelementary](https://github.com/Sprout-Informatics/sc-cellelementary)
- PBMC 5k dataset — 10x Genomics
- Seurat docs: [satijalab.org/seurat](https://satijalab.org/seurat)
- 10x Genomics data portal

**Recommended Reading**
- Stuart et al., *Cell* (2019) — Seurat integration
- Luecken & Theis, *MSB* (2019) — Best practices
- 10x Genomics tutorials & experiment guides

**Compute Environment**
- RStudio (Cloud / VM)
- Google Cloud infrastructure
- R packages: Seurat, dplyr, ggplot2, patchwork

> 📋 **Optional Assignment:** Submit a short analysis summary (plots + interpretation) — registration fee waived upon submission.

---

## The Question Driving This Entire Workshop

> ## What is the most abundant cell type in this PBMC dataset?

Every step — QC, normalization, clustering, marker genes — is a tool to answer this question. By Day 2, you will answer it with data and justify your reasoning.

---

# DAY 1 — From Experiment to Clean Data
*QC · Filtering · Setting up for biological insight*

---

## Bulk RNA-seq vs Single-Cell RNA-seq

| | **A. Bulk RNA-seq** | **B. Single-Cell RNA-seq** |
|---|---|---|
| | Many cells pooled together | Individual cell expression profiles |
| | One averaged expression signal | Thousands of cells per experiment |
| | Cannot distinguish cell types | Identifies distinct cell populations |
| | Fast & cost-effective | Captures rare cell types & states |

**Discussion questions:**
- ❓ When would bulk still be appropriate?
- ❓ What biological information is lost in bulk RNA-seq?

---

## Why Single-Cell Matters
*Tissues are mixtures of cell types and states*

❓ If I give you blood — how many cell types are inside?

❓ Would bulk RNA-seq distinguish T cells vs B cells?

| Stat | Value |
|---|---|
| Distinct cell types in healthy blood | ~10 |
| Cells profiled in large scRNA-seq studies | >1 million |

scRNA-seq lets us resolve each cell type individually — impossible with bulk.

---

## Brief History of Single-Cell RNA-seq

| Year | Milestone |
|---|---|
| **2009** | First scRNA-seq data |
| **2013** | Plate-based, low throughput (tens–hundreds of cells) |
| **2015** | GTEx multi-tissue & multi-individual |
| **2017** | Droplet-based, high throughput (thousands–millions) |
| **2019** | Cell-type & cell-state specific eQTLs |
| **2026** | ← We are here |

---

## The 10x Genomics Experiment

**Flow:** Cell Suspension → Oil Droplets → Barcoded Beads → Sequencing → Count Matrix

| Term | Definition |
|---|---|
| **Barcode** | Unique DNA sequence — identifies which cell each RNA molecule came from |
| **UMI** | Unique Molecular Identifier — counts individual RNA molecules, not just reads |
| **Gene** | A measurable feature; one row in the count matrix |
| **Count matrix** | Genes × cells grid of UMI counts — the starting point for all analysis |

---

## The Dataset: PBMC 5k (10x Genomics)

| Metric | Value | Notes |
|---|---|---|
| Target cells | **5,000** | Peripheral blood mononuclear cells |
| Genes detected | **33,500+** | Full human transcriptome |
| Raw barcodes | **700k+** | Most are empty droplets — QC will filter |

**Expected Cell Types in Blood:**
T cells · B cells · NK cells · Monocytes · DCs · Platelets

❓ What cell types would you expect to dominate in blood? Why?

---

## Environment Setup

**1. GitHub Repo**
```
github.com/Sprout-Informatics/sc-cellelementary
Clone or download — all scripts and instructions inside.
```

**2. RStudio Setup**
```
Open RStudio on the provided Google Cloud VM
or configure your local environment using the README.
```

**3. Seurat Installation**
```r
install.packages("Seurat")
install.packages(c("ggplot2", "dplyr", "patchwork"))
```

**4. Project Structure**
```
data/
  └─ raw_feature_bc_matrix.h5
Rscript/
  └─ workshop.R
results/
```

---

## Step 1: Load Data into Seurat

```r
library(Seurat)
library(ggplot2)

# Load the raw 10x H5 file
pbmc.data <- Read10X_h5("raw_feature_bc_matrix.h5")

# Create the Seurat object
pbmc <- CreateSeuratObject(pbmc.data, project = "PBMC")
pbmc   # inspect it
```

| Question | Answer |
|---|---|
| ❓ How many genes? | ~33,500 features |
| ❓ How many barcodes? | ~700,000+ (most are empty) |
| ❓ What does one column represent? | One cell's expression profile |

---

## Step 2: Quality Control Metrics

| Metric | Description | Healthy | Flag |
|---|---|---|---|
| **nFeature_RNA** | Genes per cell | > 200 | < 200 (empty droplet) or > 4,000 (doublet) |
| **nCount_RNA** | UMIs per cell | Correlated with nFeature | Very low or very high |
| **percent.mt** | % mitochondrial reads | < 10–15% | > 20% (dying / damaged) |

**Key biology:**
- `nFeature_RNA` reflects whether a real cell was captured
- `nCount_RNA` measures total sequencing depth of the cell
- `percent.mt`: dying cells leak cytoplasmic RNA; MT RNA stays

```r
pbmc[["percent.mt"]] <- PercentageFeatureSet(pbmc, pattern = "^MT-")
```

**Discussion questions:**
- ❓ What does high mitochondrial % indicate?
- ❓ What might very low gene counts indicate?
- ❓ What could very high gene counts indicate?

---

## Step 3: Filtering Strategy

```r
min_genes <- 200
max_genes <- 3000
max_mito  <- 10

pbmc <- subset(pbmc,
  subset = nFeature_RNA > min_genes &
           nFeature_RNA < max_genes &
           percent.mt < max_mito)
```

| Threshold | Rationale |
|---|---|
| `min_genes = 200` | Removes empty droplets and debris |
| `max_genes = 3,000` | Removes likely doublets (two cells per droplet) |
| `max_mito = 10%` | Standard PBMC threshold — removes dying cells |

✅ **Result: 1,700 high-quality cells retained**

**Discussion questions:**
- ❓ What happens if we filter too aggressively?
- ❓ Could we accidentally remove a rare cell type?

---

## End of Day 1

- ✅ Clean, filtered Seurat object with 1,700 cells
- ✅ QC metrics computed and visualised
- ✅ Filtering thresholds chosen and justified

> 💭 **Overnight Question:** What does a cluster represent biologically?

---

# DAY 2 — From Clean Data to Cell Identity
*Normalization · UMAP · Clustering · Marker Genes*

---

## Day 2 Recap: What Did We Do Yesterday?

**Q: What is a gene × cell matrix?**
A: Rows = genes, columns = cells, values = UMI counts. Most entries are zero (sparse).

**Q: What defines a "good cell"?**
A: Sufficient genes (200–3k), low mitochondrial %, UMI count correlated with gene count.

**Q: Why do we need to normalize?**
A: Cells differ in sequencing depth. Raw counts are unfair to compare — normalization levels the field.

---

## Step 4: Normalization

```r
pbmc <- NormalizeData(pbmc)
# Scales to 10,000 UMIs per cell, then log1p transforms
```

| Without Normalization | After Normalization |
|---|---|
| High-depth cells dominate | All cells scaled to 10,000 UMIs |
| Cell 1: 2,000 UMIs → Gene X = 4 counts | Cell 1: Gene X → 20 (per 10k) |
| Cell 2: 10,000 UMIs → Gene X = 4 counts | Cell 2: Gene X → 4 (per 10k) |
| Looks the same — but it's not! | Now the difference is visible |

❓ Why can't we cluster raw counts directly?

---

## Step 5: Highly Variable Genes

```r
pbmc <- FindVariableFeatures(pbmc, selection.method = "vst", nfeatures = 2000)
```

- ❌ Most of ~33,000 genes are uninformative — equally expressed in all cell types (housekeeping genes)
- ✅ 2,000 genes with the highest cell-to-cell variation carry the most information about cell identity
- ⚡ Fewer dimensions → faster PCA, less noise, cleaner clusters

**VST Method:** Variance-stabilizing transformation corrects for the mean-variance relationship in count data. High-count genes have naturally higher variance — VST ensures selected genes are truly biologically variable, not just highly expressed.

❓ What signal are we trying to detect by selecting variable genes?

---

## Step 6: PCA & the Elbow Plot

```r
pbmc <- ScaleData(pbmc)          # Center + scale each gene
pbmc <- RunPCA(pbmc, npcs = 50)  # Compress 2,000 genes → 50 PCs
```

**Reading the Elbow Plot** (`pca_elbowplot.png`):
- Each PC captures a direction of maximum variance
- Left of elbow → biological signal
- Right of elbow → mostly noise
- This dataset: elbow ~PC 7–8; using `1:30` is conservative

**Discussion questions:**
- ❓ What does each PC represent?
- ❓ How do we choose how many PCs to keep?

---

## Step 7: UMAP Visualization

```r
pbmc <- RunUMAP(pbmc, dims = 1:30)
```

*See: `umap_clusters.png`*

| Principle | Detail |
|---|---|
| ✅ **Local structure preserved** | Nearby cells on UMAP = transcriptionally similar |
| ⚠️ **Global distances NOT meaningful** | Do not interpret cluster separation as quantitative distance |
| 🔀 **Stochastic** | Different seeds → different visual layouts; cluster identities stay stable |

❓ Does UMAP preserve global structure between clusters?

---

## Step 8: Clustering

```r
pbmc <- FindNeighbors(pbmc, dims = 1:30)
pbmc <- FindClusters(pbmc, resolution = 0.5)
```

**Effect of Resolution Parameter:**

| Resolution | Clusters | Best for |
|---|---|---|
| 0.1 – 0.3 | Few, large | Broad overview of major cell types |
| **0.5 ← workshop** | **12 clusters** | **Good balance for PBMC dataset** |
| 1.0 – 2.0 | Many, small | Fine-grained substates & rare pops |

**Cluster Cell Counts:**

| Cluster | Cells | Cluster | Cells |
|---|---|---|---|
| **0** ⭐ | **279** | 6 | 126 |
| 1 | 248 | 7 | 114 |
| 2 | 244 | 8 | 78 |
| 3 | 173 | 9 | 57 |
| 4 | 157 | 10 | 49 |
| 5 | 130 | 11 | 45 |

**Discussion questions:**
- ❓ What makes two cells 'similar'?
- ❓ How does resolution change the number of clusters?

---

## Step 9: Marker Gene Analysis

```r
markers <- FindAllMarkers(pbmc,
  only.pos = TRUE, min.pct = 0.25, logfc.threshold = 0.25)
```

**Understanding the Output Table:**

| Column | Meaning | What to look for |
|---|---|---|
| `avg_log2FC` | Log2 fold change vs all other cells | Higher = more cluster-specific |
| `pct.1` | Fraction in this cluster expressing the gene | High pct.1 = widely expressed in cluster |
| `pct.2` | Fraction in all other clusters expressing the gene | Low pct.2 = specific to this cluster |
| `p_val_adj` | Adjusted p-value | < 0.05 required; aim for much lower |

**Discussion questions:**
- ❓ What makes a good marker gene?
- ❓ What does a high `avg_log2FC` combined with low `pct.2` tell you?

---

## Step 10: Identify the Dominant Cell Type

**Canonical PBMC Marker Genes:**

| Cell Type | Key Markers |
|---|---|
| T cells (all) | CD3D, CD3E, TRAC |
| Naive CD4+ T cells | IL7R, CCR7, LEF1 |
| CD8+ T cells | CD8A, CD8B |
| NK cells | NKG7, GNLY |
| B cells | MS4A1, CD79A |
| Monocytes | LYZ, S100A8 |

**How to Identify the Winner:**
1. Find the largest cluster(s) by cell count
2. Check top markers by avg_log2FC
3. Visualize on UMAP with `FeaturePlot()`
4. Cross-reference canonical markers
5. Justify with cluster size + gene evidence

> **Cluster 0 is the largest (279 cells). LEF1, FHIT, MAL → Naive CD4+ T cells**

❓ Which cluster is largest? What markers does it express? Does this match expected PBMC biology?

---

## Now Answer the Question

> ## What is the most abundant cell type in your PBMC dataset?

Support your answer with:
- The largest cluster's cell count
- Top marker genes (avg_log2FC, pct.1, pct.2)
- Feature plots showing canonical gene expression

---

*Boston Women in Bioinformatics · Sponsored by Sprout Informatics · April 2026*
