#!/usr/bin/env bash
#
# setup_case_sops.sh - Generate Standard Operating Procedures for OSINT cases
# Called by case_manager.sh during case creation or vault setup
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

CASE_DIR="${1:-}"
CASE_ID="${2:-}"
CASE_NAME="${3:-}"

# ============================================================================
# SOP TEMPLATES
# ============================================================================

generate_social_media_sop() {
    local case_dir="$1"
    local sop_dir="$case_dir/04 - SOPs"
    mkdir -p "$sop_dir"
    
    cat > "$sop_dir/SOP - Social Media Investigation.md" <<'EOF'
---
type: sop
category: social-media
version: 1.0
last-updated: {{date}}
---

# SOP: Social Media Investigation

## Purpose
Document standard procedures for conducting social media investigations across multiple platforms.

## Scope
This SOP covers: Facebook, Instagram, Twitter/X, LinkedIn, TikTok, Snapchat, Reddit, and other social platforms.

---

## Pre-Investigation Checklist

- [ ] Define investigation objectives
- [ ] Identify target accounts/usernames
- [ ] Document legal authorization/scope
- [ ] Set up burner accounts (if needed)
- [ ] Configure VPN/anonymization tools
- [ ] Prepare evidence collection tools

---

## Phase 1: Initial Reconnaissance

### 1.1 Username Enumeration
- [ ] Check username across multiple platforms using tools:
  - Sherlock
  - WhatsMyName
  - Namechk
  - KnowEm
- [ ] Document all discovered accounts
- [ ] Create account mapping spreadsheet

### 1.2 Profile Information Gathering
For each identified account:
- [ ] Full name (display name)
- [ ] Username/handle
- [ ] Bio/description
- [ ] Profile photo (download & archive)
- [ ] Cover/header images
- [ ] Account creation date (if available)
- [ ] Follower/following counts
- [ ] Contact information (email, phone)
- [ ] Location information
- [ ] Website/external links

### 1.3 Content Analysis
- [ ] Posts/tweets (date, time, content)
- [ ] Photos/videos (download originals)
- [ ] Comments/replies
- [ ] Likes/reactions
- [ ] Shares/retweets
- [ ] Tags/mentions
- [ ] Hashtags used

---

## Phase 2: Deep Analysis

### 2.1 Connection Mapping
- [ ] Identify frequent contacts
- [ ] Map friend/follower networks
- [ ] Document groups/communities
- [ ] Track recurring interactions
- [ ] Identify potential aliases

### 2.2 Metadata Extraction
For each piece of content:
- [ ] EXIF data from images
- [ ] Geolocation data
- [ ] Timestamp information
- [ ] Device information
- [ ] Upload source

### 2.3 Pattern Analysis
- [ ] Posting frequency/schedule
- [ ] Language patterns
- [ ] Topic analysis
- [ ] Sentiment tracking
- [ ] Behavioral patterns

---

## Phase 3: Evidence Collection

### 3.1 Archiving Methods
- [ ] Screenshots (full page)
  - Use Firefox Screenshot tool
  - Archive.is for web archiving
- [ ] Video downloads (Video Download Helper)
- [ ] Page source HTML
- [ ] Archive.org snapshots
- [ ] JSON exports (where available)

### 3.2 Chain of Custody
For each piece of evidence:
- [ ] Collection date/time (with timezone)
- [ ] Collector name
- [ ] Source URL
- [ ] File hash (SHA-256)
- [ ] Storage location
- [ ] Access log

### 3.3 Evidence Organization
```
Case/01 - Evidence/Social Media/
├── Platform_Name/
│   ├── Profile_Info/
│   ├── Posts/
│   ├── Images/
│   ├── Videos/
│   ├── Screenshots/
│   └── Metadata/
```

---

## Phase 4: Documentation

### 4.1 Investigation Report Sections
1. Executive Summary
2. Methodology
3. Accounts Identified
4. Key Findings
5. Timeline of Activity
6. Network Analysis
7. Evidence Index
8. Conclusions

### 4.2 Timeline Creation
- [ ] Chronological post history
- [ ] Account creation dates
- [ ] Significant events
- [ ] Activity gaps/patterns

---

## Platform-Specific Procedures

### Facebook/Instagram
- [ ] Check "About" section thoroughly
- [ ] Review tagged photos
- [ ] Check-ins and locations
- [ ] Events attended
- [ ] Pages liked/followed
- [ ] Groups memberships

### Twitter/X
- [ ] Advanced search operators
- [ ] Analyze retweets/quotes
- [ ] Check lists membership
- [ ] Moments participation
- [ ] Archived tweets (via Wayback)

### LinkedIn
- [ ] Employment history
- [ ] Education background
- [ ] Skills/endorsements
- [ ] Connections (1st/2nd degree)
- [ ] Groups/organizations
- [ ] Publications/certifications

### TikTok
- [ ] Duets/stitches
- [ ] Sounds used
- [ ] Hashtag challenges
- [ ] Following/followers
- [ ] Liked videos

---

## Tools & Resources

### Essential Tools
- **Browser Extensions**:
  - RevEye (reverse image search)
  - EXIF Viewer
  - Video Download Helper
  - Archive Page
  
- **Command Line**:
  - Sherlock (username search)
  - Social Mapper
  - Twint (Twitter)
  - Instaloader (Instagram)

- **Online Tools**:
  - Archive.is
  - Wayback Machine
  - Google Advanced Search
  - TinEye

### Best Practices
1. Always use VPN/anonymization
2. Never use personal accounts
3. Document everything immediately
4. Maintain chain of custody
5. Regular backups of evidence
6. Respect platform ToS and legal boundaries

---

## Legal Considerations

- [ ] Verify investigation authority
- [ ] Understand platform Terms of Service
- [ ] Know applicable privacy laws
- [ ] Document consent/authorization
- [ ] Consider jurisdiction issues
- [ ] Consult legal counsel when uncertain

---

## Quality Assurance

- [ ] All evidence properly archived
- [ ] Chain of custody complete
- [ ] Screenshots include timestamps
- [ ] Metadata extracted and logged
- [ ] Report peer-reviewed
- [ ] Evidence backed up securely

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | {{date}} | Initial creation | - |

---

**Related SOPs**: 
- [[SOP - Digital Evidence Collection]]
- [[SOP - Open Source Intelligence]]
- [[SOP - Report Writing]]
EOF
}

