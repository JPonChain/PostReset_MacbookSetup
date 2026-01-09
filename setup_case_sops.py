#!/usr/bin/env python3
"""
sop_builder.py - Fixed version with proper escaping
"""

import argparse
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List

# ============================================================================
# SOP MODULE DEFINITIONS
# ============================================================================

@dataclass(frozen=True)
class SopModule:
    key: str
    title: str
    filename: str
    category: str
    default_md: str
    
    def __hash__(self):
        return hash(self.key)


MODULES: Dict[str, SopModule] = {}

# Note: For placeholder modules, use double braces {{}} to escape them
# This prevents .format() from trying to replace them

MODULES["social-media"] = SopModule(
    key="social-media",
    title="Social Media Investigation",
    filename="04-Social-Media-Investigation.md",
    category="intermediate",
    default_md="""---
type: sop
category: social-media
version: 1.0
created: {date}
---

# Social Media Investigation

## Purpose
Conduct passive social media investigations across multiple platforms.

## Platforms
- Facebook, Instagram, Twitter/X, LinkedIn, TikTok, Reddit

## Process
1. Identify target accounts
2. Document public profile information
3. Archive posts and content
4. Map connections and networks
5. Analyze patterns and timeline

## Tools
- Archive Page extension
- Screenshot tools
- Wayback Machine

## Resources
- OSINT Framework: https://osintframework.com/
"""
)

MODULES["company-investigation"] = SopModule(
    key="company-investigation",
    title="Company & Organization Investigation",
    filename="05-Company-Investigation.md",
    category="intermediate",
    default_md="""---
type: sop
category: company
version: 1.0
created: {date}
---

# Company & Organization Investigation

## Purpose
Research companies and organizations using public sources.

## Key Areas
- Corporate structure and ownership
- Financial information
- Legal history
- Online presence
- Key personnel

## Resources
- Secretary of State websites
- SEC EDGAR database
- Better Business Bureau
- LinkedIn company pages

## Process
1. Identify legal entity
2. Research corporate filings
3. Check court records
4. Review online presence
5. Compile findings
"""
)

MODULES["digital-evidence"] = SopModule(
    key="digital-evidence",
    title="Digital Evidence Analysis",
    filename="06-Digital-Evidence-Analysis.md",
    category="advanced",
    default_md="""---
type: sop
category: evidence
version: 1.0
created: {date}
---

# Digital Evidence Analysis

## Purpose
Analyze and process digital evidence while maintaining integrity.

## Key Processes
- File analysis
- Metadata extraction
- Timeline construction
- Pattern identification

## Tools
- ExifTool
- File hash utilities
- Forensic viewers

## Best Practices
- Never modify originals
- Document all steps
- Maintain chain of custody
- Verify file integrity
"""
)

MODULES["geolocation"] = SopModule(
    key="geolocation",
    title="Geolocation & Media Verification",
    filename="07-Geolocation-Verification.md",
    category="advanced",
    default_md="""---
type: sop
category: geolocation
version: 1.0
created: {date}
---

# Geolocation & Media Verification

## Purpose
Verify location and authenticity of photos and videos.

## Techniques
- Reverse image search
- EXIF metadata analysis
- Landmark identification
- Shadow/sun angle analysis
- Cross-reference with maps

## Tools
- Google Maps / Street View
- TinEye
- Google Reverse Image Search
- SunCalc for shadow analysis

## Process
1. Preserve original media
2. Extract metadata
3. Reverse image search
4. Identify visual clues
5. Cross-reference location data
6. Document findings
"""
)

MODULES["reporting"] = SopModule(
    key="reporting",
    title="Investigation Reporting",
    filename="08-Reporting.md",
    category="basic",
    default_md="""---
type: sop
category: reporting
version: 1.0
created: {date}
---

# Investigation Reporting

## Purpose
Document findings in clear, professional reports.

## Report Structure
1. Executive Summary
2. Investigation Scope
3. Methodology
4. Findings (by category)
5. Timeline
6. Conclusions
7. Recommendations
8. Appendices (evidence, sources)

## Best Practices
- Use clear, objective language
- Cite all sources
- Include confidence levels
- Document limitations
- Provide context for findings

## Confidence Levels
- **High**: Multiple independent sources confirm
- **Medium**: Single reliable source or partial confirmation
- **Low**: Unverified or circumstantial

## Key Elements
- All claims must be sourced
- Include dates and timestamps
- Maintain professional tone
- Clearly mark speculation vs. fact
"""
)

# Now add the complete modules from before (case-intake, evidence-handling, person-investigation)
# These already have proper formatting

