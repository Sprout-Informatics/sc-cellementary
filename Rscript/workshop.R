# =========================
# Part 1: PBMC QC + clustering + dominant cell type (Seurat v5-safe)
# Input: 10x H5 raw_feature_bc_matrix.h5
# Output: /home/prisnirath/singlecell/results
# =========================

library(Seurat)
library(ggplot2)
library(Matrix)

# ---- Paths (your VM paths) ----
data_file <- "/home/prisnirath/singlecell/data/raw/5k_Human_Donor1_PBMC_3p_gem-x_Multiplex_count_raw_feature_bc_matrix.h5"
out_dir   <- "/home/prisnirath/singlecell/results"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ---- Load 10x matrix (raw counts) ----
pbmc.data <- Read10X_h5(data_file)
pbmc <- CreateSeuratObject(pbmc.data, project = "PBMC")
pbmc

# ---- QC metrics ----
pbmc[["percent.mt"]]   <- PercentageFeatureSet(pbmc, pattern = "^MT-")
pbmc[["percent.ribo"]] <- PercentageFeatureSet(pbmc, pattern = "^RPL|^RPS")

md <- pbmc@meta.data
md$cell <- rownames(md)

# ---- QC plots (ggplot: stable) ----
p1 <- ggplot(md, aes(x = "All cells", y = nFeature_RNA)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.12, outlier.size = 0.3) +
  labs(x = "", y = "Genes per cell (nFeature_RNA)", title = "QC: nFeature_RNA")

p2 <- ggplot(md, aes(x = "All cells", y = nCount_RNA)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.12, outlier.size = 0.3) +
  labs(x = "", y = "UMIs per cell (nCount_RNA)", title = "QC: nCount_RNA")

p3 <- ggplot(md, aes(x = "All cells", y = percent.mt)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.12, outlier.size = 0.3) +
  labs(x = "", y = "Percent mitochondrial (percent.mt)", title = "QC: percent.mt")

ggsave(file.path(out_dir, "qc_violin_nFeature_RNA.png"), p1, width = 6, height = 4, dpi = 150)
ggsave(file.path(out_dir, "qc_violin_nCount_RNA.png"),   p2, width = 6, height = 4, dpi = 150)
ggsave(file.path(out_dir, "qc_violin_percent_mt.png"),   p3, width = 6, height = 4, dpi = 150)

p4 <- ggplot(md, aes(x = nCount_RNA, y = nFeature_RNA)) +
  geom_point(size = 0.6, alpha = 0.35) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "UMIs per cell (log10)", y = "Genes per cell (log10)",
       title = "QC: nCount_RNA vs nFeature_RNA")

p5 <- ggplot(md, aes(x = nCount_RNA, y = percent.mt)) +
  geom_point(size = 0.6, alpha = 0.35) +
  scale_x_log10() +
  labs(x = "UMIs per cell (log10)", y = "Percent mitochondrial",
       title = "QC: nCount_RNA vs percent.mt")

ggsave(file.path(out_dir, "qc_scatter_counts_vs_genes.png"), p4, width = 6.5, height = 4.5, dpi = 150)
ggsave(file.path(out_dir, "qc_scatter_counts_vs_mito.png"),  p5, width = 6.5, height = 4.5, dpi = 150)

# Optional: feature-level distribution (gene totals)
counts <- GetAssayData(pbmc, assay = "RNA", layer = "counts")
gene_totals <- Matrix::rowSums(counts)
gene_df <- data.frame(gene_total_umi = as.numeric(gene_totals))

p6 <- ggplot(gene_df, aes(x = gene_total_umi)) +
  geom_histogram(bins = 50) +
  scale_x_log10() +
  labs(x = "Total UMI per gene (log10)", y = "Number of genes",
       title = "Feature-level QC: total counts per gene")

ggsave(file.path(out_dir, "qc_gene_total_counts_hist.png"), p6, width = 6.5, height = 4.5, dpi = 150)

# ---- Filter cells (conservative PBMC defaults) ----
# Since this is a RAW matrix, expect many barcodes that are not real cells.
# These thresholds are a starting point. Adjust based on your QC plots.
min_genes <- 200
max_genes <- 3000
max_mito  <- 10

pbmc <- subset(pbmc, subset = nFeature_RNA > min_genes &
                         nFeature_RNA < max_genes &
                         percent.mt < max_mito)

# Save a quick filtering summary
filter_summary <- data.frame(
  metric = c("min_genes", "max_genes", "max_mito", "cells_post_filter"),
  value  = c(min_genes, max_genes, max_mito, ncol(pbmc))
)
write.csv(filter_summary, file.path(out_dir, "qc_filter_summary.csv"), row.names = FALSE)

# ---- Normalize + variable genes ----
pbmc <- NormalizeData(pbmc)
pbmc <- FindVariableFeatures(pbmc, selection.method = "vst", nfeatures = 2000)

# ---- Scale + PCA ----
pbmc <- ScaleData(pbmc)
pbmc <- RunPCA(pbmc, npcs = 50, verbose = FALSE)

png(file.path(out_dir, "pca_elbowplot.png"), width = 900, height = 600)
ElbowPlot(pbmc, ndims = 50)
dev.off()

# ---- Neighbors + clustering + UMAP ----
dims_use <- 1:30
pbmc <- FindNeighbors(pbmc, dims = dims_use)
pbmc <- FindClusters(pbmc, resolution = 0.5)
pbmc <- RunUMAP(pbmc, dims = dims_use)

p_umap <- DimPlot(pbmc, reduction = "umap", label = TRUE) + NoLegend()
ggsave(file.path(out_dir, "umap_clusters.png"), p_umap, width = 7, height = 5, dpi = 150)

# ---- Identify the most abundant cluster ----
cluster_counts <- sort(table(pbmc$seurat_clusters), decreasing = TRUE)
write.csv(as.data.frame(cluster_counts),
          file.path(out_dir, "cluster_cell_counts.csv"),
          row.names = FALSE)

largest_cluster <- names(cluster_counts)[1]

# ---- Find markers and infer dominant cell type ----
markers <- FindAllMarkers(pbmc, only.pos = TRUE, min.pct = 0.25, logfc.threshold = 0.25)
write.csv(markers, file.path(out_dir, "all_markers.csv"), row.names = FALSE)

top_markers_largest <- subset(markers, cluster == largest_cluster)
top_markers_largest <- top_markers_largest[order(-top_markers_largest$avg_log2FC), ]
write.csv(head(top_markers_largest, 30),
          file.path(out_dir, paste0("top_markers_cluster_", largest_cluster, ".csv")),
          row.names = FALSE)

cat("\nMost abundant cluster:", largest_cluster, "\n")
cat("Cells per cluster:\n")
print(cluster_counts)
cat("\nTop markers for most abundant cluster:\n")
print(head(top_markers_largest[, c("gene","avg_log2FC","pct.1","pct.2","p_val_adj")], 10))

# ---- Optional: visualize canonical markers on UMAP ----
canonical <- c("CD3D","CD3E","TRAC","IL7R","CCR7","CD8A","NKG7","GNLY","MS4A1","LYZ","LST1")
canonical <- canonical[canonical %in% rownames(pbmc)]

if (length(canonical) > 0) {
  png(file.path(out_dir, "umap_canonical_markers.png"), width = 1400, height = 900)
  print(FeaturePlot(pbmc, features = canonical, ncol = 4))
  dev.off()
}

# ---- Save object for Part 2 ----
saveRDS(pbmc, file.path(out_dir, "pbmc_part1_clustered.rds"))

cat("\nDone. Outputs saved to:", out_dir, "\n")

