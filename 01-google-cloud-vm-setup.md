# Creating a Google Cloud VM for Single-Cell Analysis

This guide walks you through creating and configuring a virtual machine (VM) in Google Cloud for single-cell RNA-seq analysis. By the end, you'll have a cloud-based computing environment ready for Cell Ranger and Seurat.

> **Note:** Google Cloud offers $300 in free credits for first-time users, which is more than enough for this workshop.

---

## Prerequisites

- A Google account
- A web browser
- About 15-20 minutes

---

## Part 1: Create Your Google Cloud Project

### Step 1: Log In

Go to the Google Cloud Console: [https://console.cloud.google.com](https://console.cloud.google.com)

Sign in with your Google account.

### Step 2: Create a New Project

1. Click the **project dropdown** in the top left (next to "Google Cloud")
2. Click **NEW PROJECT**
3. Enter a project name: `scRNAseq-workshop`
4. Click **Create**

### Step 3: Enable Billing

If you haven't set up billing before, Google will prompt you to do so. Follow the prompts to:
- Start your free trial (no charge until you exceed $300 in credits)
- Add a payment method (required but won't be charged during the trial)

---

## Part 2: Enable Compute Engine

Before you can create a VM, you need to enable the Compute Engine API:

1. In the left sidebar, click **Compute Engine**
2. Click **Enable API**

This may take 1-2 minutes to complete.

---

## Part 3: Create the VM Instance

### Step 1: Navigate to VM Instances

1. In the left sidebar, go to **Compute Engine → VM Instances**
2. Click **CREATE INSTANCE**

### Step 2: Configure Your VM

Fill in the following settings:

#### Name
Enter: `scrnaseq-vm`

#### Region & Zone
Choose a region close to you for better performance:
- US West Coast: `us-west1`
- US Central: `us-central1`
- US East Coast: `us-east1`

Any zone within your chosen region is fine.

#### Machine Configuration

Expand the **Machine Type** section and configure:

| Setting | Value |
|---------|-------|
| Machine family | General Purpose |
| Series | N1 |
| Machine type | **n1-standard-4** (4 vCPUs, 15 GB RAM) |

> **Tip:** For larger datasets or faster processing, you can choose `n1-standard-8` instead.

#### Boot Disk

Click **CHANGE** and set:

| Setting | Value |
|---------|-------|
| Operating System | Ubuntu |
| Version | Ubuntu 22.04 LTS |
| Disk Size | **150 GB** |
| Disk Type | Standard persistent disk |

Click **Select** to confirm.

> **Why 150 GB?** Single-cell analysis requires space for reference genomes, raw data, and intermediate files. 150 GB provides comfortable headroom.

#### Firewall

Check both boxes:
- ✅ Allow HTTP traffic
- ✅ Allow HTTPS traffic

### Step 3: Create the VM

Scroll down and click **CREATE**.

Your VM will take 1-2 minutes to provision. When the green checkmark appears, your VM is ready.

---

## Part 4: Connect to Your VM

1. Go to **Compute Engine → VM Instances**
2. Find your VM in the list
3. Click the **SSH** button next to your VM name

A browser-based terminal window will open. You're now inside your cloud machine!

You should see a prompt like:
```
your_username@scrnaseq-vm:~$
```

---

## Part 5: Install Required Software

Now that you're connected to your VM, run these commands to set up your analysis environment.

### Step 1: Update the System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Essential Tools

```bash
sudo apt install -y build-essential git wget unzip curl
```

### Step 3: Install Python and R

```bash
sudo apt install -y python3 python3-pip python3-venv r-base
```

**NOTE:** If the R version <= 4.5, you will need to add a newer CRAN repository and re-install r-base. See install instructions here: https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html

### Step 4: Install Libraries for R Packages

These libraries are needed to compile R packages like Seurat:

```bash
sudo apt install -y libcurl4-openssl-dev libssl-dev libxml2-dev
```

Your VM is now ready for:
- Cell Ranger installation
- Reference genome downloads
- Seurat analysis

---

## Part 6: Validate Your Setup

Run these commands to confirm everything installed correctly:

```bash
# Check CPU configuration
lscpu

# Check disk space
df -h

# Check R version
R --version

# Check Python version
python3 --version
```

**Expected results:**
- ✅ CPU: 4 vCPUs (or 8 if you chose n1-standard-8)
- ✅ Disk: ~150 GB total
- ✅ R: version 4.x
- ✅ Python: version 3.x

---

## VM Size Reference

Choose your VM size based on your dataset:

| Dataset Size | VM Type | Specs | Use Case |
|--------------|---------|-------|----------|
| PBMC 3k (practice) | n1-standard-4 | 4 vCPUs, 15 GB RAM | Fast, cost-effective for learning |
| Medium datasets (≤10k cells) | n1-standard-8 | 8 vCPUs, 30 GB RAM | Faster Cell Ranger runs |
| Large datasets (>20k cells) | n1-standard-16 | 16 vCPUs, 60 GB RAM | High memory for complex analyses |

---

## Managing Costs

**Important:** VMs cost money while they're running!

- **Stop your VM** when you're not using it: Go to VM Instances → click the three dots next to your VM → **Stop**
- **Start it again** when you need it: Same menu → **Start**
- Stopped VMs only incur minimal storage costs (~$7.50/month for 150 GB)

---

## Next Steps

Your VM is now configured and ready. Continue to the next guide:

1. **[02-ssh-vscode-connection.md](02-ssh-vscode-connection.md)** — Set up SSH access and connect with Visual Studio Code
2. Install Seurat and analysis packages (see [README.md](README.md))
3. Start the [single-cell QC walkthrough](03-scrna-seq-qc-walkthrough.md)
