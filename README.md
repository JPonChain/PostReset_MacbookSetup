# Setting up your Macbook

Kali Installation - [Click here](https://github.com/JPonChain/InvestigationSetUp?tab=readme-ov-file#kali-linux-installation-guide-macos--utm)

## Download Nord VPN

Download, log in and secure your connection
```
https://nordvpn.com/download/
```

## Terminal set up
Open terminal and run:
```
xcode-select --install
```
If it says it’s already installed, fine. If it pops a dialog, complete it.

Then verify:
```
xcode-select -p
```

You should see something like /Library/Developer/CommandLineTools.

2) Accept the license (sometimes blocks git/brew)
```
sudo xcodebuild -license accept
```
----

# macOS Bootstrap & Case Management System

A production-quality automation system to bootstrap a fresh MacBook and set up a professional case management workflow using Obsidian.

## 🎯 What This Does

This system transforms a brand new Mac into a fully-configured professional workspace with:

- **Secure VPN** (NordVPN)
- **Development tools** (Xcode CLT, Homebrew, Git, Python 3.12)
- **Professional applications** (Obsidian, Telegram, Firefox, UTM)
- **Case management system** with interactive CLI
- **Kali Linux VM** for security work
- **Obsidian vault** optimized for legal/investigative casework

## 📦 What's Included

### Core Scripts

1. **`setup.sh`** - Main bootstrap script
   - Installs all dependencies in correct order
   - Idempotent and resumable (safe to re-run)
   - Creates `~/Tools/` directory structure
   - Comprehensive logging

2. **`case-manager.sh`** - Interactive case management
   - Beautiful menu-driven interface
   - Guided case creation wizard
   - List, search, and open cases
   - Obsidian configuration launcher
   - Case statistics dashboard

3. **`case_manager.py`** - Python backend
   - Standard library only (no dependencies)
   - CLI tool for case operations
   - Creates structured case folders
   - Integrates with Obsidian vault

4. **`setup_obsidian.sh`** - Visual Obsidian configuration wizard
   - Step-by-step guided setup
   - Theme installation (Minimal)
   - Plugin installation (Templater, Dataview, Tasks, Calendar, Kanban)
   - Professional templates
   - Custom CSS styling

## 🚀 Quick Start

### Prerequisites

- Fresh macOS installation (Sonoma, Ventura, or Monterey)
- Administrator access (sudo)
- Internet connection
- ~10GB free disk space (for Kali ISO)

### Installation

1. **Download all scripts to your Mac**
   ```
   cd ~/Downloads/PostReset_MacbookSetup
   ```

2. **Run the bootstrap**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Reload your shell**
   ```bash
   source ~/.zprofile
   ```

4. **Configure Obsidian** (from case manager menu or directly)
   ```bash
   cd /Users/k9/tools/caseManager
   chmod +x setup_obsidian.sh
   chmod +x case_manager.sh
   chmod +x vault-template.sh
   ./setup_obsidian.sh
   ```

5. **Manually Launch case manager**
from start
   ```bash
   cd /Users/k9/Tools/caseManager
   ./case_manager.sh
   ```
If already in diirectory
   ```bash
   ./case_manager.sh
   ```
----
   
# Vault Templates
From the same directory location:
```bash
./vault-template.sh
```
From start
```bash
cd /Users/k9/tools/caseManager
./vault-template.sh
```

Run this:
```
chmod +x vault-template.sh
./vault-template.sh
```

----

# 📋 Installation Phases

The bootstrap runs in 8 carefully ordered phases:

### Phase 0: Preflight
- Creates `~/Tools/` directory structure
- Verifies network connectivity
- Checks permissions
- Sets up PATH

### Phase 1: NordVPN
- Installs NordVPN via official PKG
- **Runs BEFORE Homebrew** (no dependencies)
- Multiple download methods with fallback

### Phase 2: Xcode Command Line Tools
- Installs Apple's developer tools
- Required for compilation
- Accepts license automatically