generate_person_investigation_sop() {
    local case_dir="$1"
    local sop_dir="$case_dir/04 - SOPs"
    mkdir -p "$sop_dir"
    
    cat > "$sop_dir/SOP - Person Investigation.md" <<'EOF'
---
type: sop
category: person-investigation
version: 1.0
last-updated: {{date}}
---

# SOP: Person Investigation (Individual Background)

## Purpose
Comprehensive procedures for investigating individuals using open source intelligence methods.

## Scope
Background checks, due diligence, locating persons, identity verification.

---

## Investigation Framework

### Phase 1: Initial Information Gathering

#### 1.1 Basic Identifiers
- [ ] Full legal name (including middle name)
- [ ] Date of birth
- [ ] Social Security Number (if authorized)
- [ ] Driver's License Number
- [ ] Previous names/aliases
- [ ] Maiden name (if applicable)

#### 1.2 Contact Information
- [ ] Current address
- [ ] Previous addresses (5-10 years)
- [ ] Phone numbers (current & historical)
- [ ] Email addresses
- [ ] Social media handles

---

## Phase 2: Public Records Search

### 2.1 Government Records
- [ ] Birth records
- [ ] Death records (relatives)
- [ ] Marriage/divorce records
- [ ] Property records
- [ ] Tax records (public liens)
- [ ] Voter registration
- [ ] Business licenses

### 2.2 Court Records
- [ ] Civil court cases
- [ ] Criminal records
- [ ] Traffic violations
- [ ] Small claims
- [ ] Bankruptcy filings
- [ ] Liens and judgments

### 2.3 Professional Records
- [ ] Professional licenses
- [ ] Certifications
- [ ] Disciplinary actions
- [ ] Board memberships
- [ ] Academic credentials

---

## Phase 3: Online Presence

### 3.1 Social Media (See Social Media SOP)
- [ ] Facebook
- [ ] LinkedIn
- [ ] Twitter/X
- [ ] Instagram
- [ ] TikTok
- [ ] Other platforms

### 3.2 Digital Footprint
- [ ] Personal websites/blogs
- [ ] Forum posts
- [ ] Comments on articles
- [ ] Reviews (Google, Yelp, etc.)
- [ ] GitHub/professional portfolios
- [ ] YouTube channels

### 3.3 Search Engine Research
- [ ] Google (quoted name searches)
- [ ] Bing
- [ ] DuckDuckGo
- [ ] Specialized search engines
- [ ] Image searches
- [ ] News archives

---

## Phase 4: Financial & Assets

### 4.1 Property Ownership
- [ ] Real estate holdings
- [ ] Property values
- [ ] Mortgage information
- [ ] Property tax records
- [ ] HOA memberships

### 4.2 Business Interests
- [ ] Business ownership
- [ ] Corporate filings
- [ ] Partnership agreements
- [ ] LLC memberships
- [ ] DBA registrations

### 4.3 Financial Indicators
- [ ] Bankruptcy history
- [ ] Foreclosures
- [ ] Tax liens
- [ ] Judgments
- [ ] UCC filings

---

## Phase 5: Associates & Relationships

### 5.1 Family Connections
- [ ] Spouse/partner
- [ ] Children
- [ ] Parents
- [ ] Siblings
- [ ] Extended family

### 5.2 Professional Network
- [ ] Current employer
- [ ] Previous employers
- [ ] Colleagues
- [ ] Business partners
- [ ] Professional associations

### 5.3 Social Connections
- [ ] Friends (social media)
- [ ] Neighbors
- [ ] Community involvement
- [ ] Club memberships

---

## Phase 6: Location Intelligence

### 6.1 Address History
- [ ] Current residence
- [ ] Previous addresses
- [ ] Length at each address
- [ ] Property ownership
- [ ] Neighbors

### 6.2 Location Patterns
- [ ] Check-ins (social media)
- [ ] GPS metadata (photos)
- [ ] Frequent locations
- [ ] Travel patterns
- [ ] Work location

---

## Tools & Databases

### Free Resources
- [ ] Google Advanced Search
- [ ] Facebook Graph Search
- [ ] LinkedIn
- [ ] Whitepages
- [ ] TruePeopleSearch
- [ ] FastPeopleSearch
- [ ] County recorder offices
- [ ] Court websites

### Paid Services (if authorized)
- [ ] TLO/TransUnion
- [ ] LexisNexis
- [ ] BeenVerified
- [ ] Spokeo
- [ ] Intelius
- [ ] CLEAR

### Government Resources
- [ ] PACER (court records)
- [ ] County assessor sites
- [ ] Secretary of State databases
- [ ] Professional licensing boards
- [ ] Sex offender registries

---

## Documentation Template

### Subject Profile
```
Name: [Full Legal Name]
DOB: [MM/DD/YYYY]
SSN: [XXX-XX-XXXX] (if available)
Current Address: [Full Address]
Phone: [Numbers]
Email: [Addresses]

Last Known Employment:
Company: [Name]
Position: [Title]
Duration: [Start - End]

Family:
Spouse: [Name]
Children: [Names, Ages]
Parents: [Names]
```

---

## Reporting Standards

### Report Sections
1. **Executive Summary**
   - Subject identification
   - Key findings
   - Red flags/concerns

2. **Methodology**
   - Sources consulted
   - Tools used
   - Search parameters

3. **Findings by Category**
   - Personal information
   - Employment history
   - Education
   - Financial records
   - Legal history
   - Online presence
   - Associates

4. **Timeline**
   - Chronological history
   - Significant events

5. **Verification Status**
   - Confirmed information
   - Unverified claims
   - Conflicting data

6. **Recommendations**
   - Further investigation needed
   - Red flags to address

---

## Legal & Ethical Guidelines

### Compliance Requirements
- [ ] Fair Credit Reporting Act (FCRA)
- [ ] Privacy laws
- [ ] Terms of Service
- [ ] Data protection regulations
- [ ] Permissible purposes

### Prohibited Activities
- ❌ Pretexting
- ❌ Hacking/unauthorized access
- ❌ Impersonation
- ❌ Stalking/harassment
- ❌ Invasion of privacy

---

## Quality Control Checklist

- [ ] All sources documented
- [ ] Information cross-referenced
- [ ] Dates verified
- [ ] Spelling/names confirmed
- [ ] Contact info validated
- [ ] Records organized chronologically
- [ ] Report proofread
- [ ] Evidence archived

---

**Related SOPs**:
- [[SOP - Social Media Investigation]]
- [[SOP - Background Checks]]
- [[SOP - Asset Searches]]
EOF
}

