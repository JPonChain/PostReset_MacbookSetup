#!/usr/bin/env bash
#
# setup_obsidian.sh - Complete Obsidian configuration for casework
# Configures theme, plugins, settings, and templates
#
# Usage: chmod +x setup_obsidian.sh && ./setup_obsidian.sh
#

# Check if running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash. Please run with: bash setup_obsidian.sh"
    exit 1
fi

# Check bash version (need 4.0+ for associative arrays)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Error: This script requires bash 4.0 or higher. You have bash $BASH_VERSION"
    echo "On macOS, install with: brew install bash"
    exit 1
fi

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

OBSIDIAN_VAULT_PATH="${OBSIDIAN_VAULT_PATH:-$HOME/Documents/ObsidianVault}"
OBSIDIAN_CONFIG_DIR="$OBSIDIAN_VAULT_PATH/.obsidian"
PLUGINS_DIR="$OBSIDIAN_CONFIG_DIR/plugins"
THEMES_DIR="$OBSIDIAN_CONFIG_DIR/themes"
SNIPPETS_DIR="$OBSIDIAN_CONFIG_DIR/snippets"

# Recommended plugins for casework
declare -A PLUGINS
PLUGINS["templater-obsidian"]="SilentVoid13/Templater"
PLUGINS["dataview"]="blacksmithgu/obsidian-dataview"
PLUGINS["obsidian-tasks-plugin"]="obsidian-tasks-group/obsidian-tasks"
PLUGINS["calendar"]="liamcain/obsidian-calendar-plugin"
PLUGINS["obsidian-kanban"]="mgmeyers/obsidian-kanban"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
fail() { echo -e "${RED}❌ $*${NC}"; exit 1; }

ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        info "Created directory: $1"
    fi
}

# ============================================================================
# VAULT SETUP
# ============================================================================

check_vault() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          OBSIDIAN VAULT CONFIGURATION WIZARD                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -d "$OBSIDIAN_VAULT_PATH" ]]; then
        fail "Vault does not exist at $OBSIDIAN_VAULT_PATH"
    fi
    
    info "Vault found at: $OBSIDIAN_VAULT_PATH"
    ensure_dir "$OBSIDIAN_CONFIG_DIR"
    ensure_dir "$PLUGINS_DIR"
    ensure_dir "$THEMES_DIR"
    ensure_dir "$SNIPPETS_DIR"
}

# ============================================================================
# THEME INSTALLATION
# ============================================================================

install_minimal_theme() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 1: Installing Minimal Theme${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local theme_dir="$THEMES_DIR/Minimal"
    local theme_css="$theme_dir/theme.css"
    local manifest="$theme_dir/manifest.json"
    
    ensure_dir "$theme_dir"
    
    info "Downloading Minimal theme..."
    if curl -sfL -o "$theme_css" \
        "https://raw.githubusercontent.com/kepano/obsidian-minimal/master/theme.css"; then
        success "Downloaded theme.css"
    else
        warn "Failed to download Minimal theme, trying alternative..."
        if curl -sfL -o "$theme_css" \
            "https://github.com/kepano/obsidian-minimal/releases/latest/download/theme.css"; then
            success "Downloaded from releases"
        else
            warn "Could not download theme automatically"
            return 1
        fi
    fi
    
    # Create manifest
    cat > "$manifest" <<'EOF'
{
    "name": "Minimal",
    "version": "7.7.1",
    "minAppVersion": "1.0.0",
    "author": "kepano"
}
EOF
    
    success "Minimal theme installed"
    return 0
}

# ============================================================================
# APPEARANCE CONFIGURATION
# ============================================================================