### Phase 3: Homebrew
- Installs package manager
- Architecture-aware (Apple Silicon vs Intel)
- Updates and verifies installation

### Phase 4: Core Tooling
- Git, GitHub CLI
- pyenv with Python 3.12.7
- pipx for Python tools
- wget, jq, coreutils
- **bash 5.x** (required for scripts)

### Phase 5: GUI Applications
- Obsidian (case management)
- Telegram (communication)
- Firefox (web browser)
- UTM (virtualization)

### Phase 6: Obsidian Vault
- Creates vault structure
- Basic templates (Intake, Meeting, Evidence)
- Copies setup_obsidian.sh to Tools

### Phase 7: Case Manager
- Creates interactive case-manager.sh
- Copies case_manager.py to Tools
- Adds `cases` alias to shell

### Phase 8: UTM & Kali Linux
- Downloads Kali Linux ISO (~3GB)
- Architecture-specific (ARM64 or AMD64)
- Provides VM creation instructions

## 🎨 Case Manager Features

Launch with `cases` command:

```
╔════════════════════════════════════════════════════════════════╗
║                   CASE MANAGEMENT SYSTEM                       ║
║                    Tools Directory Menu                        ║
╚════════════════════════════════════════════════════════════════╝

Main Menu:
  1) Create New Case        - Guided 4-step wizard
  2) List All Cases         - Filter by status
  3) Open Existing Case     - Opens in Finder
  4) Search Cases           - Find by ID/name/keyword
  5) Configure Obsidian     - Run setup wizard
  6) View Case Statistics   - Dashboard with counts
  7) Export Case Report     - Coming soon
  8) Help & Documentation   - Full guide
  9) Exit
```

### Creating a New Case

The wizard walks you through:

1. **Case ID** - Format validation (YYYY-NNN or PREFIX-NNN)
2. **Case Name** - Descriptive name
3. **Client Type** - Individual/Corporate/Criminal/Civil
4. **Confirmation** - Review and create

**Automatically creates:**
```
Cases/2026-001 - John Doe Investigation/
├── case.md                    # Main case file with metadata
├── 00 - Intake/              # Initial consultation
│   └── 2026-001 - Intake Notes.md
├── 01 - Evidence/            # Documents, photos, recordings
├── 02 - Notes/               # Meeting notes, research
├── 03 - Tasks/               # Action items
│   └── 2026-001 - Task List.md
└── 99 - Export/              # Final reports
```

## 🎨 Obsidian Configuration Wizard

The `setup_obsidian.sh` script provides a beautiful, interactive setup:

### Visual Features
- ✨ Welcome screen with overview
- 📊 Progress bar (Step X of 7)
- 🎨 Color-coded output
- ⏳ Animated spinners during downloads
- 🎉 Celebration completion screen

### What Gets Configured

**Step 1: Vault Verification**
- Checks/creates vault at `~/Documents/ObsidianVault`
- Creates directory structure

**Step 2: Theme Installation**
- Installs Minimal theme (clean, professional)
- Downloads from GitHub

**Step 3: Plugin Installation**
- 📋 Templater - Dynamic templates
- 📊 Dataview - Query case data
- ✅ Tasks - Task management
- 📅 Calendar - Timeline view
- 🗂️ Kanban - Board workflows

**Step 4: Appearance Configuration**
- Sets accent colors
- Custom CSS styling
- Status tag colors (🟢 Active, 🔴 Closed, 🟠 Pending)

**Step 5: Core Settings**
- Optimized for casework
- Template configuration
- Keyboard shortcuts

**Step 6: Template Creation**
- Case Dashboard (with Dataview queries)
- Timeline (chronological events)
- Witness Interview (structured)
- Evidence Log (chain of custody)
- Meeting Notes (action items)

**Step 7: Plugin Configuration**
- Templater settings
- Dataview preferences
- Tasks automation

