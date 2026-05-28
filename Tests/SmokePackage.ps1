param(
    [ValidateSet("x64", "x86")]
    [string] $Platform = "x64",
    [string] $ArtifactsDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) "Artifacts"),
    [string] $MSBuildPath = "",
    [string] $SevenZipPath = "",
    [ValidateRange(0, 9)]
    [int] $CompressionLevel = 5,
    [ValidateRange(1, 3600)]
    [int] $ArchiveReadyTimeoutSeconds = 300,
    [switch] $SkipBuild,
    [switch] $SkipArchive,
    [switch] $KeepStaging,
    [switch] $UseMinimalRuntimeFixture
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceChecks = Join-Path $repoRoot "Tests\SourceChecks.ps1"
$releaseScript = Join-Path $repoRoot "Source\Release.ps1"

function Get-BinDirectory {
    param([ValidateSet("x64", "x86")][string] $TargetPlatform)

    if ($TargetPlatform -eq "x86") {
        return Join-Path $repoRoot "Source\bin-x86"
    }

    return Join-Path $repoRoot "Source\bin"
}

function Resolve-PowerShell {
    foreach ($commandName in @("powershell.exe", "pwsh.exe", "pwsh")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }

    throw "PowerShell was not found."
}

$binDirectory = Get-BinDirectory $Platform
$appExe = Join-Path $binDirectory "StaxRip2.exe"
$powershellExe = Resolve-PowerShell

function Initialize-MinimalRuntimeFixture {
    foreach ($path in @(
        (Join-Path $binDirectory "Apps\Conf"),
        (Join-Path $binDirectory "Fonts\Icons")
    )) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Get-PEMachine {
    param([Parameter(Mandatory = $true)][string] $Path)

    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object System.IO.BinaryReader -ArgumentList $stream
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw "$Path is not a PE executable." }
        $stream.Seek(0x3C, [IO.SeekOrigin]::Begin) | Out-Null
        $peOffset = $reader.ReadInt32()
        $stream.Seek($peOffset, [IO.SeekOrigin]::Begin) | Out-Null
        if ($reader.ReadUInt32() -ne 0x4550) { throw "$Path has an invalid PE header." }
        return $reader.ReadUInt16()
    }
    finally {
        if ($reader) { $reader.Dispose() }
        $stream.Dispose()
    }
}

function Assert-ExecutableArchitecture {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [ValidateSet("x64", "x86")][string] $ExpectedPlatform
    )

    $machine = Get-PEMachine $Path
    $expectedMachine = if ($ExpectedPlatform -eq "x64") { 0x8664 } else { 0x014c }

    if ($machine -ne $expectedMachine) {
        throw "$Path has PE machine 0x$($machine.ToString('x4')), expected $ExpectedPlatform."
    }
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Message
    )

    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        if (Test-Path $Path) {
            return
        }
        Start-Sleep -Milliseconds 500
    }

    if (-not (Test-Path $Path)) {
        throw $Message
    }
}

function Assert-PathMissing {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Message
    )

    if (Test-Path $Path) {
        throw $Message
    }
}

