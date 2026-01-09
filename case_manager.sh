#!/usr/bin/env bash
#
# case-manager.sh - Interactive Case Management System
#
# Creates and manages cases inside an Obsidian vault.
# Supports "Obsidian Source Case" replication:
#   - Select ANY existing case that already has a .obsidian/ folder
#   - Automatically copy that .obsidian/ (+ Templates/) into new and existing cases
#
# Usage: ./case-manager.sh (or alias "cases")
#

set -euo pipefail

TOOLS_DIR="${TOOLS_DIR:-$HOME/Tools}"
CASE_MANAGER_DIR="${CASE_MANAGER_DIR:-$TOOLS_DIR/caseManager}"
CASE_MANAGER_PY="${CASE_MANAGER_PY:-$CASE_MANAGER_DIR/case_manager.py}"
OBSIDIAN_VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/ObsidianVault}"
CASE_ROOT_DIR="${CASE_ROOT_DIR:-$OBSIDIAN_VAULT/Cases}"
SOP_BUILDER="${SOP_BUILDER:-$CASE_MANAGER_DIR/setup_case_sops.py}"

# Persistent file that records which case is the current .obsidian source
OBSIDIAN_SOURCE_FILE="${OBSIDIAN_SOURCE_FILE:-$HOME/.case_manager_obsidian_source}"

# Allow overriding the python interpreter (useful with pyenv/pipx)
PYTHON_BIN="${PYTHON_BIN:-python3}"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

clear_screen() {
    clear
    echo ""
}

info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}              CASE MANAGEMENT SYSTEM${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              Professional Workflow Manager                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD} $*${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_divider() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
}

pause() {
    echo ""
    read -r -p "$(echo -e "${DIM}Press Enter to continue...${NC}")"
}