## 📁 Directory Structure

After bootstrap completion:

```
~/Tools/
├── setup.sh          # Main bootstrap script
├── case-manager.sh           # Interactive menu (auto-created)
├── case_manager.py           # Python backend
├── setup_obsidian.sh         # Obsidian wizard
├── bin/                      # Custom scripts on PATH
├── logs/                     # Bootstrap logs (last 10 kept)
│   └── bootstrap_20260104_153045.log
└── tmp/                      # Temporary downloads

~/Documents/ObsidianVault/
├── .obsidian/                # Obsidian configuration
│   ├── plugins/              # Community plugins
│   ├── themes/               # Minimal theme
│   └── snippets/             # Custom CSS
├── Cases/                    # All case folders
│   └── 2026-001 - Client Name/
├── Templates/                # Case templates
│   ├── Case Dashboard.md
│   ├── Timeline.md
│   ├── Witness Interview.md
│   ├── Evidence Log.md
│   └── Meeting Notes.md
└── Attachments/              # Shared media files

~/UTM/
└── ISOs/
    └── kali-linux-2024.4-installer-arm64.iso  # (or amd64)
```

## 🔧 Configuration & Customization

### Environment Variables

```bash
# Override vault location
export OBSIDIAN_VAULT_PATH="$HOME/Documents/MyVault"

# Override Tools directory
export TOOLS_DIR="$HOME/CustomTools"

# Override Python version
export PYTHON_VERSION="3.12.8"

# Then run bootstrap
./setup.sh
```

### Bash Version Note

The scripts require **bash 4.0+** for associative arrays. macOS ships with bash 3.2.

✅ **Solution:** Bootstrap automatically installs bash 5.x via Homebrew

If you encounter bash version errors:
```bash
# Install bash manually
brew install bash

# Run scripts with Homebrew bash
/opt/homebrew/bin/bash ~/Tools/setup_obsidian.sh
```

## 🛠️ Troubleshooting

### Bootstrap fails on NordVPN download
```bash
# Download manually and install
open https://nordvpn.com/download/mac/
# Then re-run bootstrap (it will skip completed steps)
./setup.sh
```

### "declare: -A: invalid option"
You're using the old bash. Use Homebrew's bash:
```bash
/opt/homebrew/bin/bash ~/Tools/setup_obsidian.sh
# Or install bash first
brew install bash
```

### Case manager not found
```bash
# Ensure case_manager.py is in Tools
cp case_manager.py ~/Tools/
chmod +x ~/Tools/case_manager.py

# Re-run bootstrap to set up wrapper
./setup.sh
```

### Obsidian plugins not working
1. Open Obsidian
2. Settings → Community Plugins
3. Click "Turn on community plugins"
4. Enable each plugin individually

### Permission denied errors
```bash
# Make scripts executable
chmod +x setup.sh
chmod +x ~/Tools/case-manager.sh
chmod +x ~/Tools/setup_obsidian.sh
```

## 📝 Manual Installation Steps

### Copy Files to Tools
```bash
cd ~/Downloads

# Copy all scripts
cp setup.sh case_manager.py setup_obsidian.sh ~/Tools/

# Make executable
chmod +x ~/Tools/*.sh ~/Tools/*.py

# Verify
ls -la ~/Tools/
```

### Run Individual Components
```bash
# Just install Obsidian configuration
cd ~/Tools && ./setup_obsidian.sh

# Just use case manager
cd ~/Tools && ./case-manager.sh

# Use Python tool directly
python3 ~/Tools/case_manager.py list
```

## 🔐 Security Notes

- **NordVPN**: Requires manual login (credentials not automated)
- **GitHub**: Requires `gh auth login` for CLI access
- **sudo**: Required for NordVPN, Xcode, and shell modifications
- **No credentials stored**: All logins are manual
- **Logs**: Stored in `~/Tools/logs/` (review for sensitive data)

