#!/usr/bin/env bash
#
# bootstrap_mac.sh - Production macOS bootstrap for fresh Macs
# Safe for Apple Silicon & Intel, idempotent, resumable
#
# Usage: chmod +x bootstrap_mac.sh && ./bootstrap_mac.sh
#

set -euo pipefail

# ============================================================================
# CONFIGURATION & DEFAULTS
# ============================================================================

PYTHON_VERSION="${PYTHON_VERSION:-3.12.7}"
OBSIDIAN_VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/ObsidianVault}"
TOOLS_DIR="${TOOLS_DIR:-$HOME/Tools}"
CASE_MANAGER_DIR="${CASE_MANAGER_DIR:-$TOOLS_DIR/caseManager}"
LOG_DIR="${LOG_DIR:-$TOOLS_DIR/logs}"
LOG_FILE="${LOG_DIR}/bootstrap_$(date +%Y%m%d_%H%M%S).log"
MAX_LOGS=10
INVESTIGATION_SETUP_SRC="${INVESTIGATION_SETUP_SRC:-$HOME/Downloads/investigationsetup-main}"

# Kali ISO settings
KALI_ISO_DIR="$HOME/UTM/ISOs"
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
    KALI_URL="https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-installer-arm64.iso"
    KALI_ISO_NAME="kali-linux-2024.4-installer-arm64.iso"
else
    KALI_URL="https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-installer-amd64.iso"
    KALI_ISO_NAME="kali-linux-2024.4-installer-amd64.iso"
fi

# Homebrew packages
BREW_PACKAGES=(git gh pyenv pipx wget jq coreutils bash)
BREW_CASKS=(obsidian telegram firefox utm)

# ============================================================================
# ERROR HANDLING & LOGGING
# ============================================================================

trap 'echo "⛔ Failed on line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