confirm() {
    local prompt="$1"
    local response
    read -r -p "$(echo -e "${YELLOW}$prompt (y/n):${NC} ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

show_vault_info() {
    echo -e "${DIM}📂 Current Directory: $(pwd)${NC}"
    echo -e "${DIM}📁 Vault Location: $OBSIDIAN_VAULT${NC}"

    if [[ -d "$CASE_ROOT_DIR" ]]; then
        local case_count
        case_count=$(find "$CASE_ROOT_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        case_count=$((case_count - 1))
        if [[ $case_count -gt 0 ]]; then
            echo -e "${DIM}📊 Total Cases: $case_count${NC}"
        fi
    fi

    local src
    if src="$(get_obsidian_source_dir 2>/dev/null)"; then
        echo -e "${DIM}🧩 Obsidian Source: $(basename "$src")${NC}"
    else
        echo -e "${DIM}🧩 Obsidian Source: (not set)${NC}"
    fi
}

# ---------------------------------------------------------------------------
# Obsidian Source Case replication
# ---------------------------------------------------------------------------

find_case_dir_by_id() {
    local case_id="$1"

    # Prefer exact "<id> - <name>" convention
    if [[ -d "$CASE_ROOT_DIR" ]]; then
        find "$CASE_ROOT_DIR" -maxdepth 1 -type d \( -name "${case_id} -*" -o -name "${case_id}-*" -o -name "${case_id}*" \) \
            -print -quit 2>/dev/null || true
    fi
}

set_obsidian_source_from_case() {
    local case_id="$1"
    local src_dir
    src_dir="$(find_case_dir_by_id "$case_id")"

    if [[ -z "$src_dir" || ! -d "$src_dir" ]]; then
        error "Could not find a case folder for: $case_id"
        echo -e "${DIM}Looked under: $CASE_ROOT_DIR${NC}"
        return 1
    fi

    if [[ ! -d "$src_dir/.obsidian" ]]; then
        error "Case '$case_id' does not contain a .obsidian folder."
        echo -e "${DIM}Path: $src_dir${NC}"
        echo ""
        echo "To create it: open Obsidian → 'Open folder as vault' → select that case folder once."
        return 1
    fi

    printf "%s" "$src_dir" > "$OBSIDIAN_SOURCE_FILE"
    success "Obsidian source set to case: $case_id"
    echo -e "${DIM}Source path: $src_dir${NC}"
    return 0
}

get_obsidian_source_dir() {
    if [[ -f "$OBSIDIAN_SOURCE_FILE" ]]; then
        local src
        src="$(cat "$OBSIDIAN_SOURCE_FILE" 2>/dev/null || true)"
        if [[ -n "$src" && -d "$src/.obsidian" ]]; then
            echo "$src"
            return 0
        fi
    fi
    return 1
}

apply_obsidian_from_source_to_case_dir() {
    local target_dir="$1"

    if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
        error "Target folder does not exist: $target_dir"
        return 1
    fi

    local src_dir
    if ! src_dir="$(get_obsidian_source_dir)"; then
        warn "No Obsidian source case set."
        echo "Set one first: Configure Obsidian → 'Set Obsidian source from a case'"
        return 1
    fi

    info "Applying Obsidian config"
    echo -e "${DIM}From: $src_dir${NC}"
    echo -e "${DIM}To:   $target_dir${NC}"

    # Backup existing .obsidian (safe & repeatable)
    if [[ -d "$target_dir/.obsidian" ]]; then
        local backup="$target_dir/.obsidian.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target_dir/.obsidian" "$backup"
        warn "Backed up existing .obsidian to: $(basename "$backup")"
    fi

    cp -R "$src_dir/.obsidian" "$target_dir/"

    # Copy Templates if present in the source case
    if [[ -d "$src_dir/Templates" ]]; then
        mkdir -p "$target_dir/Templates"
        cp -R "$src_dir/Templates/"* "$target_dir/Templates/" 2>/dev/null || true
    fi

    # Ensure a couple of useful dirs exist
    mkdir -p "$target_dir/Attachments" 2>/dev/null || true

    success "Applied .obsidian (and Templates if available)"
    return 0
}

apply_obsidian_from_source_to_case_id() {
    local target_case_id="$1"
    local target_dir
    target_dir="$(find_case_dir_by_id "$target_case_id")"

    if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
        error "Could not find target case folder for: $target_case_id"
        return 1
    fi

    apply_obsidian_from_source_to_case_dir "$target_dir"
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_banner() {
    clear_screen
    print_header
    echo ""
    show_vault_info
    echo ""
}


show_menu() {
    echo -e "${GREEN}${BOLD}Main Menu:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Create New Case${NC}"
    echo -e "     ${DIM}→ Guided wizard to set up a new case${NC}"
    echo ""
    echo -e "  ${CYAN}2)${NC} ${BOLD}List All Cases${NC}"
    echo -e "     ${DIM}→ View all cases with filtering options${NC}"
    echo ""
    echo -e "  ${CYAN}3)${NC} ${BOLD}Open Existing Case${NC}"
    echo -e "     ${DIM}→ Open case folder in Finder${NC}"
    echo ""
    echo -e "  ${CYAN}4)${NC} ${BOLD}Search Cases${NC}"
    echo -e "     ${DIM}→ Find cases by ID, name, or keyword${NC}"
    echo ""
    echo -e "  ${CYAN}5)${NC} ${BOLD}Generate SOPs${NC}"
    echo -e "     ${DIM}→ Standard Operating Procedures${NC}"
    echo ""
    echo -e "  ${CYAN}6)${NC} ${BOLD}Configure Obsidian${NC}"
    echo -e "     ${DIM}→ Setup wizard + Source Case replication${NC}"
    echo ""
    echo -e "  ${CYAN}7)${NC} ${BOLD}Case Statistics${NC}"
    echo -e "     ${DIM}→ View dashboard with case metrics${NC}"
    echo ""
    echo -e "  ${CYAN}8)${NC} ${BOLD}Quick Actions${NC}"
    echo -e "     ${DIM}→ Open vault, templates, or folders${NC}"
    echo ""
    echo -e "  ${CYAN}9)${NC} ${BOLD}Help & Documentation${NC}"
    echo -e "     ${DIM}→ Comprehensive guide and tips${NC}"
    echo ""
    echo -e "  ${CYAN}10)${NC} ${BOLD}Exit${NC}"
    echo ""
    print_divider
}

# ============================================================================
# CASE CREATION WIZARD
# ============================================================================

create_new_case() {
    clear_screen
    print_header
    print_section "CREATE NEW CASE - Step-by-Step Wizard"

    echo -e "${BOLD}This wizard will guide you through creating a new case.${NC}"
    echo -e "${DIM}You'll provide: Case ID and Name${NC}"
    echo ""

    if ! confirm "Ready to create a new case?"; then
        warn "Case creation cancelled"
        pause
        return
    fi

    # Step 1: Case ID
    clear_screen
    print_header
    echo ""
    echo -e "${GREEN}${BOLD}Step 1 of 3: Case ID${NC}"
    print_divider
    echo ""
    echo "The Case ID is a unique identifier for this case."
    echo ""
    echo -e "${CYAN}Recommended formats:${NC}"
    echo "  • YYYY-NNN  (Year-based: 2026-001, 2026-002)"
    echo "  • INV-NNN   (Investigation: INV-042)"
    echo "  • CASE-NNN  (Generic: CASE-123)"
    echo "  • LIT-NNN   (Litigation: LIT-456)"
    echo ""

    local case_id
    while true; do
        read -r -p "$(echo -e "${BOLD}Enter Case ID:${NC} ")" case_id

        if [[ -z "$case_id" ]]; then
            error "Case ID cannot be empty"
            echo ""
            continue
        fi

        if [[ ! "$case_id" =~ ^[A-Z0-9]+-[A-Z0-9]+$ ]]; then
            error "Invalid format. Use: PREFIX-NUMBER (e.g., 2026-001)"
            echo ""
            continue
        fi

        if [[ -d "$CASE_ROOT_DIR" ]] && find "$CASE_ROOT_DIR" -maxdepth 1 -type d -name "${case_id} -*" 2>/dev/null | grep -q .; then
            error "Case ID '$case_id' already exists"
            echo ""
            if confirm "Open existing case in Finder?"; then
                "$PYTHON_BIN" "$CASE_MANAGER_PY" open --id "$case_id" --finder
                pause
                return
            fi
            echo ""
            continue
        fi

        success "Valid Case ID: $case_id"
        break
    done

    # Step 2: Case Name
    clear_screen
    print_header
    echo ""
    echo -e "${GREEN}${BOLD}Step 2 of 3: Case Name${NC}"
    print_divider
    echo ""
    echo "The Case Name is a descriptive title for this case."
    echo ""

    local case_name
    while true; do
        read -r -p "$(echo -e "${BOLD}Enter Case Name:${NC} ")" case_name

        if [[ -z "$case_name" ]]; then
            error "Case name cannot be empty"
            echo ""
            continue
        fi

        if [[ ${#case_name} -lt 5 ]]; then
            warn "Case name is very short. Consider a more descriptive name."
            if ! confirm "Continue with '$case_name'?"; then
                echo ""
                continue
            fi
        fi

        success "Case Name: $case_name"
        break
    done

    # Step 3: Confirmation
    clear_screen
    print_header
    echo ""
    echo -e "${GREEN}${BOLD}Step 3 of 3: Review & Confirm${NC}"
    print_divider
    echo ""
    echo -e "${BOLD}Please review the case details:${NC}"
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}Case ID:${NC}      $case_id"
    echo -e "${CYAN}│${NC} ${BOLD}Case Name:${NC}    $case_name"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    if ! confirm "Create this case?"; then
        warn "Case creation cancelled"
        pause
        return
    fi

    # Create the case
    clear_screen
    print_header
    print_section "Creating Case..."

    info "Generating case structure..."

    if "$PYTHON_BIN" "$CASE_MANAGER_PY" new --id "$case_id" --name "$case_name" 2>&1; then
        echo ""
        success "Case created successfully!"

        # Automatically apply .obsidian from selected source (if set)
        if get_obsidian_source_dir >/dev/null 2>&1; then
            echo ""
            info "Applying Obsidian configuration from your Source Case..."
            apply_obsidian_from_source_to_case_id "$case_id" || warn "Could not apply source .obsidian to new case (see message above)."
        else
            echo ""
            warn "No Obsidian Source Case is set. New case will not get a per-case .obsidian automatically."
            if confirm "Set an Obsidian Source Case now?"; then
                local src_id
                read -r -p "Enter source Case ID (must already have .obsidian), e.g. 2026-001: " src_id
                if [[ -n "$src_id" ]]; then
                    set_obsidian_source_from_case "$src_id" || true
                    if get_obsidian_source_dir >/dev/null 2>&1; then
                        apply_obsidian_from_source_to_case_id "$case_id" || true
                    fi
                fi
            fi
        fi

        echo ""
        print_divider
        echo ""
        echo -e "${BOLD}What's next?${NC}"
        echo ""
        echo "  1️⃣  Open case in Finder"
        echo "  2️⃣  Open the case folder as a vault (if using per-case vaults)"
        echo "  3️⃣  Start with Intake Notes"
        echo "  4️⃣  Use templates for documentation"
        echo ""

        if confirm "Open case folder in Finder now?"; then
            "$PYTHON_BIN" "$CASE_MANAGER_PY" open --id "$case_id" --finder
        fi

        if confirm "Open Obsidian now?"; then
            open -a Obsidian "$OBSIDIAN_VAULT" 2>/dev/null || true
        fi
    else
        echo ""
        error "Failed to create case"
    fi

    pause
}

# ============================================================================
# LIST CASES
# ============================================================================

list_cases() {
    clear_screen
    print_header
    print_section "ALL CASES"

    echo "Filter cases by status:"
    echo ""
    echo -e "  ${CYAN}1)${NC} All cases"
    echo -e "  ${CYAN}2)${NC} 🟢 Active only"
    echo -e "  ${CYAN}3)${NC} 🔴 Closed only"
    echo -e "  ${CYAN}4)${NC} 🟠 Pending only"
    echo ""

    local filter_choice
    read -r -p "$(echo -e "${BOLD}Select filter (1-4):${NC} ")" filter_choice

    echo ""
    print_divider
    echo ""

    case $filter_choice in
        2)
            info "Showing active cases only..."
            echo ""
            "$PYTHON_BIN" "$CASE_MANAGER_PY" list --status active
            ;;
        3)
            info "Showing closed cases only..."
            echo ""
            "$PYTHON_BIN" "$CASE_MANAGER_PY" list --status closed
            ;;
        4)
            info "Showing pending cases only..."
            echo ""
            "$PYTHON_BIN" "$CASE_MANAGER_PY" list --status pending
            ;;
        *)
            info "Showing all cases..."
            echo ""
            "$PYTHON_BIN" "$CASE_MANAGER_PY" list
            ;;
    esac

    pause
}

# ============================================================================
# OPEN CASE
# ============================================================================

open_case() {
    clear_screen
    print_header
    print_section "OPEN CASE"

    echo "Enter the Case ID to open its folder."
    echo ""

    local case_id
    read -r -p "$(echo -e "${BOLD}Enter Case ID:${NC} ")" case_id

    if [[ -z "$case_id" ]]; then
        warn "No Case ID provided"
        pause
        return
    fi

    echo ""
    info "Opening case: $case_id..."
    echo ""

    if "$PYTHON_BIN" "$CASE_MANAGER_PY" open --id "$case_id" --finder; then
        success "Case opened in Finder"
    else
        error "Case not found: $case_id"
    fi

    pause
}

# ============================================================================
# SEARCH CASES
# ============================================================================

search_cases() {
    clear_screen
    print_header
    print_section "SEARCH CASES"

    echo "Search for cases by ID, name, or any keyword."
    echo ""

    local search_term
    read -r -p "$(echo -e "${BOLD}Enter search term:${NC} ")" search_term

    if [[ -z "$search_term" ]]; then
        warn "No search term provided"
        pause
        return
    fi

    echo ""
    print_divider
    info "Searching for: '$search_term'..."
    echo ""

    if "$PYTHON_BIN" "$CASE_MANAGER_PY" list 2>/dev/null | grep -i "$search_term"; then
        echo ""
        success "Found matching cases above"
    else
        warn "No cases found matching '$search_term'"
    fi

    pause
}

# ============================================================================
# CONFIGURE OBSIDIAN
# ============================================================================

configure_obsidian() {
    while true; do
        clear_screen
        print_header
        print_section "OBSIDIAN CONFIGURATION"

        local src
        if src="$(get_obsidian_source_dir 2>/dev/null)"; then
            echo -e "${DIM}Current Source Case Vault: $src${NC}"
        else
            echo -e "${DIM}Current Source Case Vault: (not set)${NC}"
        fi

        echo ""
        echo -e "${GREEN}${BOLD}Options:${NC}"
        echo ""
        echo -e "  ${CYAN}1)${NC} Run Obsidian setup wizard (setup_obsidian.sh)"
        echo -e "  ${CYAN}2)${NC} Set Obsidian Source from an existing case (must have .obsidian)"
        echo -e "  ${CYAN}3)${NC} Apply Source to an existing case"
        echo -e "  ${CYAN}4)${NC} Clear Source selection"
        echo -e "  ${CYAN}5)${NC} Back"
        echo ""
        print_divider

        local choice
        read -r -p "$(echo -e "${BOLD}Select option (1-5):${NC} ")" choice

        case $choice in
            1)
                clear_screen
                print_header
                print_section "OBSIDIAN SETUP WIZARD"

                if [[ ! -f "$TOOLS_DIR/setup_obsidian.sh" ]]; then
                    error "setup_obsidian.sh not found in $TOOLS_DIR"
                    pause
                    continue
                fi

                if ! confirm "Launch Obsidian setup wizard?"; then
                    warn "Setup cancelled"
                    pause
                    continue
                fi

                info "Launching wizard..."
                sleep 1

                local bash_cmd="bash"
                if command -v brew >/dev/null 2>&1 && [[ -x "$(brew --prefix)/bin/bash" ]]; then
                    bash_cmd="$(brew --prefix)/bin/bash"
                fi

                "$bash_cmd" "$TOOLS_DIR/setup_obsidian.sh"
                pause
                ;;
            2)
                clear_screen
                print_header
                print_section "SET SOURCE CASE"

                echo "Enter a Case ID that ALREADY has a .obsidian folder."
                echo -e "${DIM}Example: 2026-001${NC}"
                echo ""
                local cid
                read -r -p "Case ID: " cid
                if [[ -z "$cid" ]]; then
                    warn "No Case ID provided"
                    pause
                    continue
                fi
                set_obsidian_source_from_case "$cid" || true
                pause
                ;;
            3)
                clear_screen
                print_header
                print_section "APPLY SOURCE TO CASE"

                if ! get_obsidian_source_dir >/dev/null 2>&1; then
                    warn "No source set. Choose option 2 first."
                    pause
                    continue
                fi

                echo "Apply the current source .obsidian to another case."
                echo ""
                local tid
                read -r -p "Target Case ID: " tid
                if [[ -z "$tid" ]]; then
                    warn "No target Case ID provided"
                    pause
                    continue
                fi
                apply_obsidian_from_source_to_case_id "$tid" || true
                pause
                ;;
            4)
                rm -f "$OBSIDIAN_SOURCE_FILE" 2>/dev/null || true
                success "Cleared Obsidian Source selection"
                pause
                ;;
            5)
                return
                ;;
            *)
                error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# CASE STATISTICS (kept simple)
