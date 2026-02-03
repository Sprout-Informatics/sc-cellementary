# Setting Up SSH Access and Connecting with VSCode

This guide walks you through setting up SSH access to your Google Cloud VM and connecting using Visual Studio Code (VSCode). By the end, you'll be able to edit code and run commands on your VM directly from your local machine.

> **Prerequisite:** Complete [01-google-cloud-vm-setup.md](01-google-cloud-vm-setup.md) first. You should have a running VM before proceeding.

---

## Prerequisites

- A Google Cloud VM already created (from the previous guide)
- A local computer (Windows, macOS, or Linux)
- About 15-20 minutes

---

## Part 1: Install the Google Cloud CLI

The `gcloud` command-line tool lets you manage your VMs and configure SSH access from your local terminal.

### Step 1: Download and Install

**macOS:**

Open Terminal and run:

```bash
# Install via Homebrew (recommended)
brew install --cask google-cloud-sdk
```

Or download from: [https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

**Windows:**

1. Download the installer from: [https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)
2. Run the downloaded `.exe` file
3. Follow the installation wizard
4. When prompted, check the box to add gcloud to your PATH

**Linux (Debian/Ubuntu):**

```bash
# Add the Cloud SDK distribution URI as a package source
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Install the Cloud SDK
sudo apt update && sudo apt install -y google-cloud-cli
```

### Step 2: Initialize the CLI

After installation, initialize gcloud:

```bash
gcloud init
```

Follow the prompts to:
1. Log in to your Google account (a browser window will open)
2. Select your project (`scRNAseq-workshop` or whatever you named it)
3. Set a default region/zone (choose the same one as your VM)

### Step 3: Verify Installation

```bash
gcloud --version
```

You should see version information for the Google Cloud SDK.

---

## Part 2: Generate an SSH Key Pair

SSH keys allow secure, password-free connections to your VM. You'll create a key pair: a private key (stays on your computer) and a public key (goes on the VM).

### Step 1: Check for Existing Keys

First, check if you already have SSH keys:

```bash
ls -la ~/.ssh/
```

If you see files named `id_rsa` and `id_rsa.pub` (or `id_ed25519` and `id_ed25519.pub`), you may already have keys. You can use existing keys or create new ones.

### Step 2: Generate a New Key Pair

We recommend using the Ed25519 algorithm for better security:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

When prompted:

| Prompt | What to Enter |
|--------|---------------|
| File location | Press **Enter** to accept the default (`~/.ssh/id_ed25519`) |
| Passphrase | Enter a strong passphrase (recommended) or press **Enter** for none |
| Confirm passphrase | Re-enter your passphrase |

> **Tip:** A passphrase adds an extra layer of security. You'll enter it the first time you connect each session.

**Alternative: RSA keys** (if Ed25519 isn't supported):

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### Step 3: Verify Your Keys Were Created

```bash
ls -la ~/.ssh/
```

You should see:
- `id_ed25519` — Your private key (keep this secret!)
- `id_ed25519.pub` — Your public key (this gets shared)

### Step 4: View Your Public Key

Display your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

The output will look something like:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your_email@example.com
```

Keep this terminal open—you'll need this key in the next step.

---

## Part 3: Add Your SSH Key to Google Cloud

Google Cloud needs your public key to allow SSH connections to your VMs.

### Option A: Using gcloud (Recommended)

The easiest method is to let gcloud handle everything:

```bash
gcloud compute config-ssh
```

This command:
- Generates SSH keys if you don't have them
- Uploads your public key to your Google Cloud project
- Configures your `~/.ssh/config` file with entries for all your VMs

You should see output like:

```
You should now be able to use ssh/scp with your instances.
For example, try running:

  $ ssh scrnaseq-vm.us-west1-a.your-project-id
```

### Option B: Manual Upload via Console

If you prefer to add keys manually:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **Compute Engine → Metadata**
3. Click the **SSH Keys** tab
4. Click **ADD SSH KEY**
5. Paste your entire public key (from `cat ~/.ssh/id_ed25519.pub`)
6. Click **Save**

---

## Part 4: Test SSH Connection

Before setting up VSCode, verify that SSH works from your terminal.

### Step 1: Start Your VM

If your VM isn't running:

```bash
gcloud compute instances start scrnaseq-vm --zone us-west1-a
```

Replace `us-west1-a` with your VM's actual zone.

### Step 2: Connect via SSH

```bash
gcloud compute ssh scrnaseq-vm --zone us-west1-a
```

The first time you connect, gcloud may:
- Generate SSH keys (if you haven't already)
- Ask you to set a passphrase
- Add the VM's host key to your known_hosts file

Once connected, you'll see a prompt like:

```
your_username@scrnaseq-vm:~$
```

### Step 3: Disconnect

Type `exit` or press `Ctrl+D` to close the SSH connection.

---

## Part 5: Install Visual Studio Code

VSCode is a powerful code editor that can connect directly to your VM, letting you edit files and run commands as if working locally.

### Step 1: Download VSCode

Download from the official website:

**[https://code.visualstudio.com/](https://code.visualstudio.com/)**

### Step 2: Install VSCode

**Windows:**
- Run the downloaded `.exe` installer
- Follow the installation wizard
- Check "Add to PATH" when prompted

**macOS:**
- Open the downloaded `.zip` file
- Drag **Visual Studio Code** to your **Applications** folder
- Open VSCode and optionally add it to your Dock

**Linux (Debian/Ubuntu):**

```bash
# Download the .deb package from the website, then:
sudo dpkg -i code_*.deb
sudo apt install -f  # Install any missing dependencies
```

Or use snap:

```bash
sudo snap install code --classic
```

---

## Part 6: Install the Remote - SSH Extension

The Remote - SSH extension lets VSCode connect to your VM.

### Step 1: Open Extensions

1. Open VSCode
2. Click the **Extensions** icon in the left sidebar (or press `Ctrl+Shift+X` / `Cmd+Shift+X`)

### Step 2: Search and Install

1. Type **"Remote - SSH"** in the search box
2. Find the extension by **Microsoft** (look for the blue verified checkmark)
3. Click **Install**

The extension will also install "Remote - SSH: Editing Configuration Files" as a dependency.

---

## Part 7: Configure SSH for VSCode

VSCode uses your SSH config file to know how to connect to remote hosts.

### Step 1: Run gcloud config-ssh

If you haven't already, run this command to configure SSH:

```bash
gcloud compute config-ssh
```

This creates entries in `~/.ssh/config` for all your Google Cloud VMs.

### Step 2: Verify the Configuration

Check that your VM appears in the SSH config:

```bash
cat ~/.ssh/config
```

You should see an entry like:

```
Host scrnaseq-vm.us-west1-a.your-project-id
    HostName 35.xxx.xxx.xxx
    IdentityFile ~/.ssh/google_compute_engine
    UserKnownHostsFile ~/.ssh/google_compute_known_hosts
```

> **Note:** The IP address (`HostName`) may change if your VM is stopped and restarted. Run `gcloud compute config-ssh` again to update it.

---

## Part 8: Connect to Your VM with VSCode

Now you're ready to connect!

### Step 1: Open the Command Palette

Press:
- **Windows/Linux:** `Ctrl+Shift+P`
- **macOS:** `Cmd+Shift+P`

### Step 2: Connect to Host

1. Type **"Remote-SSH: Connect to Host"** and select it
2. You'll see a list of available hosts from your SSH config
3. Select your VM (e.g., `scrnaseq-vm.us-west1-a.your-project-id`)

### Step 3: Wait for Connection

A new VSCode window will open and begin connecting. The first connection takes 1-2 minutes as VSCode:
- Establishes the SSH connection
- Installs the VSCode Server on your VM
- Sets up the remote environment

You may be prompted for:
- Your SSH key passphrase (if you set one)
- Confirmation to continue connecting (type "yes")

### Step 4: Verify the Connection

Once connected:
- The **bottom-left corner** shows a green/blue indicator with "SSH: scrnaseq-vm..."
- Open a terminal (`Ctrl+`` ` or **Terminal → New Terminal**) to run commands on the VM

Try running:

```bash
hostname
```

It should display `scrnaseq-vm`, confirming you're on your VM.

---

## Part 9: Open Your Working Directory

### Step 1: Open a Folder

1. Click **File → Open Folder** (or press `Ctrl+K Ctrl+O`)
2. Navigate to your home directory: `/home/your_username`
3. Click **OK**

### Step 2: Trust the Folder

VSCode may ask if you trust the authors of the files. Click **Yes, I trust the authors** to enable all features.

Your file explorer (left sidebar) now shows the contents of your VM's home directory.

---

## Part 10: Install R Extensions (Recommended)

For the best experience working with R code, install these extensions while connected to your VM.

### Step 1: Open Extensions

Click the **Extensions** icon or press `Ctrl+Shift+X`.

### Step 2: Install R Support

Search for and install:

| Extension | Author | Purpose |
|-----------|--------|---------|
| **R** | REditorSupport | Syntax highlighting, code completion, help viewer |
| **R Debugger** | RDebugger | Step-through debugging for R scripts |

When prompted, choose to install on the **SSH host** (not locally).

### Step 3: Configure R Extension (Optional)

For enhanced features, you can install the `languageserver` package in R:

1. Open a terminal in VSCode
2. Start R:
   ```bash
   R
   ```
3. Install the package:
   ```r
   install.packages("languageserver")
   ```
4. Exit R:
   ```r
   q()
   ```

---

## Quick Reference

| Task | How To |
|------|--------|
| Open Command Palette | `Ctrl+Shift+P` (Win/Linux) or `Cmd+Shift+P` (Mac) |
| Connect to VM | Command Palette → "Remote-SSH: Connect to Host" |
| Open terminal | `Ctrl+`` ` or Terminal → New Terminal |
| Open folder | `Ctrl+K Ctrl+O` or File → Open Folder |
| Disconnect | Click green/blue indicator → "Close Remote Connection" |
| Update SSH config | `gcloud compute config-ssh` (run locally) |

---

## Troubleshooting

### "Could not establish connection to host"

1. **Is your VM running?**
   ```bash
   gcloud compute instances list
   ```
   Start it if needed:
   ```bash
   gcloud compute instances start scrnaseq-vm --zone us-west1-a
   ```

2. **Has the IP address changed?**
   Run `gcloud compute config-ssh` again to update your SSH config.

3. **Can you connect via regular SSH?**
   ```bash
   gcloud compute ssh scrnaseq-vm --zone us-west1-a
   ```
   If this fails, there may be a network or firewall issue.

### "Permission denied (publickey)"

Your SSH keys aren't set up correctly:

1. Run `gcloud compute config-ssh` to regenerate keys
2. Or manually add your public key via the Google Cloud Console (Compute Engine → Metadata → SSH Keys)

### VSCode is slow or unresponsive

1. Check your internet connection
2. The VM might need more resources—consider upgrading to a larger machine type
3. Close unused extensions to reduce overhead

### Can't find the VM in the host list

1. Run `gcloud compute config-ssh` to update your SSH config
2. Refresh the Remote Explorer in VSCode (click the refresh icon)
3. Check that you're logged into the correct gcloud project:
   ```bash
   gcloud config get-value project
   ```

---

## Managing Your Connection

### Disconnecting

To disconnect from your VM:
- Close the VSCode window, **OR**
- Click the green/blue indicator in the bottom-left corner and select **"Close Remote Connection"**

### Reconnecting

Your recent connections are saved. To reconnect:
1. Open VSCode
2. Open Command Palette (`Ctrl+Shift+P`)
3. Type "Remote-SSH: Connect to Host"
4. Your VM will appear at the top of the list

### Updating SSH Configuration

If your VM's IP address changes (after stopping/starting), update your SSH config:

```bash
gcloud compute config-ssh
```

---

## Next Steps

Now that you're connected to your VM via VSCode, you can:

1. Continue to the [main README](README.md) for Seurat installation instructions
2. Start the [single-cell QC walkthrough](03-scrna-seq-qc-walkthrough.md)
3. Create and edit R scripts directly on your VM
4. Run analysis pipelines from the integrated terminal

> **Remember:** Always stop your VM when you're done to avoid unnecessary charges!
> ```bash
> gcloud compute instances stop scrnaseq-vm --zone us-west1-a
> ```