MODULES["case-intake"] = SopModule(
    key="case-intake",
    title="Case Intake & Scope Definition",
    filename="01-Case-Intake-and-Scope.md",
    category="basic",
    default_md="""---
type: sop
category: intake
version: 1.0
created: {date}
---

# Case Intake & Scope Definition

## Purpose
Establish clear, lawful scope and documentation standards for OSINT investigations.

---

## Pre-Investigation Requirements

### Authorization & Legal Basis
- [ ] Written authorization from client/sponsor
- [ ] Legal basis documented
- [ ] Jurisdiction confirmed
- [ ] Privacy/data protection laws reviewed
- [ ] Ethical guidelines acknowledged

### Scope Definition
**Define clearly:**
- Investigation objectives (what questions to answer)
- Entities of Interest (EOIs): people, organizations, domains, handles
- Geographic scope
- Time window
- Information sources (authorized/prohibited)
- Deliverable format

---

## Case Setup

### Folder Structure
```
CaseID/
├── 00-Intake/
├── 01-Evidence/
├── 02-Notes/
├── 03-Tasks/
├── 04-SOPs/
├── 05-Reports/
└── 99-Export/
```

### Naming Conventions
- **Dates:** YYYY-MM-DD format
- **Files:** `YYYY-MM-DD_Source_Description.ext`

---

## Key Milestones
- [ ] Authorization documented
- [ ] Scope clearly defined
- [ ] Folder structure created
- [ ] Investigation log started

---

## Resources
- OSINT Framework: https://osintframework.com/
- Intel Techniques: https://inteltechniques.com/
"""
)

MODULES["evidence-handling"] = SopModule(
    key="evidence-handling",
    title="Digital Evidence Collection & Preservation",
    filename="02-Evidence-Collection-and-Preservation.md",
    category="basic",
    default_md="""---
type: sop
category: evidence
version: 1.0
created: {date}
---

# Digital Evidence Collection & Preservation

## Purpose
Ensure evidence integrity through proper collection and preservation.

---

## Core Principles

1. **Authenticity** - Preserve original sources
2. **Integrity** - Never modify originals
3. **Reproducibility** - Document all steps

---

## Collection Methods

### Web Pages
1. Full screenshot (include URL bar)
2. Save complete HTML
3. Archive to Archive.is
4. Save to Wayback Machine

### Social Media
- Screenshot post with context
- Download media files
- Save page source
- Create archive link

### Images
```bash
# Extract metadata
exiftool -a -G1 image.jpg > metadata.txt

# Generate hash
shasum -a 256 image.jpg > image.sha256
```

---

## File Organization

Naming: `CaseID_YYYYMMDD_HHMMSS_Source_Type.ext`

Example: `2026-001_20260107_142345_Twitter_Screenshot.png`

---

## Resources
- ExifTool: https://exiftool.org/
- Archive.is: https://archive.is/
- Wayback Machine: https://web.archive.org/
"""
)

MODULES["person-investigation"] = SopModule(
    key="person-investigation",
    title="Person Investigation (OSINT)",
    filename="03-Person-Investigation.md",
    category="intermediate",
    default_md="""---
type: sop
category: person
version: 1.0
created: {date}
---

# Person Investigation (OSINT)

## Purpose
Build comprehensive profiles using lawful, public sources only.

---

## Phase 1: Baseline Profile

### Initial Identifiers
- Full legal name
- Known aliases
- Date of birth (if public)
- Locations
- Email/phone (from public sources)
- Social media handles

---

## Phase 2: Online Presence

### Social Media Platforms
- Facebook, LinkedIn, Twitter/X
- Instagram, TikTok, YouTube
- Reddit, GitHub

### Username Tools
- Sherlock: https://github.com/sherlock-project/sherlock
- WhatsMyName: https://whatsmyname.app/

---

## Phase 3: Public Records

- Property ownership
- Court records (PACER)
- Professional licenses
- Business registrations

---

## Phase 4: Network Mapping

- Professional connections
- Social networks
- Family relationships (public only)

---

## Legal Boundaries

### Permitted
- ✅ Public records
- ✅ Public social media
- ✅ Search engines

### Prohibited
- ❌ Hacking
- ❌ Impersonation
- ❌ Social engineering

---

## Resources
- OSINT Framework: https://osintframework.com/
- PACER: https://pacer.uscourts.gov/
"""
)

# ============================================================================
# PRESET PROFILES
# ============================================================================

