# From Counts to Cell Types

**Single-Cell RNA-Seq Workshop**
Boston Women in Bioinformatics | Sponsored by Sprout Informatics | April 2026

A 2-day hands-on introduction to single-cell RNA-seq analysis using Seurat on Google Cloud.

---

## Repository Structure

```
sc-cellementary/
├── README.md
├── markdowns/                          # Student-facing resources (start here)
│   ├── student_manual_intro.md         # Workshop overview and R command reference
│   ├── student_manual_day_1.md         # Day 1 tutorial: QC and preprocessing
│   ├── student_manual_day_2.md         # Day 2 tutorial: normalization to cell types
│   ├── 01-google-cloud-vm-setup.md     # Setup guide: creating your Google Cloud VM
│   ├── 02-ssh-vscode-connection.md     # Setup guide: SSH and VSCode connection
│   └── scrnaseq_workshop_slides.md     # Workshop slide deck (markdown version)
├── resources/                          # Supplementary files
│   ├── student_manual.docx             # Student manual (Word format)
│   ├── scrnaseq_workshop.pptx          # Workshop slides (PowerPoint)
│   ├── workshop_workflows.html         # Visual workflow diagrams
│   └── scRNA-seq Workshop Workflows.pdf
├── instructor_resources/               # Instructor-only materials (not for students)
│   ├── instructor_manual.md            # Teaching guide with timing, discussion notes, answer keys
│   └── instructor_manual.docx          # Instructor manual (Word format)
└── Rscript/
    └── workshop.R                      # Complete R script for the workshop analysis
```

---

## Student Resources

All student-facing materials live in the [markdowns/](markdowns/) directory. Work through them in this order:

### Setup (before the workshop)

| Guide | Description |
|-------|-------------|
| [01 - Google Cloud VM Setup](markdowns/01-google-cloud-vm-setup.md) | Create and configure your virtual machine on Google Cloud |
| [02 - SSH & VSCode Connection](markdowns/02-ssh-vscode-connection.md) | Set up SSH access and connect using Visual Studio Code |

### Workshop Materials

| File | Description |
|------|-------------|
| [Student Manual — Intro](markdowns/student_manual_intro.md) | Workshop overview, dataset description, and R command quick-reference |
| [Student Manual — Day 1](markdowns/student_manual_day_1.md) | Load count data, compute QC metrics (nFeature, nCount, percent.mt), and filter low-quality cells |
| [Student Manual — Day 2](markdowns/student_manual_day_2.md) | Normalize data, run PCA/UMAP, cluster cells, find marker genes, and assign cell type identities |
| [Workshop Slides](markdowns/scrnaseq_workshop_slides.md) | Slide content covering concepts across both days |

---

## Quick Links

- [Seurat Documentation](https://satijalab.org/seurat/)
- [10x Genomics Datasets](https://www.10xgenomics.com/datasets)
- [Google Cloud Console](https://console.cloud.google.com)

---

## Getting Help

If you encounter issues during the workshop, reach out to the instructors or check the troubleshooting sections within each guide.

## Give Back!

If you found the materials here helpful, please consider donating to the [Boston Women in Bioinformatics](https://givebutter.com/BWIBdonate) to support continued community initiatives such as this one!
