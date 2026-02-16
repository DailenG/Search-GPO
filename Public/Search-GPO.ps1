function Search-GPO {
    <#
    .SYNOPSIS
        Enhanced GPO Search Tool with deep-step logging.
    
    .DESCRIPTION
        Analyzes GPO metadata and internal script code with real-time progress watchdog.
        Can search for strings in GPO Names, Metadata (XML), and internal script files (Startup/Shutdown/Logon/Logoff).
    
    .PARAMETER SearchTerm
        The string to search for within GPOs.

    .PARAMETER ShowDetails
        If specified, outputs a formatted list of results instead of a table.

    .EXAMPLE
        Search-GPO -SearchTerm "Printer"
        Searches all GPOs for the string "Printer".

    .EXAMPLE
        Search-GPO "Deploy" -ShowDetails
        Searches for "Deploy" and shows full match details.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$SearchTerm,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )

    process {
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            Write-Error "The 'GroupPolicy' module is required but not found. Please install RSAT (Remote Server Administration Tools) for Group Policy Management."
            return
        }

        if (-not $SearchTerm) {
            try {
                $SearchTerm = Read-Host "Enter the server name or string to search for"
            }
            catch {
                Write-Error "Could not read input. Run with: Search-GPO -SearchTerm 'Name'"
                return
            }
        }

        if ([string]::IsNullOrWhiteSpace($SearchTerm)) { return }

        # Escape regex special characters in search term
        $EscapedSearchTerm = [regex]::Escape($SearchTerm)

        $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        $DomainDNS = $env:USERDNSDOMAIN
        $SysvolBase = "\\$DomainDNS\SYSVOL\$DomainDNS\Policies"

        Write-Host "`nInitializing Enhanced Scan for: $SearchTerm" -ForegroundColor Cyan
        Write-Verbose "Targeting Domain: $DomainDNS"
        Write-Verbose "SYSVOL Root: $SysvolBase"

        $AllGpos = Get-GPO -All
        $TotalCount = $AllGpos.Count
        $Results = New-Object System.Collections.Generic.List[PSObject]

        foreach ($Gpo in $AllGpos) {
            $Index = [array]::IndexOf($AllGpos, $Gpo) + 1
            $Percent = [math]::Round(($Index / $TotalCount) * 100, 0)
            $Timestamp = Get-Date -Format "HH:mm:ss"
            
            # Progress Bar Watchdog
            Write-Progress -Activity "Scanning GPOs (Elapsed: $($Timer.Elapsed.ToString('mm\:ss')))" `
                -Status "[$Timestamp] Analyzing [$Index/$TotalCount]: $($Gpo.DisplayName)" `
                -PercentComplete $Percent
            
            # Detailed Verbose Logging for each step
            Write-Verbose "[$Timestamp] START: $($Gpo.DisplayName) [ID: $($Gpo.Id)]"
            
            $MatchSource = @()
            $MatchEvidence = @()
            $GpoGuid = "{$($Gpo.Id.Guid.ToString().ToUpper())}"
            
            try {
                # STEP 1: XML Metadata Analysis
                Write-Verbose "  -> Step 1/2: Analyzing XML Metadata Settings..."
                [xml]$GpoXml = Get-GPOReport -Guid $Gpo.Id -ReportType Xml -ErrorAction Stop
                
                if ($GpoXml.OuterXml -like "*$SearchTerm*") { 
                    Write-Verbose "    [!] Match found in Metadata XML."
                    $MatchSource += "GPO Settings"
                    if ($GpoXml.OuterXml -match "([^>]{0,50}$EscapedSearchTerm[^<]{0,50})") {
                        $MatchEvidence += "XML Snippet: ...$($Matches[1])..."
                    }
                }
                
                # Link Analysis
                $ActiveLinks = @($GpoXml.GPO.LinksTo) | Where-Object { $_.Enabled -eq "true" }
                $LinkPaths = if ($ActiveLinks) { ($ActiveLinks.SOMPath -join "; ") } else { "--- NONE ---" }
                Write-Verbose "  -> Verified Link Status: $(if ($ActiveLinks) { 'Linked' } else { 'Unlinked' })"
            }
            catch {
                Write-Verbose "  -> ERROR: Metadata analysis failed for this policy."
                $LinkPaths = "--- ERROR ---"
            }

            # STEP 2: Internal Script Code Analysis
            Write-Verbose "  -> Step 2/2: Scraping Internal SYSVOL Script Code..."
            $ScriptFolders = @(
                "$SysvolBase\$GpoGuid\Machine\Scripts\Startup",
                "$SysvolBase\$GpoGuid\Machine\Scripts\Shutdown",
                "$SysvolBase\$GpoGuid\User\Scripts\Logon",
                "$SysvolBase\$GpoGuid\User\Scripts\Logoff"
            )
            
            foreach ($Folder in $ScriptFolders) {
                if (Test-Path $Folder) {
                    Write-Verbose "    Checking Directory: $($Folder.Split('\\')[-3..-1] -join '\\')"
                    $FileMatches = Get-ChildItem $Folder -File -Recurse | Select-String -Pattern $EscapedSearchTerm
                    if ($FileMatches) {
                        Write-Verbose "    [!] Match found in Script Content."
                        $MatchSource += "Script Code"
                        foreach ($fm in $FileMatches) {
                            $MatchEvidence += "File ($($fm.Filename)) line $($fm.LineNumber): $($fm.Line.Trim())"
                        }
                    }
                }
            }

            if ($MatchSource.Count -gt 0) {
                $Results.Add([PSCustomObject]@{
                        GPOName      = $Gpo.DisplayName
                        IsLinked     = if ($LinkPaths -ne "--- NONE ---" -and $LinkPaths -ne "--- ERROR ---") { $true } else { $false }
                        Source       = $MatchSource -join ", "
                        MatchDetails = $MatchEvidence -join " | "
                        LastModified = $Gpo.ModificationTime
                        LinkPaths    = $LinkPaths
                    })
            }
            Write-Verbose "[$Timestamp] FINISH: $($Gpo.DisplayName)`n"
        }

        $Timer.Stop()

        if ($Results.Count -gt 0) {
            Write-Host "`n[SCAN COMPLETE] - Found $($Results.Count) matches in $($Timer.Elapsed.ToString('mm\:ss'))`n" -ForegroundColor Green
            
            if ($ShowDetails) {
                $Results | Format-List GPOName, IsLinked, Source, MatchDetails, LastModified, LinkPaths
            }
            else {
                $Results | Select-Object GPOName, IsLinked, Source, LastModified, LinkPaths | Format-Table -AutoSize
            }
        }
        else {
            Write-Host "`nNo matches found for '$SearchTerm' across $TotalCount GPOs." -ForegroundColor Yellow
        }
    }
}
