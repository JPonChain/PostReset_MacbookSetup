#!/usr/bin/env bash
#
# vault-template.sh - Vault Template Manager
# Save/apply vault configurations AND apply .obsidian from any case that has it.
#
# Usage: ./vault-template.sh
#

set -euo pipefail

TOOLS_DIR="${TOOLS_DIR:-$HOME/Tools}"
TEMPLATES_DIR="$TOOLS_DIR/vault-templates"
DEFAULT_VAULT="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/ObsidianVault}"
CASE_ROOT_DIR="${CASE_ROOT_DIR:-$DEFAULT_VAULT/Cases}"

# Persistent source-case selection for copying .obsidian to other cases
OBSIDIAN_SOURCE_FILE="${OBSIDIAN_SOURCE_FILE:-$HOME/.case_manager_obsidian_source}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ==========================================================================
# HELPER FUNCTIONS
# ==========================================================================

info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; }

print_header() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}            VAULT TEMPLATE MANAGER${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Save & Apply Vault Configurations + Case .obsidian Copy   ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_divider() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
}

confirm() {
    local prompt="$1"
    local response
    read -r -p "$(echo -e "${YELLOW}$prompt (y/n):${NC} ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

pause() {
    echo ""
    read -r -p "$(echo -e "${DIM}Press Enter to continue...${NC}")"
}

# ==========================================================================
# Obsidian Source Case replication (case with .obsidian -> other cases)
# ==========================================================================

find_case_dir_by_id() {
  local case_id="$1"
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
  success "Obsidian source set to: $(basename "$src_dir")"
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

apply_obsidian_from_source_to_case() {
  local target_case_id="$1"
  local target_dir
  target_dir="$(find_case_dir_by_id "$target_case_id")"

  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    error "Could not find target case folder for: $target_case_id"
    return 1
  fi

  local src_dir
  if ! src_dir="$(get_obsidian_source_dir)"; then
    error "No valid Obsidian source case is set."
    echo "Set one first: 'Use Case as .obsidian Source'"
    return 1
  fi

  warn "This will overwrite the target case's .obsidian folder (backup will be created)."
  echo -e "${DIM}From: $src_dir${NC}"
  echo -e "${DIM}To:   $target_dir${NC}"

  if ! confirm "Continue?"; then
    info "Cancelled"
    return 0
  fi

  if [[ -d "$target_dir/.obsidian" ]]; then
    local backup="$target_dir/.obsidian.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$target_dir/.obsidian" "$backup"
    warn "Backed up existing .obsidian to: $(basename "$backup")"
  fi

  cp -R "$src_dir/.obsidian" "$target_dir/"

  if [[ -d "$src_dir/Templates" ]]; then
    mkdir -p "$target_dir/Templates"
    cp -R "$src_dir/Templates/"* "$target_dir/Templates/" 2>/dev/null || true
  fi

  mkdir -p "$target_dir/Attachments" 2>/dev/null || true

  success "Applied .obsidian (and Templates if available) to $target_case_id"
}

# ==========================================================================
# TEMPLATE FUNCTIONS (vault-wide templates)
# ==========================================================================

save_template() {
    print_header
    echo -e "${MAGENTA}${BOLD}SAVE VAULT AS TEMPLATE${NC}"
    print_divider
    echo ""

    echo "Source vault path:"
    read -r -p "$(echo -e "${DIM}(Press Enter for default: $DEFAULT_VAULT)${NC} ")" source_vault
    source_vault="${source_vault:-$DEFAULT_VAULT}"

    if [[ ! -d "$source_vault/.obsidian" ]]; then
        error "Not a valid Obsidian vault: $source_vault"
        pause
        return
    fi

    echo ""
    echo "Template name:"
    read -r -p "$(echo -e "${BOLD}Enter name:${NC} ")" template_name

    if [[ -z "$template_name" ]]; then
        error "Template name cannot be empty"
        pause
        return
    fi

    template_name=$(echo "$template_name" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local template_dir="$TEMPLATES_DIR/$template_name"

    if [[ -d "$template_dir" ]]; then
        warn "Template '$template_name' already exists"
        if ! confirm "Overwrite?"; then
            pause
            return
        fi
        rm -rf "$template_dir"
    fi

    echo ""
    info "Creating template directory..."
    mkdir -p "$template_dir"

    info "Copying vault configuration..."
    cp -r "$source_vault/.obsidian" "$template_dir/"

    if [[ -d "$source_vault/Templates" ]]; then
        info "Copying templates..."
        cp -r "$source_vault/Templates" "$template_dir/"
    fi

    cat > "$template_dir/template.json" <<EOF
{
  "name": "$template_name",
  "created": "$(date +%Y-%m-%d)",
  "source": "$source_vault",
  "includes": {
    "plugins": true,
    "themes": true,
    "settings": true,
    "templates": $([ -d "$source_vault/Templates" ] && echo "true" || echo "false")
  }
}
EOF

    echo ""
    success "Template saved: $template_name"
    echo -e "${DIM}Location: $template_dir${NC}"
    pause
}

list_templates() {
    print_header
    echo -e "${MAGENTA}${BOLD}SAVED TEMPLATES${NC}"
    print_divider
    echo ""

    if [[ ! -d "$TEMPLATES_DIR" ]] || [[ -z "$(ls -A "$TEMPLATES_DIR" 2>/dev/null)" ]]; then
        info "No templates saved yet."
        pause
        return
    fi

    local count=1
    for template_dir in "$TEMPLATES_DIR"/*; do
        [[ -d "$template_dir" ]] || continue
        local template_name
        template_name=$(basename "$template_dir")
        local created="Unknown"
        if [[ -f "$template_dir/template.json" ]]; then
            created=$(grep '"created"' "$template_dir/template.json" | sed 's/.*: "\(.*\)".*/\1/')
        fi
        echo -e "${CYAN}$count)${NC} ${BOLD}$template_name${NC}  ${DIM}(Created: $created)${NC}"
        count=$((count + 1))
    done

    pause
}

apply_template() {
    print_header
    echo -e "${MAGENTA}${BOLD}APPLY TEMPLATE TO VAULT${NC}"
    print_divider
    echo ""

    if [[ ! -d "$TEMPLATES_DIR" ]] || [[ -z "$(ls -A "$TEMPLATES_DIR" 2>/dev/null)" ]]; then
        warn "No templates available. Create one first."
        pause
        return
    fi

    echo "Available templates:"
    echo ""
    local templates=()
    local count=1
    for template_dir in "$TEMPLATES_DIR"/*; do
        [[ -d "$template_dir" ]] || continue
        local template_name
        template_name=$(basename "$template_dir")
        templates+=("$template_name")
        echo "  $count) $template_name"
        count=$((count + 1))
    done

    echo ""
    local selection
    read -r -p "$(echo -e "${BOLD}Select template (1-${#templates[@]}):${NC} ")" selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt ${#templates[@]} ]]; then
        error "Invalid selection"
        pause
        return
    fi

    local selected_template="${templates[$((selection - 1))]}"
    local template_dir="$TEMPLATES_DIR/$selected_template"

    echo ""
    echo "Target vault path:"
    read -r -p "$(echo -e "${DIM}(Press Enter for default: $DEFAULT_VAULT)${NC} ")" target_vault
    target_vault="${target_vault:-$DEFAULT_VAULT}"

    if [[ ! -d "$target_vault" ]]; then
        warn "Vault does not exist: $target_vault"
        if confirm "Create new vault?"; then
            mkdir -p "$target_vault"
        else
            pause
            return
        fi
    fi

    echo ""
    warn "This will overwrite existing vault configuration!"

    if ! confirm "Continue?"; then
        info "Operation cancelled"
        pause
        return
    fi

    echo ""
    info "Applying template..."

    if [[ -d "$target_vault/.obsidian" ]]; then
        local backup_dir="$target_vault/.obsidian.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up current config to: $(basename "$backup_dir")"
        mv "$target_vault/.obsidian" "$backup_dir"
    fi

    cp -r "$template_dir/.obsidian" "$target_vault/"

    if [[ -d "$template_dir/Templates" ]]; then
        mkdir -p "$target_vault/Templates"
        cp -r "$template_dir/Templates/"* "$target_vault/Templates/" 2>/dev/null || true
    fi

    mkdir -p "$target_vault/Cases" "$target_vault/Attachments"

    success "Template applied successfully!"

    if confirm "Open Obsidian now?"; then
        open -a Obsidian "$target_vault" 2>/dev/null || warn "Could not open Obsidian"
    fi

    pause
}

delete_template() {
    print_header
    echo -e "${MAGENTA}${BOLD}DELETE TEMPLATE${NC}"
    print_divider
    echo ""

    if [[ ! -d "$TEMPLATES_DIR" ]] || [[ -z "$(ls -A "$TEMPLATES_DIR" 2>/dev/null)" ]]; then
        info "No templates to delete."
        pause
        return
    fi

    echo "Saved templates:"
    echo ""
    local templates=()
    local count=1
    for template_dir in "$TEMPLATES_DIR"/*; do
        [[ -d "$template_dir" ]] || continue
        local template_name
        template_name=$(basename "$template_dir")
        templates+=("$template_name")
        echo "  $count) $template_name"
        count=$((count + 1))
    done

    echo ""
    local selection
    read -r -p "$(echo -e "${BOLD}Select template to delete (1-${#templates[@]}):${NC} ")" selection

    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt ${#templates[@]} ]]; then
        error "Invalid selection"
        pause
        return
    fi

    local selected_template="${templates[$((selection - 1))]}"
    local template_dir="$TEMPLATES_DIR/$selected_template"

    echo ""
    warn "Delete template: $selected_template"

    if confirm "Are you sure?"; then
        rm -rf "$template_dir"
        success "Template deleted: $selected_template"
    else
        info "Cancelled"
    fi

    pause
}

# ==========================================================================
# Case-based .obsidian operations (menu)
# ==========================================================================

menu_set_source_case() {
  print_header
  echo -e "${MAGENTA}${BOLD}USE CASE AS .obsidian SOURCE${NC}"
  print_divider
  echo ""
  echo "Enter a Case ID that already contains a .obsidian folder."
  echo -e "${DIM}Example: 2026-001${NC}"
  echo ""
  local cid
  read -r -p "Case ID: " cid
  if [[ -z "$cid" ]]; then
    warn "No Case ID provided"
    pause
    return
  fi
  set_obsidian_source_from_case "$cid" || true
  pause
}

menu_apply_source_to_case() {
  print_header
  echo -e "${MAGENTA}${BOLD}APPLY SOURCE .obsidian TO A CASE${NC}"
  print_divider
  echo ""

  local src
  if ! src="$(get_obsidian_source_dir 2>/dev/null)"; then
    warn "No source set yet. Choose 'Use Case as .obsidian Source' first."
    pause
    return
  fi

  echo -e "${DIM}Current source: $src${NC}"
  echo ""
  local tid
  read -r -p "Target Case ID: " tid
  if [[ -z "$tid" ]]; then
    warn "No target Case ID provided"
    pause
    return
  fi

  apply_obsidian_from_source_to_case "$tid" || true
  pause
}

menu_show_source() {
  print_header
  echo -e "${MAGENTA}${BOLD}CURRENT SOURCE STATUS${NC}"
  print_divider
  echo ""

  local src
  if src="$(get_obsidian_source_dir 2>/dev/null)"; then
    success "Source is set"
    echo -e "${DIM}$src${NC}"
  else
    warn "Source is not set (or no longer valid)"
    echo -e "${DIM}Set one using: 'Use Case as .obsidian Source'${NC}"
  fi

  pause
}

menu_clear_source() {
  rm -f "$OBSIDIAN_SOURCE_FILE" 2>/dev/null || true
  success "Cleared source selection"
  pause
}

# ==========================================================================
# MAIN MENU
# ==========================================================================

show_menu() {
    print_header

    echo -e "${GREEN}${BOLD}Main Menu:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ${BOLD}Save Vault as Template${NC}"
    echo -e "  ${CYAN}2)${NC} ${BOLD}Apply Template to Vault${NC}"
    echo -e "  ${CYAN}3)${NC} ${BOLD}List Templates${NC}"
    echo -e "  ${CYAN}4)${NC} ${BOLD}Delete Template${NC}"
    echo ""
    echo -e "  ${CYAN}5)${NC} ${BOLD}Use Case as .obsidian Source${NC}"
    echo -e "     ${DIM}→ Pick ANY case that already has .obsidian and store it${NC}"
    echo -e "  ${CYAN}6)${NC} ${BOLD}Apply Source to a Case${NC}"
    echo -e "     ${DIM}→ Copy source .obsidian (+Templates) into a target case${NC}"
    echo -e "  ${CYAN}7)${NC} ${BOLD}Show Current Source${NC}"
    echo -e "  ${CYAN}8)${NC} ${BOLD}Clear Source${NC}"
    echo ""
    echo -e "  ${CYAN}9)${NC} ${BOLD}Help${NC}"
    echo -e "  ${CYAN}10)${NC} ${BOLD}Exit${NC}"
    echo ""
    print_divider
    echo ""

    local choice
    read -r -p "$(echo -e "${BOLD}Select option (1-10):${NC} ")" choice

    case $choice in
        1) save_template ;;
        2) apply_template ;;
        3) list_templates ;;
        4) delete_template ;;
        5) menu_set_source_case ;;
        6) menu_apply_source_to_case ;;
        7) menu_show_source ;;
        8) menu_clear_source ;;
        9) show_help ;;
        10) exit 0 ;;
        *) error "Invalid option"; sleep 1 ;;
    esac
}

show_help() {
    print_header
    echo -e "${MAGENTA}${BOLD}HELP${NC}"
    print_divider
    echo ""

    echo -e "${BOLD}Vault Templates:${NC}"
    echo "  Save/apply a vault's .obsidian configuration (themes/plugins/settings)"
    echo "  and optionally its Templates folder."
    echo ""

    echo -e "${BOLD}Case-based .obsidian Source:${NC}"
    echo "  Use ANY existing case that already has .obsidian/ as the source."
    echo "  Then copy that .obsidian (+Templates) into other cases."
    echo ""
    echo "To create a .obsidian in a case folder:"
    echo "  1) Open Obsidian"
    echo "  2) 'Open folder as vault'"
    echo "  3) Select the case folder"
    echo "  4) Configure your theme/plugins"
    echo ""

    pause
}

# ==========================================================================
# MAIN LOOP
# ==========================================================================

main() {
    mkdir -p "$TEMPLATES_DIR"

    while true; do
        show_menu
    done
}

main "$@"