generate_digital_evidence_sop() {
    local case_dir="$1"
    local sop_dir="$case_dir/04 - SOPs"
    mkdir -p "$sop_dir"
    
    cat > "$sop_dir/SOP - Digital Evidence Collection.md" <<'EOF'
---
type: sop
category: digital-evidence
version: 1.0
last-updated: {{date}}
---

# SOP: Digital Evidence Collection & Preservation

## Purpose
Ensure proper collection, preservation, and documentation of digital evidence to maintain admissibility and integrity.

---

## Core Principles

### 1. Chain of Custody
Every piece of evidence must have:
- Collection date/time (with timezone)
- Collector identification
- Source location/URL
- File hash (integrity verification)
- Transfer log
- Storage location

### 2. Evidence Integrity
- Original evidence never modified
- Working copies for analysis
- Hash verification at each step
- Audit trail maintained

### 3. Documentation
- Screenshot everything
- Document all actions
- Maintain detailed logs
- Record tool versions

---

## Phase 1: Preparation

### 1.1 Setup Evidence Collection Environment
- [ ] Clean workstation
- [ ] VPN/proxy configured
- [ ] Screen recording software ready
- [ ] Time sync verified (NTP)
- [ ] Tools tested and ready

### 1.2 Documentation Setup
- [ ] Evidence log template
- [ ] Chain of custody forms
- [ ] Collection checklist
- [ ] Folder structure created

```
Case/01 - Evidence/
├── Web_Archives/
├── Screenshots/
├── Documents/
├── Images/
├── Videos/
├── Metadata/
└── Hash_Logs/
```

---

## Phase 2: Web Evidence Collection

### 2.1 Web Page Archiving
For each webpage:

1. **Full Page Screenshot**
   - [ ] Use Firefox built-in screenshot (shows full page)
   - [ ] Include URL bar in screenshot
   - [ ] Timestamp visible
   - [ ] Save as PNG (lossless)

2. **Archive Services**
   - [ ] Archive.is snapshot
   - [ ] Wayback Machine save
   - [ ] Local HTML save (File > Save Page As > Complete)

3. **Source Code**
   - [ ] Right-click > View Page Source
   - [ ] Save HTML source
   - [ ] Save linked resources

4. **Metadata Documentation**
   ```
   URL: [Full URL]
   Date Collected: [YYYY-MM-DD HH:MM:SS TZ]
   Archive URLs:
     - Archive.is: [URL]
     - Wayback: [URL]
   Hash (HTML): [SHA-256]
   Collector: [Name]
   ```

### 2.2 Social Media Posts
- [ ] Screenshot individual post
- [ ] Screenshot profile
- [ ] Screenshot URL
- [ ] Archive.is link
- [ ] JSON export (if available)
- [ ] Download embedded media

### 2.3 Video Evidence
Tools: Video Download Helper, youtube-dl, yt-dlp

- [ ] Download highest quality available
- [ ] Save video description/comments
- [ ] Screenshot video info page
- [ ] Extract metadata
- [ ] Create hash

---

## Phase 3: Image Evidence

### 3.1 Image Collection
- [ ] Download original resolution
- [ ] Do not screenshot (loses metadata)
- [ ] Use "Save Image As" or download link
- [ ] Preserve original filename

### 3.2 EXIF Metadata Extraction
Use: EXIF Viewer browser extension, exiftool

Required metadata:
- [ ] Camera make/model
- [ ] Date/time taken
- [ ] GPS coordinates (if present)
- [ ] Software used
- [ ] Original dimensions
- [ ] File modification dates

Command:
```bash
exiftool -a -G1 image.jpg > image_metadata.txt
```

### 3.3 Reverse Image Search
- [ ] Google Images
- [ ] TinEye
- [ ] Yandex
- [ ] Bing
- Document all findings

---

## Phase 4: Document Evidence

### 4.1 PDF Documents
- [ ] Download original
- [ ] Extract metadata
- [ ] OCR if needed
- [ ] Create hash

### 4.2 Office Documents
- [ ] Download without opening
- [ ] Extract metadata:
  - Author
  - Creation date
  - Modification date
  - Company
  - Last saved by
- [ ] Convert to PDF for archiving

### 4.3 Email Evidence
- [ ] Forward as attachment (preserves headers)
- [ ] Screenshot email
- [ ] Save headers separately
- [ ] Document email path

---

## Phase 5: Hashing & Verification

### 5.1 Generate File Hashes
For every collected file:

```bash
# SHA-256 hash
shasum -a 256 filename > filename.sha256

# MD5 hash (for compatibility)
md5 filename > filename.md5
```

### 5.2 Hash Log Format
```
Filename: evidence_001.png
SHA-256: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
MD5: 098f6bcd4621d373cade4e832627b4f6
Size: 1,234,567 bytes
Date Collected: 2026-01-07 14:23:45 PST
Collector: [Name]
Source: https://example.com/page
```

---

## Phase 6: Storage & Organization

### 6.1 Folder Naming Convention
```
YYYY-MM-DD_HH-MM_SourceType_Description/
```

Example:
```
2026-01-07_14-23_Facebook_Profile-Screenshot/
2026-01-07_15-45_Website_Archive/
```

### 6.2 File Naming Convention
```
CaseID_YYYYMMDD_HHMMSS_Source_Description.ext
```

Example:
```
2026-001_20260107_142345_FB_ProfilePhoto.jpg
2026-001_20260107_150000_Twitter_Post-Screenshot.png
```

### 6.3 Evidence Index
Maintain spreadsheet:

| Evidence ID | Date | Time | Source | Type | Filename | Hash | Location | Notes |
|-------------|------|------|--------|------|----------|------|----------|-------|
| EVD-001 | 2026-01-07 | 14:23 | Facebook | Screenshot | ... | ... | ... | ... |

---

## Phase 7: Chain of Custody

### 7.1 Chain of Custody Form
For each piece of evidence:

```
Evidence ID: EVD-001
Case Number: 2026-001
Description: Facebook profile screenshot
Collected By: [Name]
Date/Time: 2026-01-07 14:23:45 PST
Source: https://facebook.com/username
Hash: [SHA-256]

Transfer Log:
Date/Time | From | To | Purpose | Signature
----------|------|----|---------|-----------
2026-01-07 14:23 | Collector | Evidence Storage | Initial collection | [Signature]
```

---

## Tools Reference

### Browser Extensions (Firefox)
- Archive Page
- EXIF Viewer
- Video Download Helper
- RevEye Reverse Image Search
- Full Page Screen Capture

### Command Line Tools
```bash
# Metadata extraction
exiftool -a filename

# Hash generation
shasum -a 256 filename
md5 filename

# Video download
yt-dlp [URL]

# Web archiving
wget --mirror --page-requisites [URL]
```

### Online Tools
- Archive.is
- Wayback Machine (web.archive.org)
- TinEye
- Google Reverse Image Search

---

## Quality Assurance Checklist

- [ ] All evidence has unique ID
- [ ] Hashes generated and verified
- [ ] Chain of custody complete
- [ ] Screenshots include timestamps
- [ ] URLs visible in screenshots
- [ ] Metadata extracted
- [ ] Evidence backed up
- [ ] Index updated
- [ ] Documentation complete

---

## Legal Considerations

- [ ] Proper authorization obtained
- [ ] Privacy laws considered
- [ ] Terms of Service reviewed
- [ ] Admissibility standards met
- [ ] Expert testimony prepared (if needed)

---

**Related SOPs**:
- [[SOP - Social Media Investigation]]
- [[SOP - Report Writing]]
- [[SOP - Quality Control]]
EOF
}

