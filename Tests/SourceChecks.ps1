$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

function Read-RepoFile {
    param([Parameter(Mandatory = $true)][string] $RelativePath)
    return Get-Content -LiteralPath (Join-Path $repoRoot $RelativePath) -Raw
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Expected,
        [Parameter(Mandatory = $true)][string] $Message
    )

    if (-not $Text.Contains($Expected)) {
        throw $Message
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Unexpected,
        [Parameter(Mandatory = $true)][string] $Message
    )

    if ($Text.Contains($Unexpected)) {
        throw $Message
    }
}

$fontManager = Read-RepoFile "Source/UI/FontManager.vb"
Assert-Contains $fontManager "If Directory.Exists(fontFolder) Then" "Font folders must be optional at startup."
Assert-NotContains $fontManager "_fontCollections.First().Value.Families.First()" "Font fallback must not assume bundled fonts exist."
Assert-Contains $fontManager "SystemFonts.MessageBoxFont.FontFamily" "Font fallback must use a system font when bundled fonts are unavailable."

$package = Read-RepoFile "Source/General/Package.vb"
Assert-Contains $package "If Not IO.Directory.Exists(confFolder) Then Exit Sub" "Apps/Conf must be optional at startup."

$globalClass = Read-RepoFile "Source/General/GlobalClass.vb"
Assert-Contains $globalClass "Return Not String.IsNullOrWhiteSpace(settingsLocation) AndAlso Directory.Exists(settingsLocation)" "SettingsFolderExists must check the actual directory."

$solution = Read-RepoFile "Source/StaxRip.sln"
Assert-Contains $solution "Release|x64.ActiveCfg = Release|x64" "Release x64 must build the Release configuration."
Assert-Contains $solution "Release|x86.ActiveCfg = Release|x86" "Release x86 must build the Release configuration."

$project = Read-RepoFile "Source/StaxRip.vbproj"
Assert-Contains $project "<AssemblyName>StaxRip2</AssemblyName>" "Assembly output name must identify the fork."
Assert-Contains $project "<ProductName>StaxRip2</ProductName>" "Product name must identify the fork."

$assemblyInfo = Read-RepoFile "Source/My Project/AssemblyInfo.vb"
Assert-Contains $assemblyInfo 'AssemblyTitle("StaxRip2")' "Assembly title must identify the fork."
Assert-Contains $assemblyInfo 'AssemblyProduct("StaxRip2")' "Assembly product must identify the fork."
Assert-Contains $assemblyInfo 'AssemblyVersion("0.1.0")' "Assembly version must follow the StaxRip2 release line."
Assert-Contains $assemblyInfo 'AssemblyFileVersion("0.1.0")' "File version must follow the StaxRip2 release line."

$updateChecker = Read-RepoFile "Source/General/StaxRipUpdate.vb"
Assert-Contains $updateChecker 'api.github.com/repos/m00nxx/StaxRip2/releases?per_page=5' "Update checks must target the StaxRip2 fork releases."
Assert-NotContains $updateChecker 'api.github.com/repos/staxrip/staxrip/releases?per_page=5' "Update checks must not target upstream StaxRip releases."

$mainForm = Read-RepoFile "Source/Forms/MainForm.vb"
Assert-Contains $mainForm 'https://github.com/m00nxx/StaxRip2' "Help menu must point to the StaxRip2 repository."
Assert-Contains $mainForm 'https://github.com/m00nxx/StaxRip2/issues/new/choose' "Issue reporting must point to the StaxRip2 repository."

Write-Host "Source checks passed."
