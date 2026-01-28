# Single-Cell Workshop Setup Guide

This guide walks you through setting up your computing environment for single-cell RNA-seq analysis. You will learn how to:

1. Start and manage your Google Cloud VM
2. Install RStudio Server on the VM
3. Install Seurat and related R packages

---

## Table of Contents

- [Part 1: Managing Your Google Cloud VM](#part-1-managing-your-google-cloud-vm)
- [Part 2: Installing RStudio Server](#part-2-installing-rstudio-server)
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
| Create SSH tunnel for RStudio | `gcloud compute ssh singlecell-vm --zone us-west1-a -- -N -L 8787:localhost:8787` |

---

## Part 2: Installing RStudio Server

RStudio Server lets you run RStudio in your web browser while the computation happens on your VM. Choose the instructions that match your VM's operating system.

### Determine Your Operating System

First, make sure you're connected to your VM (see Part 1), then check which OS you're running:

```bash
# For Debian
cat /etc/os-release

# For Ubuntu
lsb_release -a
```

---

### Option A: Debian (11 or 12)

#### Step 1: Install R and System Dependencies

Run the following commands to install R and the libraries needed to compile R packages:

```bash
sudo apt update

sudo apt install -y \
    r-base \
    gdebi-core \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev
```

Verify R installed correctly:

```bash
R --version
```

You should see R version 4.x.

#### Step 2: Download and Install RStudio Server

Download the appropriate RStudio Server installer from [Posit's download page](https://posit.co/download/rstudio-server/). Select the version matching your Debian release (11 or 12).

After downloading, install with `gdebi`:

```bash
sudo gdebi -n rstudio-server-<version>-amd64.deb
```

#### Step 3: Start RStudio Server

Enable and start the RStudio Server service:

```bash
sudo systemctl enable --now rstudio-server
sudo systemctl status rstudio-server --no-pager
```

You should see `Active: active (running)` in the output. RStudio Server runs on port 8787.

#### Step 4: Set Your Linux Password

RStudio uses your Linux username and password to authenticate. Set a password for your user:

```bash
sudo passwd YOUR_USERNAME
```

Enter a password you'll remember—you'll use this to log into RStudio.

#### Step 5: Access RStudio via SSH Tunnel

This method is secure and doesn't require opening firewall ports.

**On your local machine** (not the VM), open a new terminal and run:

```bash
gcloud compute ssh singlecell-vm \
    --zone us-west1-a \
    -- -N -L 8787:localhost:8787
```

This creates a secure tunnel that forwards the VM's port 8787 to your local machine. The `-N` flag means "don't open a shell, just create the tunnel." **Keep this terminal window open.**

Now open your web browser and go to:

```
http://localhost:8787
```

Log in with your Linux username and the password you set in Step 4.

---

### Option B: Ubuntu (22.04 or later)

#### Step 1: Install R and System Dependencies

```bash
sudo apt update
sudo apt install -y r-base gdebi-core
```

#### Step 2: Download and Install RStudio Server

```bash
cd /tmp
wget -O rstudio-server.deb \
    https://rstudio.org/download/latest/stable/server/jammy/rstudio-server-latest-amd64.deb

sudo gdebi -n rstudio-server.deb
```

#### Step 3: Start RStudio Server

```bash
sudo systemctl enable --now rstudio-server
sudo systemctl status rstudio-server --no-pager
```

You should see `Active: active (running)`.

#### Step 4: Set Your Linux Password

```bash
sudo passwd YOUR_USERNAME
```

#### Step 5: Access RStudio

**Option 1: SSH Tunnel (Recommended)**

On your local machine:

```bash
gcloud compute ssh singlecell-vm \
    --zone us-west1-a \
    -- -N -L 8787:localhost:8787
```

Keep this terminal open, then visit `http://localhost:8787` in your browser.

**Option 2: Direct Access via External IP**

If you prefer direct access, you'll need to open a firewall port. On your local machine:

```bash
# Create firewall rule (replace YOUR_PUBLIC_IP with your actual IP)
gcloud compute firewall-rules create allow-rstudio-8787 \
    --allow tcp:8787 \
    --target-tags rstudio \
    --source-ranges YOUR_PUBLIC_IP/32

# Add the tag to your VM
gcloud compute instances add-tags singlecell-vm \
    --tags rstudio \
    --zone us-west1-a
```

Get your VM's external IP:

```bash
# From the VM
curl -s ifconfig.me
```

Then visit `http://VM_EXTERNAL_IP:8787` in your browser.

---

## Part 3: Installing Seurat

Seurat is the primary R package for single-cell RNA-seq analysis. These instructions assume you have RStudio running (see Part 2).

### Step 1: Install System Libraries

In the **VM terminal** (via SSH, not the RStudio console), install the libraries needed to compile Seurat's dependencies:

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

### Step 2: Restart Your R Session

In RStudio, go to **Session → Restart R**. This ensures no outdated packages are loaded in memory.

### Step 3: Install the Matrix Package

Seurat requires a recent version of the Matrix package. In the **RStudio Console**, run:

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

### RStudio won't start
- Check the service status: `sudo systemctl status rstudio-server`
- View logs: `sudo journalctl -u rstudio-server`

### Can't connect to RStudio in browser
- Make sure your SSH tunnel is running (you should see the terminal "hanging" with no prompt)
- Verify you're visiting `http://localhost:8787` (not https)

### Package installation fails
- Restart your R session and try again
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
