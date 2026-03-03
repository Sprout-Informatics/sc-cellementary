# Setting Up SSH Access and Connecting with VSCode

This guide walks you through setting up SSH access to your Google Cloud VM and connecting using Visual Studio Code (VSCode). By the end, you'll be able to edit code and run commands on your VM directly from your local machine.
---

## Prerequisites

- A Google Cloud VM already created (from the previous guide)
- A local computer (Windows, macOS, or Linux)
- An SSH public key file (generated for you, assigned to the VM you are connecting to)
- About 15-20 minutes

---

## Part 1: Test SSH Connection

Before setting up VSCode, verify that SSH works from your terminal.

### Step 1: Connect via SSH

```bash
ssh -i PATH_TO_PUBLIC_KEY_FILE username@[IP.ADDRESS] ## This needs to be setup for participants before hand
```

In this workshop, everyone will log in with the username `cellementary`. Example:

```bash
ssh cellementary@[IP ADDRESS] -i ~/.ssh/id_ed25519_sc-cellementary
```

Once connected, you'll see a prompt like:

```
cellementary@sc-cellementary-default:~$
```

Type `exit` or press `Ctrl+D` to close the SSH connection.

---

## Part 2: Install Visual Studio Code

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

---

## Part 3: Install the Remote - SSH Extension

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

## Part 4: Configure SSH for VSCode

VSCode uses your SSH config file to know how to connect to remote hosts. This step will be very similar to how your computer uses SSH to connect to the VM without VSCode.

### Step 1: Verify the Configuration

If you don't already have a file named `~/.ssh/config`, create it.

```bash
cat ~/.ssh/config
```

Create an entry for the cellementary host, being sure to enter the correct path to the key file in place of PATH/TO below:

```
Host cellementary-vm
  HostName <IP ADDRESS>
  IdentityFile <PATH/TO/>id_ed25519_sc-cellementary
  User cellementary
```

> **Note:** The IP address (`HostName`) may change if your VM is stopped and restarted. Run `gcloud compute config-ssh` again to update it (or get it from the cellementary class coordinator)

---

## Part 5: Connect to Your VM with VSCode

Now you're ready to connect!

### Step 1: Open the Command Palette

Press:
- **Windows/Linux:** `Ctrl+Shift+P`
- **macOS:** `Cmd+Shift+P`

### Step 2: Connect to Host

1. Type **"Remote-SSH: Connect to Host"** and select it
2. You'll see a list of available hosts from your SSH config
3. Select your VM (e.g., `cellementary-vm`)

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
- The **bottom-left corner** shows a green/blue indicator with "SSH: cellementary-vm..."
- Open a terminal (`Ctrl+`` ` or **Terminal → New Terminal**) to run commands on the VM

Try running:

```bash
hostname
```

It should display `sc-cellementary-default`, confirming you're on your VM.

<img width="388" height="141" alt="image" src="https://github.com/user-attachments/assets/9f909c7d-f538-43c5-8552-81b3d561cf50" />

---

## Part 6: Open Your Working Directory

### Step 1: Open a Folder

1. Click **File → Open Folder** (or press `Ctrl+K Ctrl+O`)
2. Navigate to your home directory: `/home/cellementary`
3. Click **OK**

The procedure above will look like this:

<img width="1096" height="442" alt="image" src="https://github.com/user-attachments/assets/466dbd36-e8d8-45e7-a19c-4c4516c4a5de" />


### Step 2: Trust the Folder

VSCode may ask if you trust the authors of the files. Click **Yes, I trust the authors** to enable all features.

Your file explorer (left sidebar) now shows the contents of your VM's home directory.

---

## Part 7: Install Extensions

We will make sure the following VSCode extensions are installed:

- R
- Python
- Jupyter

### Step 1: Open Extensions

Click the **Extensions** icon or press `Ctrl+Shift+X`.

What the extensions pane looks like in VSCode:

<img width="800" alt="image" src="https://github.com/user-attachments/assets/f941386a-4a53-483f-8644-4d9f1dd6aea1" />

When prompted, choose to install on the **SSH host** (not locally).
If prompted to install additional extensions, do so.

---

## Part 8: Install the R kernel

From a terminal window (Terminal->New Terminal if not already visible), install R

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

## Next Steps

Now that you're connected to your VM via VSCode, you can:

1. Continue to the [main README](README.md) for Seurat installation instructions
2. Start the [single-cell QC walkthrough](03-scrna-seq-qc-walkthrough.md)
3. Create and edit R scripts directly on your VM
4. Run analysis pipelines from the integrated terminal