## 🎓 Usage Examples

### Case Manager CLI

```bash
# Interactive menu
cases

# Direct Python commands
python3 ~/Tools/case_manager.py new --id 2026-001 --name "Client Name"
python3 ~/Tools/case_manager.py list --status active
python3 ~/Tools/case_manager.py open --id 2026-001
```

### Obsidian Templates

After running `setup_obsidian.sh`:

1. Open Obsidian
2. Press `Cmd/Ctrl + Shift + T` (Templater)
3. Select template:
   - Case Dashboard
   - Timeline
   - Witness Interview
   - Evidence Log
   - Meeting Notes

## 📊 Case Management Workflow

### Recommended Workflow

1. **Create case** via `cases` menu
2. **Open Obsidian** and select your vault
3. **Navigate** to Cases/[case-name]/
4. **Use templates** for documentation
5. **Track tasks** in 03 - Tasks folder
6. **Store evidence** in 01 - Evidence folder
7. **Export** final reports to 99 - Export

### Obsidian Features

- **Dataview queries** - Filter and display cases
- **Tasks plugin** - Track deadlines and todos
- **Calendar** - Visualize case timelines
- **Kanban boards** - Workflow management
- **Backlinks** - Connect related information

## 🔄 Updating

The bootstrap is idempotent - safe to re-run:

```bash
# Updates tools and fixes issues
./setup.sh

# Reconfigure Obsidian
cd ~/Tools && ./setup_obsidian.sh
```

## 📦 What Gets Installed

### Homebrew Packages
- git
- gh (GitHub CLI)
- pyenv
- pipx
- wget
- jq
- coreutils
- bash (5.x)

### Homebrew Casks
- obsidian
- telegram
- firefox
- utm

### Python
- Python 3.12.7 via pyenv
- case-manager via pipx (optional)

## 🎯 System Requirements

- **macOS**: Sonoma (14.x), Ventura (13.x), or Monterey (12.x)
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 10GB free for Kali ISO, 20GB+ recommended
- **Network**: Stable internet for downloads

## 📄 License & Credits

**Created for**: Professional case management and legal workflows

**Technologies**:
- Bash 5.x
- Python 3.12
- Obsidian with Minimal theme
- Homebrew package manager

## 🆘 Support

### Common Issues

1. **Slow downloads**: Normal for Kali ISO (3GB), use good connection
2. **Homebrew warnings**: Non-fatal, logged but script continues
3. **Plugin failures**: Install manually from Obsidian
4. **Old bash**: Bootstrap installs bash 5.x automatically

### Getting Help

1. Check logs: `cat ~/Tools/logs/bootstrap_*.log`
2. Verify installations: `brew list`, `python --version`
3. Test components individually
4. Re-run bootstrap (idempotent)

## 🎉 Success Criteria

After completion, you should have:

- ✅ `cases` command available
- ✅ Obsidian vault at `~/Documents/ObsidianVault`
- ✅ Python 3.12.7 installed
- ✅ All GUI apps in `/Applications/`
- ✅ Kali ISO ready for VM creation
- ✅ Professional templates in Obsidian
- ✅ Interactive case management system

---

# Kali Linux Installation Guide (macOS – UTM)

This guide explains how to install **Kali Linux** on macOS using **UTM**.  
It is designed for **Apple Silicon (M1 / M2 / M3 / M4)** Macs and avoids the most common installer failures.

> ✅ Follow this guide exactly  
> ❌ Do not improvise partitioning, bootloader, or networking steps

---

## Requirements

- macOS on **Apple Silicon**
- **UTM** installed
- Kali Linux **ARM64 Installer ISO** (not NetInstaller)

---

## Before You Start (Important)

- This is a **virtual machine** install
- Use **guided partitioning**
- Always install **GRUB**
- **Remove the ISO before first boot**

⚠️ If you skip ISO removal, Kali will loop back to the installer menu.

---

