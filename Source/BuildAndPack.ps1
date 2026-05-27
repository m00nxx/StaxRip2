param(
    [ValidateSet("x64", "x86")]
    [string] $Platform = "x64",
    [string] $Configuration = "Release",
    [string] $ArtifactsDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) "Artifacts"),
    [string] $MSBuildPath = "",
    [string] $SevenZipPath = "",
    [ValidateRange(0, 9)]
    [int] $CompressionLevel = 5
)

$ErrorActionPreference = "Stop"

# Legacy wrapper for Source/Release.ps1. Builds and packages the full StaxRip2.exe runtime payload.
$releaseScript = Join-Path $PSScriptRoot "Release.ps1"

& $releaseScript `
    -BuildScope App `
    -Platform $Platform `
    -Configuration $Configuration `
    -ArtifactsDirectory $ArtifactsDirectory `
    -MSBuildPath $MSBuildPath `
    -SevenZipPath $SevenZipPath `
    -CompressionLevel $CompressionLevel

if ($LastExitCode) { throw "StaxRip2 packaging failed with exit code $LastExitCode." }