# ============================================================================

show_statistics() {
    clear_screen
    print_header
    print_section "CASE STATISTICS DASHBOARD"

    if [[ ! -d "$CASE_ROOT_DIR" ]]; then
        warn "Cases directory not found at $CASE_ROOT_DIR"
        pause
        return
    fi

    local total
    total=$(find "$CASE_ROOT_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    total=$((total - 1))

    echo -e "${BOLD}Total Cases:${NC} $total"
    echo ""

    if [[ $total -le 0 ]]; then
        info "No cases created yet."
        pause
        return
    fi

    print_divider
    echo -e "${BOLD}Recent Cases (Last 5):${NC}"
    echo ""

    local count=1
    if [[ -d "$CASE_ROOT_DIR" ]]; then
        for case_folder in $(ls -t "$CASE_ROOT_DIR" 2>/dev/null | head -5); do
            [[ -d "$CASE_ROOT_DIR/$case_folder" ]] || continue
            echo "  $count. $case_folder"
            count=$((count + 1))
        done
    fi

    pause
}

# ============================================================================
# QUICK ACTIONS
# ============================================================================

quick_actions() {
    clear_screen
    print_header
    print_section "QUICK ACTIONS"

    echo "Select a quick action:"
    echo ""
    echo -e "  ${CYAN}1)${NC} Open Obsidian Vault"
    echo -e "  ${CYAN}2)${NC} Open Templates Folder"
    echo -e "  ${CYAN}3)${NC} Open Cases Folder in Finder"
    echo -e "  ${CYAN}4)${NC} Open Tools Directory"
    echo -e "  ${CYAN}5)${NC} Back"
    echo ""

    local choice
    read -r -p "$(echo -e "${BOLD}Select action (1-5):${NC} ")" choice

    case $choice in
        1) open -a Obsidian "$OBSIDIAN_VAULT" 2>/dev/null || error "Obsidian not found" ;;
        2) open "$OBSIDIAN_VAULT/Templates" 2>/dev/null || error "Templates folder not found" ;;
        3) open "$CASE_ROOT_DIR" 2>/dev/null || error "Cases folder not found" ;;
        4) open "$TOOLS_DIR" 2>/dev/null || error "Tools folder not found" ;;
        5) return ;;
        *) error "Invalid choice" ;;
    esac

    pause
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    clear_screen
    print_header
    print_section "HELP & DOCUMENTATION"

    echo -e "${BOLD}Obsidian Source Case replication${NC}"
    echo ""
    echo "You can make each case its own Obsidian vault by copying .obsidian from a source case."
    echo ""
    echo "Workflow:"
    echo "  1) Create/configure ONE case vault in Obsidian so it contains .obsidian/"
    echo "  2) Configure Obsidian → Set Source from that case ID"
    echo "  3) New cases will auto-receive .obsidian/ + Templates/"
    echo "  4) You can also apply Source to any existing case"
    echo ""

    print_divider
    echo "Python CLI:" 
    echo "  $PYTHON_BIN $CASE_MANAGER_PY new --id 2026-001 --name 'Client Name'"
    echo "  $PYTHON_BIN $CASE_MANAGER_PY list"
    echo "  $PYTHON_BIN $CASE_MANAGER_PY open --id 2026-001 --finder"

    pause
}

