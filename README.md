# Search-GPO

Refactored PowerShell module for enhanced GPO searching.

## Overview
**Search-GPO** allows you to perform deep scans of your Group Policy Objects (GPOs), searching not just for display names but within:
- XML Metadata (GPO Settings)
- Internal SYSVOL Scripts (Startup, Shutdown, Logon, Logoff)

It features a progress watchdog and verbose logging to track the scan status in real-time.

## Installation

```powershell
Import-Module ./Search-GPO
```

(Publish instructions pending)

## Usage

### Basic Search
```powershell
Search-GPO -SearchTerm "Printer"
```

### Detailed Search
```powershell
Search-GPO "Deploy" -ShowDetails
```

### Parameters
- **SearchTerm** (String): The text to search for across GPO names and content.
- **ShowDetails** (Switch): Formats the output as a list with full match evidence instead of a summary table.

## Requirements
- Active Directory PowerShell Module (`GroupPolicy` module)
- RSAT access to the domain

## License
MIT License - Copyright (c) 2026 WideData Corporation, Inc.