## Step 1: Create the VM in UTM

1. Open **UTM**
2. Click **Create**
3. Select **Virtualize**
4. Select **Linux**
5. Choose the Kali **ARM64 installer ISO**
6. Configure:
   - **Memory**: 4 GB minimum (8 GB recommended)
   - **CPU**: 2 cores minimum
   - **Storage**: 40 GB minimum (60+ GB recommended)
6b. Add 'Serial' to settings
7. Networking:
   - **Shared Network (NAT)**

Finish creation and start the VM.

---

## Step 2: Start the Installer

At the boot menu, choose:
```
Install
```

---

## Step 3: Language, Location, Keyboard

Choose settings appropriate for your region.

---

## Step 4: Configure the Network

### Hostname
```
kali
```
(Default is fine.)

### Domain Name
Leave this BLANK

Press **Continue**.

✅ This is correct for UTM, NAT networking, and home use.

---

## Step 5: Users and Passwords

- Create the default user (`kali`)
- Set a strong password

---

## Step 6: Disk Partitioning (CRITICAL)

When asked **“Partition disks”**, choose:
```
Guided – use entire disk
→ All files in one partition
→ Finish partitioning and write changes to disk
→ Yes
```

### Disk selection (verify this)
You should see something like:
```
vda 68.7 GB VirtIO Block Device
```

✅ This is the correct disk  
❌ Do NOT choose the installer ISO or anything ~3–4 GB in size

---

## Step 7: Software Selection (IMPORTANT)

On **Choose software to install**, select:
```
✔ Kali Linux
✔ Desktop → Xfce
(optional) ✔ SSH server
```

Leave everything else unchecked.

### Why Xfce?
- Fastest desktop in UTM
- Lowest RAM usage
- Most reliable graphics support

---

## Step 8: Install the GRUB Bootloader (CRITICAL)

When prompted:

### Install GRUB boot loader?
```
YES
```

### Device for GRUB installation:
```
/dev/vda
```

❌ Do NOT select `/dev/vda1`  
❌ Do NOT skip this step  

Skipping or misplacing GRUB causes boot failure.

---

## Step 9: Installation Complete → REBOOT

When the installer finishes:

1. PAUSE - Go back to the UTM main menu, on the Kali instance, clear the ISO image - you may need to scroll down a bit first
2. Choose **Continue**
3. The VM will attempt to reboot

---

## Step 10: REMOVE THE INSTALLER ISO (VERY IMPORTANT)

If you do not remove the ISO, Kali will restart the installer again.

### In UTM:

1. **Power off** the VM
2. Open **VM Settings**
3. Go to **Drives**
4. **Delete or uncheck the Kali ISO**
5. Ensure only this remains:
Boot → vda (VirtIO Block Device)


6. Start the VM again

---

## Step 11: First Boot

You should now see:
- GRUB menu (briefly), then
- Kali login screen

Login with:
Username: kali
Password: (what you set)

yaml
Copy code

---

## Common Problems & Fixes

### Installer loops back to menu
**Cause**
- ISO still attached **OR**
- GRUB not installed to `/dev/vda`

**Fix**
- Power off → remove ISO → reboot
- If GRUB was skipped, reinstall Kali and ensure GRUB is installed

---

### “No default route” during install
**Fix**
- Continue installation **offline**
- Networking will work after first boot with NAT

---

### Black screen after install
**Fix**
- Ensure **Xfce** was selected
- Increase VM RAM to 6–8 GB
- Restart VM

---

## Summary (Memorize This)

Graphical Install
Hostname: kali
Domain: (blank)
Partitioning: Guided → Entire disk → One partition
Disk: vda (VirtIO)
Software: Kali + Xfce
GRUB: Yes → /dev/vda
REMOVE ISO BEFORE BOOT

yaml
Copy code

---

## Recommended After Login

```bash
sudo apt update
sudo apt full-upgrade -y
reboot