# ============================================================================
# SOP Generation - Enhanced Menu System
# ============================================================================

generate_sops_menu() {
    while true; do
        clear_screen
        print_header
        print_section "SOP GENERATION"

        echo -e "${GREEN}${BOLD}SOP Builder Options:${NC}"
        echo ""
        echo -e "  ${CYAN}1)${NC} ${BOLD}Generate SOPs for New Case (Auto)${NC}"
        echo -e "     ${DIM}→ Quick, Standard, or Comprehensive profiles${NC}"
        echo ""
        echo -e "  ${CYAN}2)${NC} ${BOLD}Generate SOPs for Existing Case${NC}"
        echo -e "     ${DIM}→ Add SOPs to a case that doesn't have them${NC}"
        echo ""
        echo -e "  ${CYAN}3)${NC} ${BOLD}Custom SOP Selection${NC}"
        echo -e "     ${DIM}→ Choose specific SOPs to generate${NC}"
        echo ""
        echo -e "  ${CYAN}4)${NC} ${BOLD}View Available SOPs${NC}"
        echo -e "     ${DIM}→ List all available SOP modules${NC}"
        echo ""
        echo -e "  ${CYAN}5)${NC} ${BOLD}View SOP Profiles${NC}"
        echo -e "     ${DIM}→ See predefined SOP combinations${NC}"
        echo ""
        echo -e "  ${CYAN}6)${NC} ${BOLD}Back to Main Menu${NC}"
        echo ""
        print_divider

        local choice
        read -r -p "$(echo -e "${BOLD}Select option (1-6):${NC} ")" choice

        case $choice in
            1) generate_sops_auto ;;
            2) generate_sops_existing_case ;;
            3) generate_sops_custom ;;
            4) list_available_sops ;;
            5) list_sop_profiles ;;
            6) return ;;
            *) error "Invalid option"; sleep 1 ;;
        esac
    done
}