generate_osint_methodology_sop() {
    local case_dir="$1"
    local sop_dir="$case_dir/04 - SOPs"
    mkdir -p "$sop_dir"
    
    cat > "$sop_dir/SOP - OSINT Methodology.md" <<'EOF'
---
type: sop
category: osint-general
version: 1.0
last-updated: {{date}}
---

# SOP: Open Source Intelligence (OSINT) Methodology

## Purpose
Establish standardized approach for conducting open source intelligence investigations.

---

## OSINT Intelligence Cycle

### 1. Planning & Direction
- [ ] Define intelligence requirements
- [ ] Identify information gaps
- [ ] Determine collection priorities
- [ ] Establish timeline
- [ ] Assign resources

### 2. Collection
- [ ] Identify relevant sources
- [ ] Gather raw information
- [ ] Document sources
- [ ] Maintain evidence integrity

### 3. Processing
- [ ] Organize collected data
- [ ] Verify authenticity
- [ ] Extract key information
- [ ] Tag and categorize

### 4. Analysis
- [ ] Identify patterns
- [ ] Connect relationships
- [ ] Assess reliability
- [ ] Draw conclusions

### 5. Dissemination
- [ ] Prepare reports
- [ ] Present findings
- [ ] Provide recommendations
- [ ] Archive materials

---

## Source Categories

### Public Records
- Government databases
- Court records
- Property records
- Business registrations
- Professional licenses

### Online Sources
- Websites
- Social media
- Forums/discussion boards
- Blogs
- News articles

### Commercial Data
- Business directories
- Professional databases
- Public data aggregators
- Subscription services

### Technical Sources
- Domain registration (WHOIS)
- IP address data
- Network infrastructure
- Code repositories

---

## Search Techniques

### Google Advanced Search
```
"exact phrase"
site:example.com
filetype:pdf
inurl:keyword
intitle:keyword
cache:example.com
related:example.com
```

### Boolean Operators
- AND: Both terms
- OR: Either term
- NOT: Exclude term
- ( ): Group terms
- *: Wildcard

### Social Media Search
- Platform-specific operators
- Hashtag analysis
- Geolocation searches
- Advanced filters

---

## Verification & Validation

### Source Credibility Assessment
1. **Primary vs Secondary**
   - Primary: Original source
   - Secondary: Reporting on primary

2. **Reliability Factors**
   - [ ] Author credentials
   - [ ] Publication date
   - [ ] Source reputation
   - [ ] Corroborating sources
   - [ ] Potential bias

### Cross-Reference Methods
- Multiple independent sources
- Official vs unofficial
- Contemporary vs historical
- Direct vs reported

### Red Flags
- ⚠️ Single source only
- ⚠️ No attribution
- ⚠️ Outdated information
- ⚠️ Contradictory data
- ⚠️ Unverifiable claims

---

## Data Organization

### Folder Structure
```
Case/
├── 00 - Intake/
├── 01 - Evidence/
│   ├── Web_Archives/
│   ├── Documents/
│   ├── Images/
│   ├── Videos/
│   └── Social_Media/
├── 02 - Notes/
│   ├── Research_Notes/
│   ├── Interview_Notes/
│   └── Analysis/
├── 03 - Tasks/
├── 04 - SOPs/
├── 05 - Reports/
└── 99 - Export/
```

### Naming Conventions
- Dates: YYYY-MM-DD
- Files: CaseID_Date_Source_Description
- Folders: Category_Subcategory

---

## Privacy & Ethics

### Operational Security
- [ ] Use VPN/proxy
- [ ] Burner accounts
- [ ] Separate browser profiles
- [ ] No personal information
- [ ] Clear cookies/cache

### Ethical Guidelines
- Respect privacy laws
- Follow Terms of Service
- No social engineering
- No unauthorized access
- Document methods transparently

### Legal Boundaries
- ✅ Publicly available information
- ✅ Authorized access
- ✅ Proper attribution
- ❌ Hacking/cracking
- ❌ Impersonation
- ❌ Harassment

---

## Tools & Resources

### Essential Browser Extensions
- Archive Page
- EXIF Viewer
- RevEye
- Video Download Helper
- User-Agent Switcher

### Online Tools
- Wayback Machine
- Archive.is
- Google Advanced Search
- TinEye
- OSINT Framework

### Command Line
- whois
- nslookup/dig
- curl/wget
- exiftool
- youtube-dl/yt-dlp

---

## Reporting Standards

### Report Structure
1. Executive Summary
2. Scope & Methodology
3. Sources Consulted
4. Findings (by category)
5. Analysis & Conclusions
6. Recommendations
7. Appendices

### Documentation Requirements
- All sources cited
- Methods described
- Timeline included
- Evidence indexed
- Limitations noted

---

## Quality Control

### Pre-Submission Checklist
- [ ] All facts verified
- [ ] Sources documented
- [ ] Evidence archived
- [ ] Chain of custody complete
- [ ] Report proofread
- [ ] Peer review conducted
- [ ] Client deliverables prepared

---

**Related SOPs**:
- [[SOP - Social Media Investigation]]
- [[SOP - Person Investigation]]
- [[SOP - Digital Evidence Collection]]
- [[SOP - Report Writing]]
EOF
}