configure_appearance() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 2: Configuring Appearance${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local appearance_file="$OBSIDIAN_CONFIG_DIR/appearance.json"
    
    cat > "$appearance_file" <<EOF
{
  "accentColor": "#4A9EFF",
  "theme": "obsidian",
  "cssTheme": "Minimal",
  "baseFontSize": 16,
  "textFontFamily": "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  "monospaceFontFamily": "JetBrains Mono, SF Mono, Monaco, Consolas, monospace",
  "enabledCssSnippets": ["case-styling"],
  "translucency": false,
  "nativeMenus": true,
  "showViewHeader": true
}
EOF
    
    # Create custom CSS snippet for case styling
    cat > "$SNIPPETS_DIR/case-styling.css" <<'EOF'
/* Case Management Custom Styling */

/* Case headers */
.markdown-preview-view h1[data-heading*="case"],
.markdown-preview-view h1[data-heading*="Case"] {
    color: var(--text-accent);
    border-bottom: 2px solid var(--text-accent);
    padding-bottom: 0.5em;
}

/* Status indicators */
.tag[href="#status/active"] { background-color: #4CAF50; color: white; }
.tag[href="#status/closed"] { background-color: #9E9E9E; color: white; }
.tag[href="#status/pending"] { background-color: #FF9800; color: white; }

/* Evidence links */
a[href*="Evidence"] { color: #2196F3; font-weight: 500; }

/* Task styling */
.task-list-item input[type="checkbox"] {
    width: 1.2em;
    height: 1.2em;
}

/* Frontmatter in preview */
.frontmatter-container {
    background-color: var(--background-secondary);
    border-radius: 6px;
    padding: 1em;
    margin-bottom: 1em;
}
EOF
    
    success "Appearance configured with Minimal theme"
    info "Custom case styling added"
}

# ============================================================================
# PLUGIN INSTALLATION
# ============================================================================

download_plugin() {
    local plugin_id="$1"
    local repo="$2"
    local plugin_dir="$PLUGINS_DIR/$plugin_id"
    
    ensure_dir "$plugin_dir"
    
    info "Downloading $plugin_id..."
    
    # Get latest release
    local release_api="https://api.github.com/repos/$repo/releases/latest"
    local release_data
    
    if ! release_data=$(curl -sfL "$release_api" 2>/dev/null); then
        warn "Failed to fetch release info for $plugin_id"
        return 1
    fi
    
    # Extract download URLs
    local main_url manifest_url styles_url
    main_url=$(echo "$release_data" | grep -o '"browser_download_url": *"[^"]*main.js"' | sed 's/.*: *"\([^"]*\)".*/\1/' | head -n1)
    manifest_url=$(echo "$release_data" | grep -o '"browser_download_url": *"[^"]*manifest.json"' | sed 's/.*: *"\([^"]*\)".*/\1/' | head -n1)
    styles_url=$(echo "$release_data" | grep -o '"browser_download_url": *"[^"]*styles.css"' | sed 's/.*: *"\([^"]*\)".*/\1/' | head -n1)
    
    # If not in assets, construct URLs from tag
    if [[ -z "$main_url" ]]; then
        local tag=$(echo "$release_data" | grep '"tag_name"' | sed 's/.*: *"\([^"]*\)".*/\1/' | head -n1)
        main_url="https://github.com/$repo/releases/download/$tag/main.js"
        manifest_url="https://github.com/$repo/releases/download/$tag/manifest.json"
        styles_url="https://github.com/$repo/releases/download/$tag/styles.css"
    fi
    
    # Download main.js (required)
    if [[ -n "$main_url" ]] && curl -sfL -o "$plugin_dir/main.js" "$main_url" 2>/dev/null; then
        success "  ✓ main.js"
    else
        warn "  ✗ Failed to download main.js"
        return 1
    fi
    
    # Download manifest.json (required)
    if [[ -n "$manifest_url" ]] && curl -sfL -o "$plugin_dir/manifest.json" "$manifest_url" 2>/dev/null; then
        success "  ✓ manifest.json"
    else
        warn "  ✗ Failed to download manifest.json"
        return 1
    fi
    
    # Download styles.css (optional)
    if [[ -n "$styles_url" ]] && curl -sfL -o "$plugin_dir/styles.css" "$styles_url" 2>/dev/null; then
        success "  ✓ styles.css"
    fi
    
    return 0
}

install_plugins() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 3: Installing Community Plugins${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local successful=()
    local failed=()
    
    for plugin_id in "${!PLUGINS[@]}"; do
        local repo="${PLUGINS[$plugin_id]}"
        if download_plugin "$plugin_id" "$repo"; then
            successful+=("$plugin_id")
        else
            failed+=("$plugin_id")
        fi
    done
    
    echo ""
    if [[ ${#successful[@]} -gt 0 ]]; then
        success "Successfully installed ${#successful[@]} plugin(s):"
        for p in "${successful[@]}"; do
            echo "  ✓ $p"
        done
    fi
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        warn "Failed to install ${#failed[@]} plugin(s):"
        for p in "${failed[@]}"; do
            echo "  ✗ $p"
        done
        echo ""
        info "Install these manually from Obsidian: Settings → Community Plugins → Browse"
    fi
}

enable_plugins() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 4: Enabling Plugins${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local community_plugins_file="$OBSIDIAN_CONFIG_DIR/community-plugins.json"
    
    # List installed plugins
    local installed=()
    for plugin_id in "${!PLUGINS[@]}"; do
        if [[ -f "$PLUGINS_DIR/$plugin_id/manifest.json" ]]; then
            installed+=("\"$plugin_id\"")
        fi
    done
    
    # Write community-plugins.json
    if [[ ${#installed[@]} -gt 0 ]]; then
        local plugins_json=$(IFS=,; echo "${installed[*]}")
        echo "[$plugins_json]" > "$community_plugins_file"
        success "Enabled ${#installed[@]} plugin(s)"
    else
        echo "[]" > "$community_plugins_file"
        warn "No plugins to enable"
    fi
}

# ============================================================================
# PLUGIN CONFIGURATIONS
# ============================================================================

configure_templater() {
    info "Configuring Templater plugin..."
    
    local templater_config="$PLUGINS_DIR/templater-obsidian/data.json"
    
    cat > "$templater_config" <<EOF
{
  "command_timeout": 5,
  "templates_folder": "Templates",
  "templates_pairs": [["", ""]],
  "trigger_on_file_creation": false,
  "auto_jump_to_cursor": true,
  "enable_system_commands": false,
  "shell_path": "",
  "user_scripts_folder": "",
  "enable_folder_templates": true,
  "folder_templates": [
    { "folder": "Cases", "template": "Templates/Intake.md" }
  ],
  "syntax_highlighting": true,
  "enabled": true,
  "startup_templates": []
}
EOF
    
    success "Templater configured"
}

configure_dataview() {
    info "Configuring Dataview plugin..."
    
    local dataview_config="$PLUGINS_DIR/dataview/data.json"
    
    cat > "$dataview_config" <<EOF
{
  "defaultDateFormat": "MMMM dd, yyyy",
  "defaultDateTimeFormat": "h:mm a - MMMM dd, yyyy",
  "maxRecursiveDepth": 4,
  "tableIdColumnName": "File",
  "tableGroupColumnName": "Group",
  "inlineQueryPrefix": "=",
  "inlineJsQueryPrefix": "$=",
  "inlineQueriesInCodeblocks": true,
  "enableInlineDataview": true,
  "enableDataviewJs": false,
  "enableInlineDataviewJs": false,
  "prettyRenderInlineFields": true,
  "dataviewJsKeyword": "dataviewjs"
}
EOF
    
    success "Dataview configured"
}

configure_tasks() {
    info "Configuring Tasks plugin..."
    
    local tasks_config="$PLUGINS_DIR/obsidian-tasks-plugin/data.json"
    
    cat > "$tasks_config" <<EOF
{
  "globalFilter": "",
  "removeGlobalFilter": false,
  "setDoneDate": true,
  "autoSuggestInEditor": true,
  "provideAccessKeys": true,
  "useFilenameAsScheduledDate": false,
  "filenameAsDateFolders": []
}
EOF
    
    success "Tasks configured"
}

# ============================================================================
# CORE SETTINGS
# ============================================================================

configure_core_settings() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 5: Configuring Core Settings${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local app_json="$OBSIDIAN_CONFIG_DIR/app.json"
    
    cat > "$app_json" <<EOF
{
  "strictLineBreaks": false,
  "showFrontmatter": true,
  "showLineNumber": false,
  "readableLineLength": true,
  "spellcheck": true,
  "spellcheckLanguages": ["en-US"],
  "defaultViewMode": "source",
  "attachmentFolderPath": "Attachments",
  "newLinkFormat": "shortest",
  "useMarkdownLinks": false,
  "alwaysUpdateLinks": true,
  "promptDelete": true,
  "showUnsupportedFiles": false,
  "newFileLocation": "folder",
  "newFileFolderPath": "Cases",
  "foldHeading": true,
  "foldIndent": true,
  "showIndentGuide": true,
  "vimMode": false,
  "legacyEditor": false,
  "livePreview": true,
  "communityThemeSortOrder": "download",
  "communityPluginSortOrder": "download"
}
EOF
    
    success "Core settings configured"
}

configure_templates() {
    info "Configuring template settings..."
    
    local templates_json="$OBSIDIAN_CONFIG_DIR/templates.json"
    
    cat > "$templates_json" <<EOF
{
  "folder": "Templates",
  "dateFormat": "YYYY-MM-DD",
  "timeFormat": "HH:mm"
}
EOF
    
    success "Template settings configured"
}

configure_hotkeys() {
    info "Configuring hotkeys..."
    
    local hotkeys_json="$OBSIDIAN_CONFIG_DIR/hotkeys.json"
    
    cat > "$hotkeys_json" <<EOF
{
  "templater-obsidian:insert-templater": [
    {
      "modifiers": ["Mod", "Shift"],
      "key": "T"
    }
  ],
  "command-palette:open": [
    {
      "modifiers": ["Mod", "Shift"],
      "key": "P"
    }
  ],
  "global-search:open": [
    {
      "modifiers": ["Mod", "Shift"],
      "key": "F"
    }
  ]
}
EOF
    
    success "Hotkeys configured"
}

# ============================================================================
# ADVANCED TEMPLATES
# ============================================================================

create_advanced_templates() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} PHASE 6: Creating Advanced Templates${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local templates_dir="$OBSIDIAN_VAULT_PATH/Templates"
    
    # Case Dashboard Template
    cat > "$templates_dir/Case Dashboard.md" <<'EOF'
---
case-id: 
status: active
created: {{date}}
---

# Case Dashboard: {{title}}

## 📊 Quick Stats
```dataview
TABLE status, created, last-updated
FROM "Cases"
WHERE file.name = this.file.name
```

## ⏰ Upcoming Deadlines
```tasks
not done
path includes {{title}}
sort by due
```

## 📝 Recent Notes
```dataview
TABLE file.mtime as "Last Modified"
FROM "Cases/{{title}}"
SORT file.mtime DESC
LIMIT 5
```

## 📎 Evidence Log
- [[{{title}}/01 - Evidence/Evidence Index|View All Evidence]]

## 🎯 Next Actions
- [ ] 

---
*Last updated: {{date}}*
EOF

    # Timeline Template
    cat > "$templates_dir/Timeline.md" <<'EOF'
---
case-id: 
type: timeline
date: {{date}}
---

# Timeline: {{title}}

## Chronological Events

### {{date}}
**Event**: 
**Source**: 
**Significance**: 

---

### YYYY-MM-DD
**Event**: 
**Source**: 
**Significance**: 

---

## Key Dates
| Date | Event | Source |
|------|-------|--------|
| {{date}} |  |  |

EOF

    # Witness Interview Template
    cat > "$templates_dir/Witness Interview.md" <<'EOF'
---
case-id: 
type: interview
date: {{date}}
witness: 
interviewer: 
---

# Witness Interview

**Date**: {{date}}  
**Time**: {{time}}  
**Location**:  
**Witness Name**:  
**Contact**:  
**Interviewer**:  

## Background
**Relationship to Case**:  
**Occupation**:  
**How Known**:  

## Interview Notes

### Opening
- Introduction and purpose explained
- Rights/confidentiality discussed
- Consent obtained: ☐ Yes ☐ No

### Key Testimony

#### Question 1:
**Q**: 
**A**: 

#### Question 2:
**Q**: 
**A**: 

## Credibility Assessment
**Demeanor**:  
**Consistency**:  
**Corroboration**:  

## Follow-up Required
- [ ] 

## Attachments
- Recording: 
- Photos: 
- Documents: 

---
*Prepared by: {{date}}*
EOF

    success "Advanced templates created"
}

# ============================================================================
# MANUAL STEPS
# ============================================================================

print_manual_steps() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  CONFIGURATION COMPLETE                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Setup Summary:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Minimal theme installed"
    echo "  ✓ Appearance configured"
    echo "  ✓ Community plugins downloaded"
    echo "  ✓ Plugin settings configured"
    echo "  ✓ Core settings optimized"
    echo "  ✓ Advanced templates created"
    echo "  ✓ Custom CSS snippets added"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${YELLOW}📝 REQUIRED MANUAL STEPS:${NC}"
    echo ""
    echo "1️⃣  Open Obsidian:"
    echo "    • Open Obsidian app"
    echo "    • Select vault: $OBSIDIAN_VAULT_PATH"
    echo ""
    echo "2️⃣  Enable Community Plugins:"
    echo "    • Settings → Community Plugins"
    echo "    • Click 'Turn on community plugins'"
    echo "    • Confirm the security prompt"
    echo ""
    echo "3️⃣  Verify Installed Plugins:"
    echo "    • Settings → Community Plugins → Installed"
    echo "    • Ensure these are enabled:"
    for plugin_id in "${!PLUGINS[@]}"; do
        if [[ -f "$PLUGINS_DIR/$plugin_id/manifest.json" ]]; then
            echo "      ✓ $plugin_id"
        else
            echo "      ✗ $plugin_id (install manually)"
        fi
    done
    echo ""
    echo "4️⃣  Verify Theme:"
    echo "    • Settings → Appearance → Themes"
    echo "    • 'Minimal' should be active"
    echo "    • If not, click 'Minimal' to activate"
    echo ""
    echo "5️⃣  Configure Templater (Important!):"
    echo "    • Settings → Templater"
    echo "    • Template folder: 'Templates' (should be set)"
    echo "    • Enable 'Trigger on file creation' if desired"
    echo ""
    echo "6️⃣  Test the Setup:"
    echo "    • Open Command Palette (Cmd/Ctrl + Shift + P)"
    echo "    • Try: 'Templater: Create new note from template'"
    echo "    • Select 'Intake' template to test"
    echo ""
    echo -e "${BLUE}💡 Pro Tips:${NC}"
    echo "  • Enable CSS snippets: Settings → Appearance → CSS snippets"
    echo "  • Customize hotkeys: Settings → Hotkeys"
    echo "  • Explore Dataview queries in Case Dashboard template"
    echo ""
    echo -e "${GREEN}🎉 Your Obsidian vault is ready for case management!${NC}"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    check_vault
    install_minimal_theme || warn "Theme installation had issues"
    configure_appearance
    install_plugins
    enable_plugins
    
    # Configure plugins if they were installed
    [[ -d "$PLUGINS_DIR/templater-obsidian" ]] && configure_templater
    [[ -d "$PLUGINS_DIR/dataview" ]] && configure_dataview
    [[ -d "$PLUGINS_DIR/obsidian-tasks-plugin" ]] && configure_tasks
    
    configure_core_settings
    configure_templates
    configure_hotkeys
    create_advanced_templates
    
    print_manual_steps
}

main "$@"