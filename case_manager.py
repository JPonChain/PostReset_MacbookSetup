#!/usr/bin/env python3
"""
case_manager.py - CLI tool for managing legal/investigation cases in Obsidian
Standard library only, installable via pipx
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


class CaseManager:
    """Manage case folders and metadata within an Obsidian vault"""
    
    def __init__(self, vault_path: Optional[str] = None):
        self.vault_path = Path(vault_path or os.getenv(
            'OBSIDIAN_VAULT_PATH',
            str(Path.home() / 'Documents' / 'ObsidianVault')
        ))
        self.cases_dir = self.vault_path / 'Cases'
        
        if not self.vault_path.exists():
            print(f"⚠️  Warning: Vault does not exist at {self.vault_path}")
            print(f"Creating vault structure...")
            self.vault_path.mkdir(parents=True, exist_ok=True)
            self.cases_dir.mkdir(parents=True, exist_ok=True)
    
    def get_next_case_number(self, prefix: str = None) -> str:
        """Generate next case ID based on existing cases"""
        current_year = datetime.now().year
        
        if prefix:
            # Use custom prefix (e.g., INV, LIT)
            pattern = f"{prefix}-"
        else:
            # Use year-based prefix
            pattern = f"{current_year}-"
            prefix = str(current_year)
        
        # Find all existing case IDs with this prefix
        existing_numbers = []
        if self.cases_dir.exists():
            for case_folder in self.cases_dir.iterdir():
                if case_folder.is_dir() and case_folder.name.startswith(pattern):
                    # Extract number from "PREFIX-NNN - Name" format
                    parts = case_folder.name.split(' - ')[0].split('-')
                    if len(parts) >= 2:
                        try:
                            num = int(parts[-1])
                            existing_numbers.append(num)
                        except ValueError:
                            continue
        
        # Get next number
        if existing_numbers:
            next_num = max(existing_numbers) + 1
        else:
            next_num = 1
        
        return f"{prefix}-{next_num:03d}"
    
    @staticmethod
    def validate_case_id(case_id: str) -> bool:
        """Validate case ID format (e.g., 2026-001, CASE-123)"""
        if not re.match(r'^[A-Z0-9]+-[A-Z0-9]+$', case_id, re.IGNORECASE):
            print(f"❌ Invalid case ID format: {case_id}")
            print("   Expected format: YYYY-NNN or PREFIX-NNN (e.g., 2026-001)")
            return False
        return True
    
    @staticmethod
    def sanitize_name(name: str) -> str:
        """Sanitize name for use in folder/file names"""
        # Remove or replace problematic characters
        sanitized = re.sub(r'[<>:"/\\|?*]', '', name)
        sanitized = re.sub(r'\s+', ' ', sanitized).strip()
        return sanitized
    
    def get_case_folder_name(self, case_id: str, case_name: str) -> str:
        """Generate standardized folder name"""
        sanitized_name = self.sanitize_name(case_name)
        return f"{case_id} - {sanitized_name}"
    
    def case_exists(self, case_id: str) -> bool:
        """Check if a case already exists"""
        for item in self.cases_dir.iterdir():
            if item.is_dir() and item.name.startswith(f"{case_id} -"):
                return True
        return False
    
    def create_case(self, case_id: str, case_name: str) -> bool:
        """Create a new case with folder structure and initial files"""
        
        # Validation
        if not self.validate_case_id(case_id):
            return False
        
        if not case_name or not case_name.strip():
            print("❌ Case name cannot be empty")
            return False
        
        if self.case_exists(case_id):
            print(f"❌ Case {case_id} already exists")
            return False
        
        # Create case folder
        folder_name = self.get_case_folder_name(case_id, case_name)
        case_path = self.cases_dir / folder_name
        
        try:
            case_path.mkdir(parents=True, exist_ok=False)
        except FileExistsError:
            print(f"❌ Case folder already exists: {case_path}")
            return False
        
        # Create subfolders
        subfolders = [
            "00 - Intake",
            "01 - Evidence",
            "02 - Notes",
            "03 - Tasks",
            "99 - Export"
        ]
        
        for subfolder in subfolders:
            (case_path / subfolder).mkdir(exist_ok=True)
        
        # Create case.md with frontmatter
        case_md_path = case_path / "case.md"
        case_md_content = f"""---
case-id: {case_id}
case-name: {case_name}
status: active
created: {datetime.now().strftime('%Y-%m-%d')}
last-updated: {datetime.now().strftime('%Y-%m-%d')}
tags: [case]
---

# {case_id}: {case_name}