# Ensure log directory exists before redirecting
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# Clean old logs (keep last MAX_LOGS)
cleanup_old_logs() {
    local logs=($(ls -t "$LOG_DIR"/bootstrap_*.log 2>/dev/null || true))
    if [[ ${#logs[@]} -gt $MAX_LOGS ]]; then
        for ((i=$MAX_LOGS; i<${#logs[@]}; i++)); do
            rm -f "${logs[$i]}"
        done
    fi
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

move_investigation_setup_repo() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  FINAL: MOVE INVESTIGATION SETUP FILES → caseManager"
    echo "╚══════════════════════════════════════════════════════════════╝"

    local src="$INVESTIGATION_SETUP_SRC"
    local dest="$CASE_MANAGER_DIR"

    if [[ ! -d "$src" ]]; then
        warn "Source folder not found, skipping move: $src"
        return 0
    fi

    ensure_dir "$dest"

    # Move contents safely & idempotently:
    # - copies everything (including dotfiles) into dest
    # - removes source files after successful transfer
    # - leaves existing dest files as-is unless they are updated by rsync
    info "Moving files from: $src"
    info "Into:            $dest"

    if command_exists rsync; then
        rsync -a --remove-source-files "$src"/ "$dest"/
        # Clean up empty directories left behind in src
        find "$src" -type d -empty -delete 2>/dev/null || true
        rmdir "$src" 2>/dev/null || true
        info "✓ Move complete"
    else
        # Fallback without rsync (handles dotfiles)
        shopt -s dotglob nullglob
        mv -n "$src"/* "$dest"/ 2>/dev/null || true
        shopt -u dotglob nullglob
        rmdir "$src" 2>/dev/null || true
        info "✓ Move complete (mv fallback)"
    fi

    # Navigate into the folder at the end (within the script process)
    cd "$dest"
    info "Now in: $(pwd)"

    # Optional: if you ran this script interactively, drop you into a shell in that directory
    if [[ -t 0 ]]; then
        echo ""
        echo "🚀 Opening a new login shell in: $dest"
        exec "$SHELL" -l
    fi
}


info() {
    echo "ℹ️  $*"
}

warn() {
    echo "⚠️  $*" >&2
}

fail() {
    echo "❌ $*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        info "Created directory: $1"
    fi
}

append_line_if_missing() {
    local line="$1"
    local file="$2"
    
    touch "$file"
    if ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        info "Added to $file: $line"
    fi
}

brew_install() {
    local package="$1"
    if brew list "$package" &>/dev/null; then
        info "✓ $package already installed"
        return 0
    fi
    
    info "Installing $package..."
    if brew install "$package"; then
        info "✓ Installed $package"
        return 0
    else
        fail "Failed to install $package"
    fi
}

brew_cask_install() {
    local cask="$1"
    local attempts=2
    
    if brew list --cask "$cask" &>/dev/null; then
        info "✓ $cask already installed"
        return 0
    fi
    
    for ((i=1; i<=attempts; i++)); do
        info "Installing $cask (attempt $i/$attempts)..."
        if brew install --cask "$cask"; then
            info "✓ Installed $cask"
            return 0
        fi
        [[ $i -lt $attempts ]] && warn "Retry in 2 seconds..." && sleep 2
    done
    
    warn "Failed to install $cask after $attempts attempts"
    return 1
}

check_network() {
    info "Checking network connectivity..."
    
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        fail "No network connectivity (ping failed)"
    fi
    
    if ! curl -sf https://www.apple.com > /dev/null; then
        fail "Cannot reach internet (HTTPS check failed)"
    fi
    
    info "✓ Network is operational"
}

# ============================================================================
# PHASE 0: PREFLIGHT
# ============================================================================

phase_0_preflight() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 0: PREFLIGHT CHECKS"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    info "macOS version: $(sw_vers -productVersion)"
    info "Architecture: $(uname -m)"
    info "User: $(whoami)"
    info "Shell: $SHELL"
    
    check_network
    
    # Create directory structure
    ensure_dir "$TOOLS_DIR"
    ensure_dir "$TOOLS_DIR/bin"
    ensure_dir "$CASE_MANAGER_DIR"  # Create caseManager folder
    ensure_dir "$LOG_DIR"
    ensure_dir "$TOOLS_DIR/tmp"
    
    # Test write permissions
    if ! touch "$TOOLS_DIR/tmp/.test" 2>/dev/null; then
        fail "Cannot write to $TOOLS_DIR - check permissions"
    fi
    rm -f "$TOOLS_DIR/tmp/.test"
    
    # Add ~/Tools/bin to PATH
    local path_line='export PATH="$HOME/Tools/bin:$PATH"'
    append_line_if_missing "$path_line" "$HOME/.zprofile"
    append_line_if_missing "$path_line" "$HOME/.zshrc"
    export PATH="$HOME/Tools/bin:$PATH"
    
    cleanup_old_logs
    
    info "✓ Preflight complete"
}

# ============================================================================
# PHASE 1: NORDVPN (BEFORE HOMEBREW)
# ============================================================================

phase_1_nordvpn() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 1: NORDVPN INSTALLATION"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    if [[ -d "/Applications/NordVPN.app" ]]; then
        info "✓ NordVPN already installed"
        return 0
    fi
    
    info "Downloading NordVPN PKG..."
    local pkg_file="$TOOLS_DIR/tmp/NordVPN.pkg"
    local download_success=false
    local min_size=50000000  # Minimum 50MB (actual PKG is ~80-100MB)
    
    # Clean up any existing partial download
    rm -f "$pkg_file"
    
    # Method 1: Correct NordVPN URL
    info "Downloading from official NordVPN CDN..."
    if curl -L -C - --max-time 300 --retry 3 --retry-delay 2 -o "$pkg_file" \
        "https://downloads.nordcdn.com/apps/macos/generic/NordVPN-OpenVPN/latest/NordVPN.pkg" 2>&1 | grep -v "^[[:space:]]*$"; then
        
        # Verify file size
        if [[ -f "$pkg_file" ]]; then
            local file_size=$(stat -f%z "$pkg_file" 2>/dev/null || echo "0")
            info "Downloaded file size: $((file_size / 1048576)) MB"
            
            if [[ $file_size -gt $min_size ]]; then
                # Verify it's actually a PKG file
                if file "$pkg_file" | grep -q "xar archive"; then
                    download_success=true
                    info "✓ Download successful and verified (xar/PKG format)"
                else
                    warn "Downloaded file is not a valid PKG (wrong format)"
                    file "$pkg_file"
                fi
            else
                warn "Downloaded file too small ($((file_size / 1048576)) MB, expected >50MB)"
            fi
        fi
    fi
    
    # Method 2: Alternative direct URL (fallback)
    if [[ "$download_success" == false ]]; then
        info "Attempt 2: Alternative download URL..."
        rm -f "$pkg_file"
        
        if curl -L -C - --max-time 300 --retry 3 --retry-delay 2 -o "$pkg_file" \
            "https://nordvpn.com/download/mac/latest/" 2>&1 | grep -v "^[[:space:]]*$"; then
            
            if [[ -f "$pkg_file" ]]; then
                local file_size=$(stat -f%z "$pkg_file" 2>/dev/null || echo "0")
                info "Downloaded file size: $((file_size / 1048576)) MB"
                
                if [[ $file_size -gt $min_size ]] && file "$pkg_file" | grep -q "xar archive"; then
                    download_success=true
                    info "✓ Download successful and verified"
                fi
            fi
        fi
    fi
    
    # Method 3: Use wget if available
    if [[ "$download_success" == false ]] && command_exists wget; then
        info "Attempt 3: Using wget..."
        rm -f "$pkg_file"
        
        if wget --timeout=300 --tries=3 -O "$pkg_file" \
            "https://downloads.nordcdn.com/apps/macos/generic/NordVPN-OpenVPN/latest/NordVPN.pkg" 2>&1; then
            
            if [[ -f "$pkg_file" ]]; then
                local file_size=$(stat -f%z "$pkg_file" 2>/dev/null || echo "0")
                if [[ $file_size -gt $min_size ]] && file "$pkg_file" | grep -q "xar archive"; then
                    download_success=true
                    info "✓ Download successful via wget"
                fi
            fi
        fi
    fi
    
    # If all methods failed
    if [[ "$download_success" == false ]]; then
        warn "Automatic download failed after multiple attempts"
        rm -f "$pkg_file"
        echo ""
        echo "📋 MANUAL NORDVPN INSTALLATION:"
        echo "   1. Open Safari and visit: https://nordvpn.com/download/mac/"
        echo "   2. Click 'Download' and save the PKG file"
        echo "   3. Open the downloaded .pkg file from Downloads"
        echo "   4. Follow the installation wizard"
        echo ""
        echo "   Or download directly:"
        echo "   https://downloads.nordcdn.com/apps/macos/generic/NordVPN-OpenVPN/latest/NordVPN.pkg"
        echo ""
        echo "   The script will continue with other installations..."
        echo ""
        warn "Continuing without NordVPN (install manually later)"
        return 0
    fi
    
    # Installation
    info "Installing NordVPN (requires sudo password)..."
    info "PKG file: $pkg_file"
    
    # Run installer with detailed output
    if sudo installer -pkg "$pkg_file" -target / -verbose 2>&1 | tee "$LOG_DIR/nordvpn_install.log"; then
        info "✓ Installer command completed"
    else
        local exit_code=$?
        warn "Installer returned exit code: $exit_code"
        warn "Check log: $LOG_DIR/nordvpn_install.log"
        
        # Show last 20 lines of log
        echo ""
        echo "Last 20 lines of installer output:"
        tail -n 20 "$LOG_DIR/nordvpn_install.log"
    fi
    
    # Clean up
    rm -f "$pkg_file"
    
    # Verify installation with retry
    info "Verifying installation..."
    sleep 3
    
    local max_attempts=5
    for ((i=1; i<=max_attempts; i++)); do
        if [[ -d "/Applications/NordVPN.app" ]]; then
            info "✓ NordVPN installed successfully"
            echo ""
            echo "📋 MANUAL STEP: Open /Applications/NordVPN.app and sign in"
            return 0
        fi
        [[ $i -lt $max_attempts ]] && sleep 2
    done
    
    warn "NordVPN app not found in /Applications after installation"
    warn "The installer may have failed. Try manual installation:"
    warn "  https://nordvpn.com/download/mac/"
}

# ============================================================================
# PHASE 2: XCODE COMMAND LINE TOOLS
# ============================================================================

phase_2_xcode_clt() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 2: XCODE COMMAND LINE TOOLS"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    if xcode-select -p &>/dev/null; then
        info "✓ Xcode CLT already installed at $(xcode-select -p)"
        return 0
    fi
    
    info "Installing Xcode Command Line Tools..."
    info "A dialog will appear - click Install and wait for completion"
    
    # Trigger installation (may fail on fresh Mac, that's ok)
    xcode-select --install 2>/dev/null || true
    
    # Poll until installed
    info "Waiting for Xcode CLT installation..."
    local max_wait=600
    local elapsed=0
    
    while ! xcode-select -p &>/dev/null; do
        if [[ $elapsed -ge $max_wait ]]; then
            fail "Xcode CLT installation timed out after ${max_wait}s"
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    info "✓ Xcode CLT installed at $(xcode-select -p)"
    
    # Accept license if needed
    if sudo xcodebuild -license accept 2>/dev/null; then
        info "✓ Xcode license accepted"
    fi
}

# ============================================================================
# PHASE 3: HOMEBREW
# ============================================================================

phase_3_homebrew() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 3: HOMEBREW"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    if command_exists brew; then
        info "✓ Homebrew already installed at $(which brew)"
    else
        info "Installing Homebrew..."
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            fail "Homebrew installation failed"
        fi
    fi
    
    # Set PATH for current shell
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        local shellenv_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        local shellenv_line='eval "$(/usr/local/bin/brew shellenv)"'
    else
        fail "Homebrew installed but brew command not found"
    fi
    
    # Persist to shell configs
    append_line_if_missing "$shellenv_line" "$HOME/.zprofile"
    append_line_if_missing "$shellenv_line" "$HOME/.zshrc"
    
    info "Updating Homebrew..."
    brew update
    
    info "Running brew doctor (warnings are non-fatal)..."
    brew doctor || warn "brew doctor reported warnings (logged, continuing)"
    
    info "✓ Homebrew ready"
}

# ============================================================================
# PHASE 4: CORE TOOLING
# ============================================================================

phase_4_core_tools() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 4: CORE TOOLING"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    for package in "${BREW_PACKAGES[@]}"; do
        brew_install "$package"
    done
    
    # Verify bash installation and add to allowed shells
    if brew list bash &>/dev/null; then
        local brew_bash="$(brew --prefix)/bin/bash"
        if [[ -x "$brew_bash" ]]; then
            info "Homebrew bash installed at: $brew_bash"
            info "Version: $($brew_bash --version | head -n1)"
            
            # Add to /etc/shells if not already there
            if ! grep -q "$brew_bash" /etc/shells 2>/dev/null; then
                info "Adding Homebrew bash to /etc/shells (requires sudo)..."
                echo "$brew_bash" | sudo tee -a /etc/shells > /dev/null
                info "✓ Homebrew bash added to allowed shells"
            fi
        fi
    fi
    
    # Python via pyenv
    info "Setting up pyenv..."
    
    local pyenv_init='export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'
    
    append_line_if_missing 'export PYENV_ROOT="$HOME/.pyenv"' "$HOME/.zprofile"
    append_line_if_missing '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' "$HOME/.zprofile"
    append_line_if_missing 'eval "$(pyenv init -)"' "$HOME/.zprofile"
    
    append_line_if_missing 'export PYENV_ROOT="$HOME/.pyenv"' "$HOME/.zshrc"
    append_line_if_missing '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' "$HOME/.zshrc"
    append_line_if_missing 'eval "$(pyenv init -)"' "$HOME/.zshrc"
    
    # Initialize pyenv in current shell
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    if pyenv versions | grep -q "$PYTHON_VERSION"; then
        info "✓ Python $PYTHON_VERSION already installed via pyenv"
    else
        info "Installing Python $PYTHON_VERSION via pyenv (this may take a few minutes)..."
        pyenv install "$PYTHON_VERSION"
    fi
    
    pyenv global "$PYTHON_VERSION"
    info "✓ Python $(python --version) set as global"
    
    # pipx setup
    info "Ensuring pipx path..."
    pipx ensurepath --force
    
    # Refresh PATH for pipx
    export PATH="$HOME/.local/bin:$PATH"
    
    info "✓ Core tooling complete"
}

# ============================================================================
# PHASE 5: GUI APPLICATIONS
# ============================================================================

phase_5_gui_apps() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 5: GUI APPLICATIONS"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    local failed_casks=()
    
    for cask in "${BREW_CASKS[@]}"; do
        if ! brew_cask_install "$cask"; then
            failed_casks+=("$cask")
        fi
    done
    
    if [[ ${#failed_casks[@]} -gt 0 ]]; then
        warn "Some casks failed to install: ${failed_casks[*]}"
        warn "You can retry manually with: brew install --cask <name>"
    fi
    
    info "✓ GUI applications phase complete"
}

# ============================================================================
# PHASE 6: OBSIDIAN VAULT SETUP
# ============================================================================

phase_6_obsidian_vault() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 6: OBSIDIAN VAULT BASIC SETUP"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    ensure_dir "$OBSIDIAN_VAULT_PATH"
    ensure_dir "$OBSIDIAN_VAULT_PATH/Cases"
    ensure_dir "$OBSIDIAN_VAULT_PATH/Templates"
    ensure_dir "$OBSIDIAN_VAULT_PATH/Attachments"
    ensure_dir "$OBSIDIAN_VAULT_PATH/.obsidian"
    
    # Create basic templates
    cat > "$OBSIDIAN_VAULT_PATH/Templates/Intake.md" <<'EOF'
---
case-id: 
client: 
date: {{date}}
type: intake
---

# Intake Notes

## Client Information
- **Name**: 
- **Contact**: 
- **Referred by**: 

## Initial Consultation
**Date**: {{date}}
**Duration**: 

### Summary


### Next Steps
- [ ] 
EOF

    cat > "$OBSIDIAN_VAULT_PATH/Templates/Meeting.md" <<'EOF'
---
case-id: 
date: {{date}}
type: meeting
attendees: []
---

# Meeting Notes

**Date**: {{date}}
**Attendees**: 

## Agenda


## Discussion


## Action Items
- [ ] 
EOF

    cat > "$OBSIDIAN_VAULT_PATH/Templates/Evidence.md" <<'EOF'
---
case-id: 
date: {{date}}
type: evidence
evidence-type: 
---

# Evidence Log

**Date Collected**: {{date}}
**Type**: 
**Source**: 

## Description


## Chain of Custody


## Notes

EOF

    info "✓ Created vault structure at $OBSIDIAN_VAULT_PATH"
    
    # Copy setup_obsidian.sh to caseManager if it exists
    local obsidian_setup_source=""
    
    if [[ -f "./setup_obsidian.sh" ]]; then
        obsidian_setup_source="./setup_obsidian.sh"
    elif [[ -f "$HOME/Downloads/setup_obsidian.sh" ]]; then
        obsidian_setup_source="$HOME/Downloads/setup_obsidian.sh"
    elif [[ -f "$CASE_MANAGER_DIR/setup_obsidian.sh" ]]; then
        info "✓ setup_obsidian.sh already in caseManager"
        obsidian_setup_source="$CASE_MANAGER_DIR/setup_obsidian.sh"
    fi
    
    if [[ -n "$obsidian_setup_source" && "$obsidian_setup_source" != "$CASE_MANAGER_DIR/setup_obsidian.sh" ]]; then
        info "Found setup_obsidian.sh at: $obsidian_setup_source"
        cp "$obsidian_setup_source" "$CASE_MANAGER_DIR/setup_obsidian.sh"
        chmod +x "$CASE_MANAGER_DIR/setup_obsidian.sh"
        
        # Update shebang to use Homebrew bash
        if [[ -x "$(brew --prefix)/bin/bash" ]]; then
            local brew_bash="$(brew --prefix)/bin/bash"
            sed -i '' "1s|^#!/usr/bin/env bash|#!${brew_bash}|" "$CASE_MANAGER_DIR/setup_obsidian.sh"
            info "✓ Updated setup_obsidian.sh to use Homebrew bash"
        fi
        
        info "✓ Copied setup_obsidian.sh to $CASE_MANAGER_DIR"
    fi
    
    if [[ ! -f "$CASE_MANAGER_DIR/setup_obsidian.sh" ]]; then
        warn "setup_obsidian.sh not found"
        echo ""
        echo "📋 TO ADD OBSIDIAN SETUP SCRIPT:"
        echo "   1. Place setup_obsidian.sh in: $CASE_MANAGER_DIR"
        echo "   2. Make executable: chmod +x $CASE_MANAGER_DIR/setup_obsidian.sh"
        echo "   3. Run from case manager menu or: cd $CASE_MANAGER_DIR && ./setup_obsidian.sh"
    else
        echo ""
        echo "📋 NEXT STEP: Run setup_obsidian.sh for advanced configuration"
        echo "   Method 1: Type 'cases' and select option 5"
        echo "   Method 2: cd $CASE_MANAGER_DIR && ./setup_obsidian.sh"
    fi
    
    # Copy vault-template.sh if available
    local vault_template_source=""
    
    if [[ -f "./vault-template.sh" ]]; then
        vault_template_source="./vault-template.sh"
    elif [[ -f "$HOME/Downloads/vault-template.sh" ]]; then
        vault_template_source="$HOME/Downloads/vault-template.sh"
    elif [[ -f "$CASE_MANAGER_DIR/vault-template.sh" ]]; then
        info "✓ vault-template.sh already in caseManager"
        vault_template_source="$CASE_MANAGER_DIR/vault-template.sh"
    fi
    
    if [[ -n "$vault_template_source" && "$vault_template_source" != "$CASE_MANAGER_DIR/vault-template.sh" ]]; then
        info "Found vault-template.sh at: $vault_template_source"
        cp "$vault_template_source" "$CASE_MANAGER_DIR/vault-template.sh"
        chmod +x "$CASE_MANAGER_DIR/vault-template.sh"
        
        # Update shebang to use Homebrew bash
        if [[ -x "$(brew --prefix)/bin/bash" ]]; then
            local brew_bash="$(brew --prefix)/bin/bash"
            sed -i '' "1s|^#!/usr/bin/env bash|#!${brew_bash}|" "$CASE_MANAGER_DIR/vault-template.sh"
            info "✓ Updated vault-template.sh to use Homebrew bash"
        fi
        
        info "✓ Copied vault-template.sh to $CASE_MANAGER_DIR"
    fi
}

phase_7_case_manager() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  PHASE 7: CASE MANAGER TOOL"
    echo "╚══════════════════════════════════════════════════════════════╝"
    
    local case_manager_py_path="$CASE_MANAGER_DIR/case_manager.py"
    local case_manager_sh_path="$CASE_MANAGER_DIR/case_manager.sh"
    
    # Check if case_manager.py exists in current directory or ~/Downloads
    local py_source_file=""
    
    if [[ -f "./case_manager.py" ]]; then
        py_source_file="./case_manager.py"
    elif [[ -f "$HOME/Downloads/case_manager.py" ]]; then
        py_source_file="$HOME/Downloads/case_manager.py"
    elif [[ -f "$case_manager_py_path" ]]; then
        info "✓ case_manager.py already at $case_manager_py_path"
        py_source_file="$case_manager_py_path"
    fi
    
    # Copy to caseManager directory if found elsewhere
    if [[ -n "$py_source_file" && "$py_source_file" != "$case_manager_py_path" ]]; then
        info "Found case_manager.py at: $py_source_file"
        info "Copying to: $case_manager_py_path"
        cp "$py_source_file" "$case_manager_py_path"
        chmod +x "$case_manager_py_path"
        info "✓ Copied case_manager.py to $CASE_MANAGER_DIR"
    fi
    
    # Check if case_manager.sh exists and import it
    local sh_source_file=""
    
    if [[ -f "./case_manager.sh" ]]; then
        sh_source_file="./case_manager.sh"
    elif [[ -f "$HOME/Downloads/case_manager.sh" ]]; then
        sh_source_file="$HOME/Downloads/case_manager.sh"
    elif [[ -f "$case_manager_sh_path" ]]; then
        info "✓ case_manager.sh already at $case_manager_sh_path"
        sh_source_file="$case_manager_sh_path"
    fi
    
    if [[ -n "$sh_source_file" && "$sh_source_file" != "$case_manager_sh_path" ]]; then
        info "Found case_manager.sh at: $sh_source_file"
        cp "$sh_source_file" "$case_manager_sh_path"
        chmod +x "$case_manager_sh_path"
        info "✓ Copied case_manager.sh to $CASE_MANAGER_DIR"
    fi
    
    # Verify case_manager.py exists at target location
    if [[ ! -f "$case_manager_py_path" ]]; then
        warn "case_manager.py not found"
        echo ""
        echo "📋 TO INSTALL CASE-MANAGER:"
        echo "   1. Place case_manager.py in: $CASE_MANAGER_DIR"
        echo "   2. Make it executable: chmod +x $CASE_MANAGER_DIR/case_manager.py"
        echo "   3. Install with pipx: pipx install -e $CASE_MANAGER_DIR"
        echo ""
        echo "   Or download from your artifacts and place in $CASE_MANAGER_DIR"
        return 0
    fi
    
    info "Installing case-manager via pipx..."
    
    # Create a minimal setup.py wrapper for pipx
    cat > "$CASE_MANAGER_DIR/setup.py" <<EOF
from setuptools import setup

setup(
    name='case-manager',
    version='1.0.0',
    py_modules=['case_manager'],
    entry_points={
        'console_scripts': [
            'case-manager=case_manager:main',
        ],
    },
    python_requires='>=3.8',
)
EOF
    
    # Ensure pipx is working
    if ! command_exists pipx; then
        warn "pipx not found in PATH, refreshing environment..."
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Install via pipx
    if pipx install -e "$CASE_MANAGER_DIR" --force 2>&1 | tee "$LOG_DIR/case_manager_install.log"; then
        info "✓ case-manager installed successfully"
        info "Location: $case_manager_py_path"
        echo ""
        echo "Usage examples:"
        echo "  case-manager new --id 2026-001 --name 'Client Name'"
        echo "  case-manager list"
        echo "  case-manager open --id 2026-001"
    else
        warn "pipx installation failed"
        echo ""
        echo "You can still use it directly:"
        echo "  python3 $case_manager_py_path new --id 2026-001 --name 'Client Name'"
        echo ""
        echo "Or try manual installation:"
        echo "  cd $CASE_MANAGER_DIR"
        echo "  pipx install -e ."
    fi
}

# ============================================================================
# PHASE 8: UTM + KALI ISO
# ============================================================================

phase_8_utm_kali() {
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "  PHASE 8: UTM & KALI ISO DOWNLOAD"
    echo "════════════════════════════════════════════════════════════════════"
    
    # Install UTM via Homebrew
    if brew list --cask utm &>/dev/null; then
        info "✓ UTM already installed"
    else
        info "Installing UTM..."
        if ! brew_cask_install utm; then
            warn "Failed to install UTM via Homebrew"
            echo ""
            echo "📋 MANUAL STEP:"
            echo "  Download UTM from: https://mac.getutm.app/"
            echo "  Or install from Mac App Store"
            echo ""
            return 0
        fi
    fi
    
    info "✓ UTM installed"
    
    # Detect architecture
    local arch="$(uname -m)"
    local kali_arch=""
    
    if [[ "$arch" == "arm64" ]]; then
        kali_arch="arm64"
        info "Detected Apple Silicon (ARM64)"
    else
        kali_arch="amd64"
        info "Detected Intel (AMD64)"
    fi
    
    # Present Kali version options
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SELECT KALI LINUX VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1) Latest Kali (Recommended)"
    echo "  2) Kali 2024.4"
    echo "  3) Kali 2024.3"
    echo "  4) Kali 2024.2"
    echo "  5) Skip Kali download"
    echo ""
    read -p "Select option [1-5]: " kali_choice
    
    local kali_version=""
    local kali_url=""
    local kali_iso_name=""
    
    case "$kali_choice" in
        1)
            kali_version="2024.4"
            ;;
        2)
            kali_version="2024.4"
            ;;
        3)
            kali_version="2024.3"
            ;;
        4)
            kali_version="2024.2"
            ;;
        5)
            info "Skipping Kali download"
            echo ""
            echo "📋 TO DOWNLOAD KALI MANUALLY:"
            echo "  Visit: https://www.kali.org/get-kali/"
            echo "  Download the installer ISO for your architecture"
            echo "  Then create a VM in UTM using the ISO"
            return 0
            ;;
        *)
            warn "Invalid choice, using latest version (2024.4)"
            kali_version="2024.4"
            ;;
    esac
    
    # Build download URL
    kali_iso_name="kali-linux-${kali_version}-installer-${kali_arch}.iso"
    kali_url="https://cdimage.kali.org/kali-${kali_version}/${kali_iso_name}"
    
    # Create ISO directory
    ensure_dir "$KALI_ISO_DIR"
    
    local kali_iso_path="$KALI_ISO_DIR/$kali_iso_name"
    
    # Check if already downloaded and valid
    if [[ -f "$kali_iso_path" ]]; then
        local file_size=$(stat -f%z "$kali_iso_path" 2>/dev/null || echo "0")
        local min_size=3000000000  # Minimum 3GB
        
        if [[ $file_size -gt $min_size ]]; then
            info "✓ Kali ISO already exists: $kali_iso_path"
            info "  Size: $((file_size / 1048576)) MB"
        else
            warn "Existing ISO is too small ($((file_size / 1048576)) MB), re-downloading..."
            rm -f "$kali_iso_path"
        fi
    fi
    
    # Download if not present or was invalid
    if [[ ! -f "$kali_iso_path" ]]; then
        echo ""
        info "Downloading Kali Linux ${kali_version} (${kali_arch})..."
        info "URL: $kali_url"
        info "This will take 10-30 minutes depending on your connection..."
        info "ISO will be saved to: $kali_iso_path"
        echo ""
        
        # Test URL accessibility first
        info "Testing download URL..."
        if ! curl -I -L --max-time 10 "$kali_url" 2>/dev/null | grep -q "200 OK"; then
            warn "URL test failed. Checking if URL is accessible..."
            warn "Attempting download anyway..."
        fi
        
        # Download with progress and resume capability
        # Using -L to follow redirects, -C - for resume, --fail to catch errors
        if curl -L -C - --fail --progress-bar --retry 3 --retry-delay 5 --max-time 3600 -o "$kali_iso_path" "$kali_url" 2>&1; then
            # Verify download completed
            if [[ -f "$kali_iso_path" ]]; then
                local file_size=$(stat -f%z "$kali_iso_path" 2>/dev/null || echo "0")
                local min_size=3000000000  # Minimum 3GB
                
                if [[ $file_size -gt $min_size ]]; then
                    info "✓ Download complete: $kali_iso_path"
                    info "  Size: $((file_size / 1048576)) MB"
                else
                    warn "Download appears incomplete!"
                    warn "File size: $((file_size / 1048576)) MB (expected >3000 MB)"
                    rm -f "$kali_iso_path"
                    echo ""
                    echo "📋 MANUAL DOWNLOAD REQUIRED:"
                    echo "  1. Visit: https://www.kali.org/get-kali/"
                    echo "  2. Download: $kali_iso_name"
                    echo "  3. Save to: $KALI_ISO_DIR"
                    echo ""
                    echo "  Or try direct download:"
                    echo "  curl -L -o '$kali_iso_path' '$kali_url'"
                    return 0
                fi
            else
                warn "Download failed - file not created"
                echo ""
                echo "📋 MANUAL DOWNLOAD:"
                echo "  Visit: https://www.kali.org/get-kali/"
                echo "  Download: $kali_iso_name"
                echo "  Save to: $KALI_ISO_DIR"
                return 0
            fi
        else
            local curl_exit=$?
            warn "Download failed with curl exit code: $curl_exit"
            rm -f "$kali_iso_path"
            echo ""
            echo "📋 TROUBLESHOOTING:"
            echo "  • Check your internet connection"
            echo "  • Verify the URL is accessible:"
            echo "    $kali_url"
            echo ""
            echo "📋 Opening browser to Kali download page..."
            
            # Open default browser to Kali downloads
            if command_exists open; then
                open "https://www.kali.org/get-kali/#kali-installer-images"
                info "✓ Browser opened to Kali download page"
            fi
            
            echo ""
            echo "MANUAL DOWNLOAD INSTRUCTIONS:"
            echo "  1. On the Kali download page that just opened:"
            echo "  2. Look for 'Installer Images' section"
            echo "  3. Download: $kali_iso_name"
            echo "  4. Move the downloaded ISO to: $KALI_ISO_DIR"
            echo ""
            echo "  Or try wget if available:"
            echo "  wget -O '$kali_iso_path' '$kali_url'"
            echo ""
            echo "  After manual download, you can continue with UTM setup"
            return 0
        fi
    fi
    
    # Create instructions for UTM setup
    KALI_FINAL_MESSAGE=$(cat <<EOF

════════════════════════════════════════════════════════════════════
  ✅ KALI ISO READY - NEXT STEPS
════════════════════════════════════════════════════════════════════

📁 Kali ISO Location:
   $kali_iso_path

🖥️  CREATE VM IN UTM:
   1. Open UTM application
   2. Click "+" or "Create a New Virtual Machine"
   3. Select "Virtualize" (for ARM) or "Emulate" (for Intel)
   4. Choose "Linux"
   5. Select "Use ISO Boot Image"
   6. Browse to: $KALI_ISO_DIR
   7. Select: $kali_iso_name
   8. Configure:
      • Memory: 4GB minimum (8GB recommended)
      • CPU Cores: 2-4 cores
      • Storage: 50GB minimum
   9. Complete setup and start the VM
   10. Follow Kali installation wizard

🔑 DEFAULT CREDENTIALS (during installation):
   Create your own username/password during setup

📚 DOCUMENTATION:
   • UTM Guide: https://docs.getutm.app/
   • Kali Docs: https://www.kali.org/docs/

EOF
)
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo "════════════════════════════════════════════════════════════════════"
    echo "  macOS Bootstrap Script"
    echo "  Log: $LOG_FILE"
    echo "════════════════════════════════════════════════════════════════════"
    
    phase_0_preflight
    phase_1_nordvpn
    phase_2_xcode_clt
    phase_3_homebrew
    phase_4_core_tools
    phase_5_gui_apps
    phase_6_obsidian_vault
    phase_7_case_manager
    phase_8_utm_kali
    move_investigation_setup_repo
    
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "  ✅ BOOTSTRAP COMPLETE"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 SUMMARY:"
    echo "  ✓ Tools directory: $TOOLS_DIR"
    echo "  ✓ Obsidian vault: $OBSIDIAN_VAULT_PATH"
    echo "  ✓ Python: $(python --version 2>/dev/null || echo 'Not in current shell')"
    echo "  ✓ Homebrew: $(brew --version | head -n1)"
    echo "  ✓ Interactive case manager: $TOOLS_DIR/case-manager.sh"
    echo ""
    echo "📝 REQUIRED MANUAL STEPS:"
    echo "  1. Open NordVPN and sign in"
    echo "  2. Place case_manager.py in $TOOLS_DIR (if not already done)"
    echo "  3. Place vault-template.sh in $TOOLS_DIR (if not already done)"
    echo "  4. Sign in to GitHub CLI: gh auth login"
    echo "  5. Create UTM VM using Kali ISO at: $KALI_ISO_DIR/$KALI_ISO_NAME"
    echo ""
    echo "🚀 QUICK START:"
    echo "  • Reload your shell: source ~/.zprofile"
    echo "  • Launch case manager: cases"
    echo "  • Manage vault templates: vault-templates"
    echo "  • Or run directly: cd ~/Tools && ./case-manager.sh"
    echo ""
    echo "🔧 CONFIGURE OBSIDIAN:"
    if [[ -x "$(brew --prefix)/bin/bash" ]]; then
        echo "  • Run: $(brew --prefix)/bin/bash ~/Tools/setup_obsidian.sh"
    else
        echo "  • Run: bash ~/Tools/setup_obsidian.sh"
    fi
    echo "  • Or from case manager menu: cases → option 5"
    echo ""
    echo "💡 CASE MANAGER FEATURES:"
    echo "  • Interactive menu system with auto-generated case IDs"
    echo "  • Open cases directly in Obsidian"
    echo "  • Save/apply vault templates for consistent setup"
    echo "  • List and search cases"
    echo "  • Case statistics dashboard"
    echo ""
    echo "📄 Full log: $LOG_FILE"
    echo "════════════════════════════════════════════════════════════════════"
    if [[ -n "${KALI_FINAL_MESSAGE:-}" ]]; then
        echo "$KALI_FINAL_MESSAGE"
    fi

        echo "📄 Full log: $LOG_FILE"
        echo "════════════════════════════════════════════════════════════════════"
}



main "$@"