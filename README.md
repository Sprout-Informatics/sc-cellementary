# Single-Cell Workshop Setup Guide

This guide walks you through setting up your computing environment for single-cell RNA-seq analysis. You will learn how to:

1. Start and manage your Google Cloud VM
2. Connect to your VM using Visual Studio Code (VSCode)
3. Install Seurat and related R packages

---

## Table of Contents

- [Part 1: Managing Your Google Cloud VM](#part-1-managing-your-google-cloud-vm)
- [Part 2: Connecting with Visual Studio Code](#part-2-connecting-with-visual-studio-code)
- [Part 3: Installing Seurat](#part-3-installing-seurat)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Prerequisites

Before starting, you should have:
- A Google Cloud account with an active project
- A VM instance already created (this guide uses `singlecell-vm` as an example)
- The `gcloud` CLI installed on your local machine
- Basic familiarity with the terminal/command line

---

## Part 1: Managing Your Google Cloud VM

Your VM (virtual machine) is a computer running in Google's cloud. You'll need to start it before you can use it, and stop it when you're done to avoid charges.

### Starting Your VM

Open a terminal on your local machine and run:

```bash
gcloud compute instances start singlecell-vm --zone us-west1-a
```

Wait for the confirmation message indicating the VM is running.

### Connecting to Your VM

Once the VM is running, connect via SSH:

```bash
gcloud compute ssh singlecell-vm --zone us-west1-a
```

You should see a prompt like `your_username@singlecell-vm:~$` indicating you're now working on the VM.

### Stopping Your VM

**Important:** Always stop your VM when you're done to avoid unnecessary charges.

If you have long-running jobs, first check if any `tmux` sessions are active:

```bash
tmux ls
```

If jobs are still running, either wait for them to complete or detach from tmux (the jobs will continue even after you disconnect).

When ready to stop:

```bash
gcloud compute instances stop singlecell-vm --zone us-west1-a
```

### Quick Reference

| Action | Command |
|--------|---------|
| Start VM | `gcloud compute instances start singlecell-vm --zone us-west1-a` |
| SSH into VM | `gcloud compute ssh singlecell-vm --zone us-west1-a` |
| Stop VM | `gcloud compute instances stop singlecell-vm --zone us-west1-a` |
| Configure SSH for VSCode | `gcloud compute config-ssh` |

---

## Part 2: Connecting with Visual Studio Code

Visual Studio Code (VSCode) is a powerful code editor that can connect directly to your remote VM, allowing you to edit files and run code as if you were working locally.

### Step 1: Install Visual Studio Code

Download and install VSCode for your operating system from the official website:

**[https://code.visualstudio.com/](https://code.visualstudio.com/)**

Follow the installation instructions for your platform:
- **Windows**: Run the downloaded `.exe` installer
- **macOS**: Drag the application to your Applications folder
- **Linux**: Follow the instructions for your distribution (`.deb` for Debian/Ubuntu, `.rpm` for Fedora/RHEL)

### Step 2: Install the Remote - SSH Extension

1. Open VSCode
2. Click the **Extensions** icon in the left sidebar (or press `Ctrl+Shift+X` on Windows/Linux, `Cmd+Shift+X` on macOS)
3. Search for **"Remote - SSH"**
4. Find the extension by **Microsoft** and click **Install**

![Remote SSH Extension](https://code.visualstudio.com/assets/docs/remote/ssh/remote-ssh-extension.png)

### Step 3: Configure SSH for Your VM

Before connecting from VSCode, you need to configure SSH access to your Google Cloud VM.

**On your local machine**, open a terminal and run:

```bash
gcloud compute config-ssh
```

This command automatically updates your `~/.ssh/config` file with entries for all your Google Cloud VMs. You should see output similar to:

```
You should now be able to use ssh/scp with your instances.
For example, try running:

  $ ssh singlecell-vm.us-west1-a.YOUR_PROJECT_ID
```

### Step 4: Connect to Your VM

1. **Open VSCode**
2. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS) to open the **Command Palette**
3. Type **"Remote-SSH: Connect to Host"** and select it
4. You'll see a list of available hosts. Select your VM (it will appear as something like `singlecell-vm.us-west1-a.YOUR_PROJECT_ID`)
5. A new VSCode window will open and begin connecting to your VM

The first connection may take a minute or two as VSCode automatically installs its server component on the remote machine.

### Step 5: Verify the Connection

Once connected, you'll know it worked when:

- The **bottom-left corner** of VSCode shows a green or blue indicator with "SSH: singlecell-vm..."
- Opening a terminal (`Ctrl+`` ` or **Terminal → New Terminal**) runs commands directly on the VM
- You can browse the VM's file system using **File → Open Folder**

### Step 6: Open Your Working Directory

1. Click **File → Open Folder** (or press `Ctrl+K Ctrl+O`)
2. Navigate to your home directory or project folder on the VM
3. Click **OK** to open the folder

VSCode will remember this location for quick access in future sessions.

### Step 7: Install R Support in VSCode (Recommended)

To get the best experience working with R code, install these extensions **while connected to your VM**:

1. Open the Extensions sidebar (`Ctrl+Shift+X`)
2. Search for and install:
   - **"R"** by REditorSupport — Provides R language support, syntax highlighting, and code completion
   - **"R Debugger"** by RDebugger — Enables debugging R scripts

When prompted, choose to install these extensions on the remote host (SSH: singlecell-vm).

### Tips for Working with VSCode Remote

- **Terminal access**: The integrated terminal runs directly on your VM—use it to run R scripts, install packages, or manage files
- **File editing**: Edit any file on the VM as if it were local
- **Extensions**: Some extensions need to be installed on the remote host. VSCode will prompt you when needed
- **Reconnecting**: Your recent connections appear at the top of the "Remote-SSH: Connect to Host" list for quick access
- **Disconnecting**: Close the VSCode window or click the green/blue indicator in the bottom-left and select "Close Remote Connection"

---

## Part 3: Installing Seurat

Seurat is the primary R package for single-cell RNA-seq analysis. These instructions assume you're connected to your VM via VSCode (see Part 2).

### Step 1: Install System Libraries

In the **VSCode terminal** (connected to your VM), install the libraries needed to compile Seurat's dependencies:

```bash
sudo apt update

sudo apt install -y \
    build-essential \
    gfortran \
    libopenblas-dev \
    liblapack-dev \
    libsuitesparse-dev \
    libglpk-dev
```

### Step 2: Start an R Session

Open a terminal in VSCode (`Ctrl+`` ` or **Terminal → New Terminal**) and start R:

```bash
R
```

This opens an interactive R session where you'll run the following installation commands.

### Step 3: Install the Matrix Package

Seurat requires a recent version of the Matrix package. In your **R session**, run:

```r
install.packages("remotes")
remotes::install_version("Matrix", version = "1.6-4", repos = "https://cloud.r-project.org")
```

Verify the installation:

```r
packageVersion("Matrix")
```

You should see `'1.6.4'` or higher. If version 1.6-4 fails, try:

```r
remotes::install_version("Matrix", version = "1.6-5", repos = "https://cloud.r-project.org")
```

### Step 4: Install Seurat

```r
install.packages("SeuratObject")
install.packages("Seurat")
```

Verify the installation:

```r
library(Seurat)
packageVersion("Seurat")
```

You should see version 5.x.x.

### Step 5: Install Recommended Packages (Optional)

These packages are commonly used alongside Seurat for data manipulation and visualization:

```r
install.packages(c(
    "tidyverse",
    "patchwork",
    "data.table",
    "cowplot"
))
```

### Step 6: Install SeuratData (Optional)

SeuratData provides example datasets for learning and testing:

```r
install.packages("remotes")
remotes::install_github("satijalab/seurat-data")
```

---

## Troubleshooting

### VSCode can't find the remote host
- Run `gcloud compute config-ssh` again to update your SSH configuration
- Verify your VM name and zone are correct
- Check that gcloud is authenticated: `gcloud auth login`

### VSCode connection fails or times out
- Verify the VM is running: `gcloud compute instances list`
- Try connecting via regular SSH first to confirm access: `gcloud compute ssh singlecell-vm --zone us-west1-a`
- Check your internet connection

### VSCode connected but terminal shows errors
- Close and reopen the terminal
- Try reconnecting: close the VSCode window and connect again
- Check VSCode's Output panel (View → Output) and select "Remote - SSH" for detailed logs

### Package installation fails
- Restart your R session (type `q()` then `R` to restart) and try again
- Check that all system libraries are installed (Step 1 in Part 3)

### SSH connection times out
- Verify the VM is running: `gcloud compute instances list`
- Check that you're using the correct zone

---

## Next Steps

Once your environment is set up, you're ready to start analyzing single-cell data. The typical Seurat workflow includes:

1. Loading your count matrix
2. Quality control and filtering
3. Normalization
4. Feature selection and dimensionality reduction
5. Clustering
6. Marker identification and annotation

Check out the [Seurat tutorials](https://satijalab.org/seurat/articles/get_started.html) for guided walkthroughs with example datasets.