PROFILES = {
    "quick": {
        "name": "Quick Start",
        "description": "Essential SOPs",
        "modules": ["case-intake", "evidence-handling", "reporting"]
    },
    "standard": {
        "name": "Standard Investigation",
        "description": "Most common types",
        "modules": ["case-intake", "evidence-handling", "person-investigation", 
                   "social-media", "reporting"]
    },
    "comprehensive": {
        "name": "Comprehensive Suite",
        "description": "All available SOPs",
        "modules": list(MODULES.keys())
    },
    "person": {
        "name": "Person-Focused",
        "description": "Person investigation emphasis",
        "modules": ["case-intake", "evidence-handling", "person-investigation",
                   "social-media", "geolocation", "reporting"]
    },
    "company": {
        "name": "Company-Focused",
        "description": "Business investigation",
        "modules": ["case-intake", "evidence-handling", "company-investigation",
                   "digital-evidence", "reporting"]
    }
}

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

def format_sop_content(content: str) -> str:
    """Replace {date} placeholder with current date"""
    return content.format(date=datetime.now().strftime("%Y-%m-%d"))


def write_sop_file(path: Path, content: str) -> None:
    """Write SOP with proper formatting"""
    content = format_sop_content(content)
    content = content.replace("\r\n", "\n").replace("\r", "\n").rstrip() + "\n"
    path.write_text(content, encoding="utf-8")


def generate_sops(case_dir: Path, modules: List[SopModule], quiet: bool = False) -> List[Path]:
    """Generate SOP files in the case directory"""
    sop_dir = case_dir / "04 - SOPs"
    sop_dir.mkdir(parents=True, exist_ok=True)
    
    created_files = []
    
    for module in modules:
        sop_path = sop_dir / module.filename
        
        if not quiet:
            print(f"  Creating: {module.title}")
        
        write_sop_file(sop_path, module.default_md)
        created_files.append(sop_path)
    
    return created_files


def list_modules() -> None:
    """Print available modules"""
    print("\nAvailable SOP Modules:")
    print("=" * 70)
    
    by_category = {"basic": [], "intermediate": [], "advanced": []}
    for module in MODULES.values():
        by_category[module.category].append(module)
    
    count = 1
    for category in ["basic", "intermediate", "advanced"]:
        print(f"\n{category.upper()}:")
        for module in sorted(by_category[category], key=lambda m: m.key):
            print(f"  {count}. {module.key:20} - {module.title}")
            count += 1


def list_profiles() -> None:
    """Print available profiles"""
    print("\nAvailable Profiles:")
    print("=" * 70)
    
    for key, profile in PROFILES.items():
        print(f"\n{key}:")
        print(f"  Name: {profile['name']}")
        print(f"  Description: {profile['description']}")
        print(f"  Modules: {', '.join(profile['modules'])}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate OSINT SOPs",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument("--case-dir", type=Path, help="Path to case directory")
    parser.add_argument("--profile", choices=list(PROFILES.keys()), help="SOP profile")
    parser.add_argument("--modules", type=str, help="Comma-separated module keys")
    parser.add_argument("--list-modules", action="store_true", help="List modules")
    parser.add_argument("--list-profiles", action="store_true", help="List profiles")
    parser.add_argument("--quiet", action="store_true", help="Suppress output")
    
    args = parser.parse_args()
    
    if args.list_modules:
        list_modules()
        return 0
    
    if args.list_profiles:
        list_profiles()
        return 0
    
    if not args.case_dir:
        print("Error: --case-dir required", file=sys.stderr)
        return 1
    
    case_dir = args.case_dir.expanduser().resolve()
    
    if not case_dir.exists():
        print(f"Error: Case directory not found: {case_dir}", file=sys.stderr)
        return 1
    
    # Select modules
    if args.modules:
        module_keys = [k.strip() for k in args.modules.split(",")]
        modules = [MODULES[k] for k in module_keys if k in MODULES]
        if not modules:
            print("Error: No valid modules specified", file=sys.stderr)
            return 1
    elif args.profile:
        module_keys = PROFILES[args.profile]["modules"]
        modules = [MODULES[k] for k in module_keys]
    else:
        module_keys = PROFILES["standard"]["modules"]
        modules = [MODULES[k] for k in module_keys]
    
    # Generate SOPs
    if not args.quiet:
        print(f"Generating {len(modules)} SOPs in {case_dir}...")
    
    created_files = generate_sops(case_dir, modules, quiet=args.quiet)
    
    if not args.quiet:
        print(f"✅ Created {len(created_files)} SOP files")
        for f in created_files:
            print(f"  - {f.name}")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())