# ============================================================================
# Auto-generate SOPs with Profile Selection
# ============================================================================

generate_sops_auto() {
    clear_screen
    print_header
    print_section "GENERATE SOPs - PROFILE SELECTION"

    echo -e "${BOLD}Select an SOP profile for this case:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Quick Start${NC}"
    echo -e "     ${DIM}Essential SOPs: Intake, Evidence, Reporting${NC}"
    echo -e "     ${DIM}Best for: Simple investigations, quick turnaround${NC}"
    echo ""
    echo -e "  ${CYAN}2)${NC} ${BOLD}Standard Investigation${NC} ⭐ ${YELLOW}Recommended${NC}"
    echo -e "     ${DIM}Core SOPs: Intake, Evidence, Person, Social Media, Reporting${NC}"
    echo -e "     ${DIM}Best for: Most investigations${NC}"
    echo ""
    echo -e "  ${CYAN}3)${NC} ${BOLD}Comprehensive Suite${NC}"
    echo -e "     ${DIM}All available SOPs${NC}"
    echo -e "     ${DIM}Best for: Complex, long-term investigations${NC}"
    echo ""
    echo -e "  ${CYAN}4)${NC} ${BOLD}Person-Focused${NC}"
    echo -e "     ${DIM}Person investigation emphasis${NC}"
    echo -e "     ${DIM}Best for: Background checks, person of interest${NC}"
    echo ""
    echo -e "  ${CYAN}5)${NC} ${BOLD}Company-Focused${NC}"
    echo -e "     ${DIM}Business/organization investigation${NC}"
    echo -e "     ${DIM}Best for: Due diligence, corporate research${NC}"
    echo ""
    echo -e "  ${CYAN}6)${NC} ${BOLD}Cancel${NC}"
    echo ""
    print_divider

    local profile_choice
    read -r -p "$(echo -e "${BOLD}Select profile (1-6):${NC} ")" profile_choice

    local profile=""
    case $profile_choice in
        1) profile="quick" ;;
        2) profile="standard" ;;
        3) profile="comprehensive" ;;
        4) profile="person" ;;
        5) profile="company" ;;
        6) return ;;
        *) 
            error "Invalid selection, using standard profile"
            profile="standard"
            sleep 2
            ;;
    esac

    # This function is called DURING case creation in create_new_case()
    # The calling function should pass the case directory
    # For now, we'll return the profile choice
    echo "$profile"
}