function Get-ArchiveListing {
    param(
        [Parameter(Mandatory = $true)][string] $Archive,
        [string] $SevenZipPath = "",
        [ValidateRange(1, 3600)][int] $TimeoutSeconds = 300
    )

    Assert-PathExists $Archive "Archive was not created."
    $sevenZip = Resolve-SevenZip $SevenZipPath

    for ($attempt = 0; $attempt -lt $TimeoutSeconds; $attempt++) {
        $stdout = Join-Path $env:TEMP "staxrip2-smoke-7z-list-out.txt"
        $stderr = Join-Path $env:TEMP "staxrip2-smoke-7z-list-err.txt"
        Remove-Item $stdout, $stderr -ErrorAction SilentlyContinue
        $process = Start-Process -FilePath $sevenZip -ArgumentList "l -ba `"$Archive`"" -RedirectStandardOutput $stdout -RedirectStandardError $stderr -Wait -PassThru
        if ($process.ExitCode -eq 0) { return Get-Content $stdout }
        Start-Sleep -Seconds 1
    }

    throw "7z listing failed after waiting for the archive."
}

function Resolve-SevenZip {
    param([string] $PathOverride = "")

    if ($PathOverride) {
        if (Test-Path $PathOverride) { return $PathOverride }
        throw "7z was not found at '$PathOverride'."
    }

    foreach ($commandName in @("7z.exe", "7za.exe", "7z")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }

    throw "7z was not found in PATH."
}

function Assert-ArchiveContains {
    param(
        [Parameter(Mandatory = $true)][string[]] $Listing,
        [Parameter(Mandatory = $true)][string] $Pattern,
        [Parameter(Mandatory = $true)][string] $Message
    )

    if (-not ($Listing -match $Pattern)) {
        throw $Message
    }
}

function Assert-ArchiveDoesNotContain {
    param(
        [Parameter(Mandatory = $true)][string[]] $Listing,
        [Parameter(Mandatory = $true)][string] $Pattern,
        [Parameter(Mandatory = $true)][string] $Message
    )

    if ($Listing -match $Pattern) {
        throw $Message
    }
}

& $powershellExe -NoProfile -ExecutionPolicy Bypass -File $sourceChecks

if ($UseMinimalRuntimeFixture) {
    Initialize-MinimalRuntimeFixture
}

$releaseArgs = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $releaseScript,
    "-Platform", $Platform,
    "-ArtifactsDirectory", $ArtifactsDirectory,
    "-CompressionLevel", $CompressionLevel,
    "-ArchiveReadyTimeoutSeconds", $ArchiveReadyTimeoutSeconds
)

if ($MSBuildPath) {
    $releaseArgs += @("-MSBuildPath", $MSBuildPath)
}
if ($SevenZipPath) {
    $releaseArgs += @("-SevenZipPath", $SevenZipPath)
}
if ($SkipBuild) {
    $releaseArgs += "-SkipBuild"
}
if ($SkipArchive) {
    $releaseArgs += "-SkipArchive"
}
if ($KeepStaging) {
    $releaseArgs += "-KeepStaging"
}

& $powershellExe @releaseArgs
if ($LastExitCode) {
    throw "Release packaging failed with exit code $LastExitCode."
}

Assert-ExecutableArchitecture $appExe $Platform

$expectedVersion = [Reflection.AssemblyName]::GetAssemblyName($appExe).Version.ToString(3)
$packageName = "StaxRip2-v$expectedVersion-$Platform"
$stagingDirectory = Join-Path $ArtifactsDirectory $packageName
$archivePath = Join-Path $ArtifactsDirectory "$packageName.7z"

if ($SkipArchive) {
    Assert-PathExists $stagingDirectory "Staging directory was not created."
    Assert-PathExists (Join-Path $stagingDirectory "StaxRip2.exe") "StaxRip2.exe is missing from the package."
    Assert-ExecutableArchitecture (Join-Path $stagingDirectory "StaxRip2.exe") $Platform
    Assert-PathExists (Join-Path $stagingDirectory "StaxRip2.exe.config") "StaxRip2.exe.config is missing from the package."
    Assert-PathExists (Join-Path $stagingDirectory "README.md") "README.md is missing from the package."
    Assert-PathExists (Join-Path $stagingDirectory "CHANGELOG.md") "CHANGELOG.md is missing from the package."
    Assert-PathExists (Join-Path $stagingDirectory "License.txt") "License.txt is missing from the package."
    Assert-PathExists (Join-Path $stagingDirectory "Apps\Conf") "Apps\Conf is missing from the package."
    Assert-PathExists (Join-Path $stagingDirectory "Fonts\Icons") "Fonts\Icons is missing from the package."
    Assert-PathMissing (Join-Path $stagingDirectory "Settings") "Settings must not be included in the package."
    Assert-PathMissing (Join-Path $stagingDirectory "ManagedCuda.xml") "ManagedCuda.xml must not be included in the package."
    Assert-PathMissing (Join-Path $stagingDirectory "System.Management.Automation.xml") "System.Management.Automation.xml must not be included in the package."
}
else {
    Assert-PathExists $archivePath "Release archive was not created."
    $listing = Get-ArchiveListing $archivePath $SevenZipPath $ArchiveReadyTimeoutSeconds

    Assert-ArchiveContains $listing "StaxRip2\.exe$" "StaxRip2.exe is missing from the archive."
    Assert-ArchiveContains $listing "StaxRip2\.exe\.config$" "StaxRip2.exe.config is missing from the archive."
    Assert-ArchiveContains $listing "README\.md$" "README.md is missing from the archive."
    Assert-ArchiveContains $listing "CHANGELOG\.md$" "CHANGELOG.md is missing from the archive."
    Assert-ArchiveContains $listing "License\.txt$" "License.txt is missing from the archive."
    Assert-ArchiveContains $listing "Apps[\\/]Conf" "Apps\Conf is missing from the archive."
    Assert-ArchiveContains $listing "Fonts[\\/]Icons" "Fonts\Icons is missing from the archive."
    Assert-ArchiveDoesNotContain $listing "Settings[\\/]" "Settings must not be included in the archive."
    Assert-ArchiveDoesNotContain $listing "\.pdb$" "PDB files must not be included in the archive."
    Assert-ArchiveDoesNotContain $listing "ManagedCuda\.xml$" "ManagedCuda.xml must not be included in the archive."
    Assert-ArchiveDoesNotContain $listing "System\.Management\.Automation\.xml$" "System.Management.Automation.xml must not be included in the archive."
    Assert-ArchiveDoesNotContain $listing "vs-temp-dl" "Temporary VapourSynth download caches must not be included in the archive."
}

Write-Host "Package smoke checks passed for $packageName."
