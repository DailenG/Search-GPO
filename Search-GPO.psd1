@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'Search-GPO.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID                 = '18388481-a957-4b71-9c60-318350550426'

    # Author of this module
    Author               = 'Dailen Gunter'

    # Company or vendor of this module
    CompanyName          = 'WideData Corporation, Inc.'

    # Copyright statement for this module
    Copyright            = '(c) 2026 WideData Corporation, Inc.'

    # Description of the functionality provided by this module
    Description          = @'
Enhanced GPO Search Tool with deep-step logging.

This module helps analyze GPO metadata and internal script code with a real-time progress watchdog.
It can search for strings in GPO Names, Metadata (XML), and internal script files.

🏴 Questions or suggestions? Message @dailen on X or open an Issue on GitHub
'@

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Functions to export from this module, for best performance, do not use wildcards
    FunctionsToExport    = @('Search-GPO')

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @('Windows', 'GPO', 'Search', 'Dailen', 'WideData')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/DailenG/PS/tree/main/modules/Search-GPO/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/DailenG/PS/tree/main/modules/Search-GPO'

            # A URL to an icon representing this module.
            IconUri    = 'https://wdc.help/icons/wam.png'
            
            # ReleaseNotes of this module
            # ReleaseNotes = ''
        }
    }
}