# ============================================================================
# Generate SOPs for Existing Case
# ============================================================================

generate_sops_existing_case() {
    clear_screen
    print_header
    print_section "GENERATE SOPs FOR EXISTING CASE"

    echo "Available Cases:"
    echo ""
    
    if [[ ! -d "$CASE_ROOT_DIR" ]]; then
        error "Cases directory not found"
        pause
        return
    fi
    
    # Build array of case directories (exclude the Cases folder itself)
    local case_dirs=()
    local count=1
    
    # Use a simpler approach - just iterate through directories
    for case_path in "$CASE_ROOT_DIR"/*; do
        # Skip if not a directory
        [[ -d "$case_path" ]] || continue
        
        # Get just the folder name
        local case_name=$(basename "$case_path")
        
        # Add to array
        case_dirs+=("$case_path")
        
        # Print with color codes
        echo -e "  ${CYAN}$count)${NC} $case_name"
        count=$((count + 1))
    done
    
    if [[ ${#case_dirs[@]} -eq 0 ]]; then
        warn "No cases found"
        pause
        return
    fi
    
    echo ""
    local case_num
    read -r -p "$(echo -e "${BOLD}Select case number:${NC} ")" case_num
    
    # Validate input
    if [[ ! "$case_num" =~ ^[0-9]+$ ]] || [[ $case_num -lt 1 ]] || [[ $case_num -gt ${#case_dirs[@]} ]]; then
        error "Invalid selection"
        pause
        return
    fi
    
    # Get selected case (subtract 1 for zero-based array)
    local case_dir="${case_dirs[$((case_num - 1))]}"

    echo ""
    info "Selected: $(basename "$case_dir")"
    echo ""

    # Check if SOPs already exist
    if [[ -d "$case_dir/04 - SOPs" ]] && [[ -n "$(ls -A "$case_dir/04 - SOPs" 2>/dev/null)" ]]; then
        warn "SOPs folder already contains files"
        echo ""
        if ! confirm "Continue and potentially overwrite existing SOPs?"; then
            info "Cancelled"
            pause
            return
        fi
    fi

    # Check if SOP builder exists
    if [[ ! -f "$SOP_BUILDER" ]]; then
        error "SOP builder not found at: $SOP_BUILDER"
        pause
        return
    fi

    # Select profile
    echo ""
    echo "Select SOP profile:"
    echo "  1) Quick Start"
    echo "  2) Standard (Recommended)"
    echo "  3) Comprehensive"
    echo "  4) Person-Focused"
    echo "  5) Company-Focused"
    echo ""

    local profile_num
    read -r -p "Select (1-5): " profile_num

    local profile="standard"
    case $profile_num in
        1) profile="quick" ;;
        2) profile="standard" ;;
        3) profile="comprehensive" ;;
        4) profile="person" ;;
        5) profile="company" ;;
    esac

    # Generate SOPs
    echo ""
    info "Generating SOPs with '$profile' profile..."
    echo ""

    if "$PYTHON_BIN" "$SOP_BUILDER" --case-dir "$case_dir" --profile "$profile"; then
        success "SOPs generated successfully!"
        echo ""
        if confirm "Open SOPs folder in Finder?"; then
            open "$case_dir/04 - SOPs"
        fi
    else
        error "Failed to generate SOPs"
    fi

    pause
}

# ============================================================================
# Custom SOP Selection
# ============================================================================

generate_sops_custom() {
    clear_screen
    print_header
    print_section "CUSTOM SOP SELECTION"

    # Check if SOP builder exists
    if [[ ! -f "$SOP_BUILDER" ]]; then
        error "SOP builder not found at: $SOP_BUILDER"
        pause
        return
    fi

    # Show list of available cases
    echo "Available Cases:"
    echo ""
    
    if [[ ! -d "$CASE_ROOT_DIR" ]]; then
        error "Cases directory not found"
        pause
        return
    fi
    
    local case_dirs=()
    local count=1
    
    # Iterate through directories
    for case_path in "$CASE_ROOT_DIR"/*; do
        [[ -d "$case_path" ]] || continue
        
        local case_name=$(basename "$case_path")
        case_dirs+=("$case_path")
        
        echo -e "  ${CYAN}$count)${NC} $case_name"
        count=$((count + 1))
    done
    
    if [[ ${#case_dirs[@]} -eq 0 ]]; then
        warn "No cases found"
        pause
        return
    fi
    
    echo ""
    local case_num
    read -r -p "$(echo -e "${BOLD}Select case number:${NC} ")" case_num
    
    if [[ ! "$case_num" =~ ^[0-9]+$ ]] || [[ $case_num -lt 1 ]] || [[ $case_num -gt ${#case_dirs[@]} ]]; then
        error "Invalid selection"
        pause
        return
    fi
    
    local selected_case="${case_dirs[$((case_num - 1))]}"
    
    echo ""
    info "Selected: $(basename "$selected_case")"
    
    # Show available modules with numbers
    echo ""
    echo "Available SOP Modules:"
    echo ""
    
    # Manually list modules with clean numbers
    echo "BASIC:"
    echo "  1. case-intake          - Case Intake & Scope Definition"
    echo "  2. evidence-handling    - Digital Evidence Collection & Preservation"
    echo "  3. reporting            - Investigation Reporting"
    echo ""
    echo "INTERMEDIATE:"
    echo "  4. company-investigation - Company & Organization Investigation"
    echo "  5. person-investigation - Person Investigation (OSINT)"
    echo "  6. social-media         - Social Media Investigation"
    echo ""
    echo "ADVANCED:"
    echo "  7. digital-evidence     - Digital Evidence Analysis"
    echo "  8. geolocation          - Geolocation & Media Verification"
    
    echo ""
    echo "Select modules by number (comma-separated):"
    echo -e "${DIM}Example: 1,2,5,8${NC}"
    echo ""
    echo "Or enter module keys:"
    echo -e "${DIM}Example: case-intake,person-investigation,reporting${NC}"
    echo ""
    
    local selection
    read -r -p "> " selection
    
    if [[ -z "$selection" ]]; then
        warn "No selection made"
        pause
        return
    fi
    
    # Check if selection is numbers or keys
    local modules=""
    if [[ "$selection" =~ ^[0-9,[:space:]]+$ ]]; then
        # Convert numbers to module keys
        local module_map=(
            "case-intake"
            "evidence-handling"
            "reporting"
            "company-investigation"
            "person-investigation"
            "social-media"
            "digital-evidence"
            "geolocation"
        )
        
        IFS=',' read -ra NUMS <<< "$selection"
        local selected_keys=()
        
        for num in "${NUMS[@]}"; do
            num=$(echo "$num" | tr -d ' ')
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#module_map[@]} ]]; then
                selected_keys+=("${module_map[$((num - 1))]}")
            fi
        done
        
        modules=$(IFS=,; echo "${selected_keys[*]}")
    else
        # Use as-is (assume module keys)
        modules="$selection"
    fi
    
    if [[ -z "$modules" ]]; then
        warn "No valid modules selected"
        pause
        return
    fi
    
    # Generate SOPs
    echo ""
    info "Generating SOPs..."
    echo ""
    
    if "$PYTHON_BIN" "$SOP_BUILDER" --case-dir "$selected_case" --modules "$modules"; then
        success "SOPs generated successfully!"
        echo ""
        if confirm "Open SOPs folder?"; then
            open "$selected_case/04 - SOPs"
        fi
    else
        error "Failed to generate SOPs"
    fi
    
    pause
}

# ============================================================================
# View SOP Profiles
# ============================================================================

list_sop_profiles() {
    clear_screen
    print_header
    print_section "SOP PROFILES"

    if [[ ! -f "$SOP_BUILDER" ]]; then
        error "SOP builder not found at: $SOP_BUILDER"
        pause
        return
    fi

    "$PYTHON_BIN" "$SOP_BUILDER" --list-profiles

    pause
}

# ============================================================================
# INTEGRATION: Modified create_new_case() function
# Add this to your create_new_case() function after case is created
# ============================================================================

# This goes AFTER the case is successfully created by case_manager.py
# and BEFORE applying Obsidian configuration

integrate_sops_in_case_creation() {
    local case_dir="$1"
    
    # Ask user if they want SOPs
    echo ""
    if confirm "Generate Standard Operating Procedures for this case?"; then
        
        # Quick profile selection
        echo ""
        echo "Select SOP profile:"
        echo "  1) Quick (3 SOPs)"
        echo "  2) Standard (5 SOPs) - Recommended"
        echo "  3) Comprehensive (all SOPs)"
        echo "  4) Skip SOPs"
        
        local sop_choice
        read -r -p "Select (1-4): " sop_choice
        
        local profile=""
        case $sop_choice in
            1) profile="quick" ;;
            2) profile="standard" ;;
            3) profile="comprehensive" ;;
            4) return 0 ;;
            *) profile="standard" ;;
        esac
        
        if [[ -n "$profile" && -f "$SOP_BUILDER" ]]; then
            info "Generating SOPs..."
            if "$PYTHON_BIN" "$SOP_BUILDER" --case-dir "$case_dir" --profile "$profile" --quiet; then
                success "SOPs generated!"
            else
                warn "SOP generation had issues (continuing anyway)"
            fi
        fi
    fi
}

# ============================================================================
# MAIN LOOP
# ============================================================================

main() {
    # Change to Tools directory
    cd "$TOOLS_DIR" || {
        error "Cannot access $TOOLS_DIR"
        exit 1
    }

    # Check if case_manager.py exists
    if [[ ! -f "$CASE_MANAGER_PY" ]]; then
        clear_screen
        print_header
        error "case_manager.py not found at $CASE_MANAGER_PY"
        echo ""
        echo "Please ensure case_manager.py is in: $TOOLS_DIR/caseManager/"
        exit 1
    fi

    # Main loop
    while true; do
        show_banner
        show_menu

        local choice
        read -r -p "$(echo -e "${BOLD}Select option (1-10):${NC} ")" choice

        case $choice in
            1) create_new_case ;;
            2) list_cases ;;
            3) open_case ;;
            4) search_cases ;;
            5) generate_sops_menu ;;
            6) configure_obsidian ;;
            7) show_statistics ;;
            8) quick_actions ;;
            9) show_help ;;
            10)
                clear_screen
                print_header
                echo ""
                success "Goodbye! 👋"
                echo ""
                exit 0
                ;;
            *)
                error "Invalid option. Please select 1-10."
                sleep 1
                ;;
        esac
    done
}

main "$@"