## Case Overview

**Status**: 🟢 Active  
**Created**: {datetime.now().strftime('%Y-%m-%d')}

## Quick Links

- [[{case_id} - Intake Notes|Intake Notes]]
- [[{case_id} - Evidence Log|Evidence Log]]
- [[{case_id} - Task List|Task List]]

## Case Summary

<!-- Brief description of the case -->

## Key Dates

- **Opened**: {datetime.now().strftime('%Y-%m-%d')}
- **Next Review**: 

## Current Status

<!-- Current status and next steps -->

## Notes

<!-- General case notes -->

---

## Folder Structure

```
{folder_name}/
├── 00 - Intake/       # Initial consultation and client info
├── 01 - Evidence/     # Documents, photos, recordings
├── 02 - Notes/        # Meeting notes, research
├── 03 - Tasks/        # Action items and deadlines
└── 99 - Export/       # Final reports and deliverables
```
"""
        
        case_md_path.write_text(case_md_content)
        
        # Create intake note
        intake_path = case_path / "00 - Intake" / f"{case_id} - Intake Notes.md"
        intake_content = f"""---
case-id: {case_id}
date: {datetime.now().strftime('%Y-%m-%d')}
type: intake
---

# Intake Notes: {case_name}

**Date**: {datetime.now().strftime('%Y-%m-%d')}  
**Case ID**: {case_id}

## Client Information

- **Name**: {case_name}
- **Contact**: 
- **Email**: 
- **Phone**: 
- **Address**: 

## Initial Consultation

**Date**: {datetime.now().strftime('%Y-%m-%d')}  
**Duration**: 

### Presenting Issue

<!-- What brought the client to you? -->

### Key Facts

- 
- 
- 

### Initial Assessment

<!-- Your initial thoughts and assessment -->

## Next Steps

- [ ] Document review
- [ ] Research relevant law/precedents
- [ ] Schedule follow-up meeting
- [ ] 

## Notes

<!-- Additional notes from intake -->

---

Back to [[case|Case Overview]]
"""
        
        intake_path.write_text(intake_content)
        
        # Create task list
        task_path = case_path / "03 - Tasks" / f"{case_id} - Task List.md"
        task_content = f"""---
case-id: {case_id}
type: tasks
---

# Task List: {case_id}

## Immediate Tasks

- [ ] Complete intake documentation
- [ ] Gather initial evidence
- [ ] Client agreement/contract

## Pending Tasks

- [ ] 

## Completed Tasks

- [x] Case created ({datetime.now().strftime('%Y-%m-%d')})

---

