# From Counts to Cell Types

## Single-Cell RNA-Seq Workshop — Student Manual

**Boston Women in Bioinformatics | Sponsored by Sprout Informatics**

April 2026 | 2-Day Hands-On Workshop

## Workshop Overview

Everything we do across both days answers one of three guiding questions:

| Question | Analysis Step |
|---|---|
| Is this a real cell? What could give us clues otherwise? | Quality control (UMIs, genes, % mitochondrial) |
| Can we compare cells fairly? | Normalization and scaling |
| Which cells are most similar? | PCA, UMAP, and clustering |

**Dataset:** PBMC 5k from 10x Genomics (GEM-X Multiplex, 3' v3) — peripheral blood mononuclear cells from a healthy donor, containing T cells, B cells, NK cells, monocytes, and more.

**Software:** R, Seurat v5, ggplot2, [VS Code](https://code.visualstudio.com/download)

**GitHub:** https://github.com/Sprout-Informatics/sc-cellelementary

**Seurat docs:** https://satijalab.org/seurat/

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


*Boston Women in Bioinformatics | Sponsored by Sprout Informatics | April 2026*
