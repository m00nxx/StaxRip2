param(
    [ValidateSet("x64", "x86")]
    [string] $Platform = "x64",
    [string] $Configuration = "Release",
    [string] $ArtifactsDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) "Artifacts"),
    [string] $MSBuildPath = ""
)

$ErrorActionPreference = "Stop"

# Legacy wrapper for Source/Release.ps1. Builds StaxRip2.exe and leaves a staging directory.
$releaseScript = Join-Path $PSScriptRoot "Release.ps1"

& $releaseScript `
    -BuildScope App `
    -Platform $Platform `
    -Configuration $Configuration `
    -ArtifactsDirectory $ArtifactsDirectory `
    -MSBuildPath $MSBuildPath `
    -SkipArchive `
    -KeepStaging

if ($LastExitCode) { throw "StaxRip2 build failed with exit code $LastExitCode." }