Back to [[case|Case Overview]]
"""
        
        task_path.write_text(task_content)
        
        print(f"✅ Case created successfully!")
        print(f"   ID: {case_id}")
        print(f"   Name: {case_name}")
        print(f"   Path: {case_path}")
        print(f"\n📁 Subfolders created:")
        for subfolder in subfolders:
            print(f"   • {subfolder}")
        print(f"\n📄 Initial files:")
        print(f"   • case.md")
        print(f"   • 00 - Intake/{case_id} - Intake Notes.md")
        print(f"   • 03 - Tasks/{case_id} - Task List.md")
        
        return True

    def list_cases(self, status_filter: Optional[str] = None) -> List[Dict]:
        """List all cases with metadata"""

        if not self.cases_dir.exists():
            print(f"⚠️  Cases directory does not exist: {self.cases_dir}")
            return []

        cases: List[Dict] = []

        for case_folder in sorted(self.cases_dir.iterdir()):
            if not case_folder.is_dir():
                continue

            case_md = case_folder / "case.md"
            if not case_md.exists():
                continue

            # Parse frontmatter
            try:
                content = case_md.read_text()
                if content.startswith('---'):
                    parts = content.split('---', 2)
                    if len(parts) >= 3:
                        frontmatter = parts[1].strip()
                        metadata: Dict[str, str] = {}
                        for line in frontmatter.split('\n'):
                            if ':' in line:
                                key, value = line.split(':', 1)
                                metadata[key.strip()] = value.strip()

                        # Filter by status if requested
                        if status_filter and metadata.get('status', '') != status_filter:
                            continue

                        cases.append({
                            'case_id': metadata.get('case-id', 'unknown'),
                            'name': metadata.get('case-name', 'unknown'),
                            'status': metadata.get('status', 'unknown'),
                            'created': metadata.get('created', 'unknown'),
                            'path': str(case_folder)
                        })
            except Exception as e:
                print(f"⚠️  Error reading {case_md}: {e}", file=sys.stderr)
                continue

        return cases
    def display_cases(self, cases: List[Dict]):
        """Display cases in a formatted table"""
        if not cases:
            print("No cases found.")
            return
        
        print(f"\n📂 Found {len(cases)} case(s):\n")
        print(f"{'ID':<15} {'Name':<30} {'Status':<10} {'Created':<12}")
        print("─" * 70)
        
        for case in cases:
            status_icon = "🟢" if case['status'] == 'active' else "🔴" if case['status'] == 'closed' else "⚪"
            print(f"{case['case_id']:<15} {case['name']:<30} {status_icon} {case['status']:<10} {case['created']:<12}")
        
        print()
    
    def open_case(self, case_id: str, obsidian_only: bool = False) -> bool:
        """Open a case folder (in Obsidian or Finder)"""
        
        for case_folder in self.cases_dir.iterdir():
            if case_folder.is_dir() and case_folder.name.startswith(f"{case_id} -"):
                print(f"📂 Case found: {case_folder.name}")
                print(f"   Path: {case_folder}")
                
                if obsidian_only:
                    # Open Obsidian to the vault (Obsidian will show the case)
                    vault_uri = f"obsidian://open?vault={self.vault_path.name}"
                    try:
                        subprocess.run(['open', vault_uri], check=True)
                        print(f"   ✅ Opened in Obsidian")
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        print(f"   ⚠️  Could not open Obsidian. Opening vault folder instead...")
                        try:
                            subprocess.run(['open', '-a', 'Obsidian', str(self.vault_path)], check=True)
                            print(f"   ✅ Opened Obsidian")
                        except:
                            print(f"   ℹ️  Please open Obsidian manually and navigate to: {case_folder}")
                else:
                    # Open in Finder
                    try:
                        subprocess.run(['open', str(case_folder)], check=True)
                        print(f"   ✅ Opened in Finder")
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        print(f"   ℹ️  Copy the path above to open manually")
                
                return True
        
        print(f"❌ Case {case_id} not found")
        return False


def main():
    """Main CLI entry point"""
    
    parser = argparse.ArgumentParser(
        description='Case management tool for Obsidian vaults',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  case-manager new --id 2026-001 --name "Smith v. Jones"
  case-manager new --id INV-042 --name "Corporate Investigation"
  case-manager list
  case-manager list --status active
  case-manager open --id 2026-001
  
Environment Variables:
  OBSIDIAN_VAULT_PATH    Path to Obsidian vault (default: ~/Documents/ObsidianVault)
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # New case command
    new_parser = subparsers.add_parser('new', help='Create a new case')
    new_parser.add_argument('--id', required=True, help='Case ID (e.g., 2026-001)')
    new_parser.add_argument('--name', required=True, help='Case name')
    new_parser.add_argument('--vault', help='Override vault path')
    
    # List cases command
    list_parser = subparsers.add_parser('list', help='List all cases')
    list_parser.add_argument('--status', choices=['active', 'closed', 'pending'],
                            help='Filter by status')
    list_parser.add_argument('--vault', help='Override vault path')
    
    # Open case command
    open_parser = subparsers.add_parser('open', help='Open a case folder')
    open_parser.add_argument('--id', required=True, help='Case ID')
    open_parser.add_argument('--obsidian', action='store_true', help='Open in Obsidian only (default)')
    open_parser.add_argument('--finder', action='store_true', help='Open in Finder instead')
    open_parser.add_argument('--vault', help='Override vault path')
    
    # Generate case ID command
    generate_parser = subparsers.add_parser('generate-id', help='Generate next case ID')
    generate_parser.add_argument('--prefix', help='Prefix for case ID (default: current year)')
    generate_parser.add_argument('--vault', help='Override vault path')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    # Initialize manager
    vault_path = getattr(args, 'vault', None)
    manager = CaseManager(vault_path)
    
    # Execute command
    if args.command == 'new':
        success = manager.create_case(args.id, args.name)
        return 0 if success else 1
    
    elif args.command == 'list':
        cases = manager.list_cases(getattr(args, 'status', None))
        manager.display_cases(cases)
        return 0
    
    elif args.command == 'open':
        # Default to Obsidian unless --finder is specified
        obsidian_only = not args.finder
        success = manager.open_case(args.id, obsidian_only)
        return 0 if success else 1
    
    elif args.command == 'generate-id':
        next_id = manager.get_next_case_number(args.prefix)
        print(f"📋 Next available Case ID: {next_id}")
        return 0
    
    return 0


if __name__ == '__main__':
    sys.exit(main())