generate_company_investigation_sop() {
    local case_dir="$1"
    local sop_dir="$case_dir/04 - SOPs"
    mkdir -p "$sop_dir"
    
    cat > "$sop_dir/SOP - Company Investigation.md" <<'EOF'
---
type: sop
category: company-investigation
version: 1.0
last-updated: {{date}}
---

# SOP: Company & Business Investigation

## Purpose
Standardized procedures for investigating companies, businesses, and corporate entities using OSINT methods.

---

## Phase 1: Basic Company Information

### 1.1 Legal Entity Details
- [ ] Full legal name
- [ ] DBA (Doing Business As) names
- [ ] EIN (Employer Identification Number)
- [ ] Business structure (LLC, Corp, Partnership, etc.)
- [ ] State of incorporation
- [ ] Date of incorporation
- [ ] Registered agent
- [ ] Principal office address

### 1.2 Registration & Licenses
- [ ] Secretary of State filings
- [ ] Business licenses
- [ ] Professional licenses
- [ ] Industry certifications
- [ ] Tax registrations
- [ ] Foreign qualifications

---

## Phase 2: Corporate Structure

### 2.1 Ownership & Control
- [ ] Shareholders/members
- [ ] Percentage ownership
- [ ] Directors
- [ ] Officers (CEO, CFO, etc.)
- [ ] Parent companies
- [ ] Subsidiaries
- [ ] Affiliated entities

### 2.2 Corporate Filings
- [ ] Articles of Incorporation
- [ ] Bylaws (if available)
- [ ] Annual reports
- [ ] Amendments
- [ ] Merger documents
- [ ] Dissolution filings

---

## Phase 3: Financial Information

### 3.1 Public Financial Data
- [ ] Annual revenue (estimates)
- [ ] Employee count
- [ ] Industry classification (NAICS)
- [ ] Credit reports (D&B)
- [ ] Stock information (if public)
- [ ] SEC filings (10-K, 10-Q, 8-K)

### 3.2 Financial Health Indicators
- [ ] Liens and judgments
- [ ] Bankruptcy filings
- [ ] Tax liens
- [ ] UCC filings
- [ ] Lawsuits (plaintiff/defendant)

---

## Phase 4: Online Presence

### 4.1 Digital Assets
- [ ] Official website(s)
- [ ] Domain registration (WHOIS)
- [ ] Social media accounts
  - LinkedIn company page
  - Facebook
  - Twitter/X
  - Instagram
  - YouTube
- [ ] Mobile apps
- [ ] Email domains

### 4.2 Online Reputation
- [ ] Customer reviews (Google, Yelp, BBB)
- [ ] Complaints (BBB, FTC, state AG)
- [ ] News articles
- [ ] Press releases
- [ ] Industry publications
- [ ] Forum discussions

### 4.3 Technical Infrastructure
- [ ] IP addresses
- [ ] Hosting provider
- [ ] DNS records
- [ ] SSL certificates
- [ ] Technology stack
- [ ] Email infrastructure

---

## Phase 5: Key Personnel

### 5.1 Executive Team
For each key person:
- [ ] Full name and title
- [ ] Background (LinkedIn)
- [ ] Previous employment
- [ ] Education
- [ ] Professional licenses
- [ ] Legal history
- [ ] Social media presence

### 5.2 Employee Intelligence
- [ ] Total employee count
- [ ] Key employees (LinkedIn)
- [ ] Turnover indicators
- [ ] Glassdoor reviews
- [ ] Job postings

---

## Phase 6: Business Operations

### 6.1 Products & Services
- [ ] Main offerings
- [ ] Target market
- [ ] Pricing (if available)
- [ ] Distribution channels
- [ ] Competitors

### 6.2 Locations & Facilities
- [ ] Headquarters
- [ ] Branch offices
- [ ] Manufacturing facilities
- [ ] Warehouses
- [ ] Retail locations

### 6.3 Business Relationships
- [ ] Major customers
- [ ] Suppliers/vendors
- [ ] Partners
- [ ] Distributors
- [ ] Franchisees

---

## Phase 7: Legal & Compliance

### 7.1 Litigation History
- [ ] Civil lawsuits (state & federal)
- [ ] Criminal cases
- [ ] Regulatory actions
- [ ] Patent disputes
- [ ] Contract disputes
- [ ] Employment disputes

### 7.2 Regulatory Compliance
- [ ] Industry-specific regulations
- [ ] OSHA violations
- [ ] EPA violations
- [ ] Labor violations
- [ ] Consumer protection issues

---

## Research Sources

### Government Databases
- Secretary of State websites (all states)
- EDGAR (SEC filings) - sec.gov
- USPTO (trademarks/patents) - uspto.gov
- PACER (federal courts) - pacer.gov
- State court systems
- BBB (Better Business Bureau)
- Professional licensing boards
- OSHA database
- EPA enforcement database

### Commercial Services
- Dun & Bradstreet
- Bloomberg
- Hoovers
- Crunchbase
- PitchBook
- ZoomInfo

### Free Resources
- LinkedIn Company Pages
- Google Advanced Search
- Archive.org
- News databases
- Industry publications
- Trade association websites

---

## Documentation Template

### Company Profile
```
Legal Name: [Full Legal Name]
DBA: [Doing Business As]
EIN: [XX-XXXXXXX]
Structure: [LLC/Corp/Partnership]
Incorporated: [State, Date]

Headquarters: [Full Address]
Phone: [Number]
Website: [URL]
Email: [Contact]

Key Personnel:
CEO: [Name]
CFO: [Name]
General Counsel: [Name]

Revenue: [Amount/Range]
Employees: [Count]
Industry: [NAICS Code - Description]
```

---

## Investigation Timeline Template

| Date | Event | Source | Significance |
|------|-------|--------|--------------|
| YYYY-MM-DD | Company incorporated | Sec of State | Beginning of entity |
| YYYY-MM-DD | First major contract | News article | Growth milestone |
| YYYY-MM-DD | Lawsuit filed | PACER | Legal issues |

---

## Red Flags Checklist

### Financial Red Flags
- [ ] Multiple bankruptcies
- [ ] Unpaid tax liens
- [ ] Recent foreclosures
- [ ] Numerous judgments
- [ ] Sudden revenue drops
- [ ] Mass layoffs

### Legal Red Flags
- [ ] Pattern of litigation
- [ ] Regulatory violations
- [ ] Criminal charges
- [ ] Securities fraud
- [ ] Consumer complaints
- [ ] Labor disputes

### Operational Red Flags
- [ ] Frequent address changes
- [ ] Shell company indicators
- [ ] No online presence
- [ ] Negative reviews
- [ ] BBB complaints
- [ ] Lack of transparency

---

## Reporting Standards

### Executive Summary
- Company identification
- Investigation scope
- Key findings
- Risk assessment
- Recommendations

### Detailed Findings
1. **Corporate Structure**
   - Legal status
   - Ownership
   - Management

2. **Financial Analysis**
   - Revenue/assets
   - Liabilities
   - Financial health

3. **Legal History**
   - Litigation summary
   - Regulatory issues
   - Compliance status

4. **Business Operations**
   - Products/services
   - Market position
   - Competitive landscape

5. **Reputation Analysis**
   - Online presence
   - Customer feedback
   - Media coverage

---

## Verification Methods

### Cross-Reference Requirements
- [ ] Minimum 2 independent sources for key facts
- [ ] Official records prioritized
- [ ] Recent information (within 12 months)
- [ ] Contradictions noted and investigated

### Document Authentication
- [ ] Verify document source
- [ ] Check publication dates
- [ ] Compare to official records
- [ ] Note any discrepancies

---

## Quality Control Checklist

- [ ] All sources documented with URLs/citations
- [ ] Dates verified (no outdated info presented as current)
- [ ] Names/titles confirmed
- [ ] Financial figures sourced
- [ ] Legal cases verified in court records
- [ ] Contact information validated
- [ ] Report proofread for accuracy
- [ ] Timeline cross-checked
- [ ] Evidence archived properly

---

## Legal & Ethical Considerations

### Permissible Research
- ✅ Public records
- ✅ Publicly available information
- ✅ Official filings
- ✅ News articles
- ✅ Social media (public posts)
- ✅ Court documents

### Prohibited Activities
- ❌ Unauthorized access to systems
- ❌ Pretexting/impersonation
- ❌ Hacking
- ❌ Bribery for information
- ❌ Trespassing
- ❌ Wire/mail fraud

### Best Practices
1. Document all sources
2. Respect privacy laws
3. Follow Terms of Service
4. Maintain objectivity
5. Verify information
6. Protect client confidentiality

---

## Tools & Resources Summary

### Essential Tools
- Google Advanced Search
- LinkedIn Sales Navigator
- PACER (court records)
- State Secretary of State websites
- Wayback Machine
- WHOIS lookups

### Document Management
- Organize by investigation phase
- Use consistent naming conventions
- Maintain evidence log
- Regular backups
- Secure storage

---

## Appendix: Investigation Checklist

### Initial Research (Day 1)
- [ ] Secretary of State filing search
- [ ] Google company name + key terms
- [ ] LinkedIn company page review
- [ ] Website analysis
- [ ] News search (last 12 months)

### Deep Dive (Days 2-3)
- [ ] Court record searches
- [ ] Financial database queries
- [ ] Key personnel background checks
- [ ] Competitor analysis
- [ ] Customer review analysis

### Verification & Documentation (Days 4-5)
- [ ] Cross-reference all findings
- [ ] Verify key facts
- [ ] Document sources
- [ ] Create timeline
- [ ] Draft report

---

**Related SOPs**:
- [[SOP - Person Investigation]]
- [[SOP - OSINT Methodology]]
- [[SOP - Digital Evidence Collection]]
- [[SOP - Due Diligence]]
- [[SOP - Asset Searches]]

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | {{date}} | Initial creation | - |

---

*End of SOP*
EOF
}