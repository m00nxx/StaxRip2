param(
    [ValidateSet("App", "Solution")]
    [string] $BuildScope = "App",
    [ValidateSet("x64", "x86")]
    [string] $Platform = "x64",
    [string] $Configuration = "Release",
    [string] $ArtifactsDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) "Artifacts"),
    [string] $MSBuildPath = "",
    [string] $SevenZipPath = "",
    [ValidateRange(0, 9)]
    [int] $CompressionLevel = 5,
    [switch] $SkipBuild,
    [switch] $SkipArchive,
    [switch] $KeepStaging
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$solution = Join-Path $PSScriptRoot "StaxRip.sln"
$project = Join-Path $PSScriptRoot "StaxRip.vbproj" # Source/StaxRip.vbproj
$binDirectory = Join-Path $PSScriptRoot "bin"
$appExe = Join-Path $binDirectory "StaxRip2.exe"

function Resolve-MSBuild {
    param([string] $PathOverride)

    if ($PathOverride) {
        if (Test-Path $PathOverride) { return $PathOverride }
        throw "MSBuild was not found at '$PathOverride'."
    }

    $command = Get-Command "MSBuild.exe" -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $found = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\Current\Bin\MSBuild.exe" | Select-Object -First 1
        if ($found) { return $found }
    }

    $candidates = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }

    throw "MSBuild.exe was not found. Install Visual Studio 2022 or Build Tools 2022."
}

function Resolve-SevenZip {
    param([string] $PathOverride)

    if ($PathOverride) {
        if (Test-Path $PathOverride) { return $PathOverride }
        throw "7z was not found at '$PathOverride'."
    }

    $command = Get-Command "7z.exe" -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $binDirectory "Apps\Support\7zip\7za.exe"),
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }

    throw "7z.exe was not found. Install 7-Zip or pass -SevenZipPath."
}

function Assert-RuntimeAssets {
    if (-not (Test-Path (Join-Path $binDirectory "StaxRip2.exe"))) { throw "StaxRip2.exe is missing from Source/bin." }
    if (-not (Test-Path (Join-Path $binDirectory 'Apps'))) { throw "Source/bin/Apps is missing." }
    if (-not (Test-Path (Join-Path $binDirectory "Apps\Conf"))) { throw "Source/bin/Apps/Conf is missing." }
    if (-not (Test-Path (Join-Path $binDirectory 'Fonts'))) { throw "Source/bin/Fonts is missing." }
    if (-not (Test-Path (Join-Path $binDirectory "Fonts\Icons"))) { throw "Source/bin/Fonts/Icons is missing." }
    if (-not (Test-Path (Join-Path $binDirectory "License.txt"))) { throw "Source/bin/License.txt is missing." }
}

function Wait-FileReady {
    param([Parameter(Mandatory = $true)][string] $Path)

    $lastLength = -1
    $stableCount = 0

    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        if (Test-Path $Path) {
            try {
                $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
                $length = $stream.Length
                $stream.Dispose()

                if ($length -eq $lastLength -and $length -gt 32) {
                    $stableCount += 1
                    if ($stableCount -ge 2) { return }
                }
                else {
                    $stableCount = 0
                    $lastLength = $length
                }
            }
            catch {
                $stableCount = 0
            }
        }

        Start-Sleep -Seconds 1
    }

    throw "Timed out waiting for '$Path' to become ready."
}

if (-not $SkipBuild) {
    $msbuild = Resolve-MSBuild $MSBuildPath
    $buildTarget = If ($BuildScope -eq "Solution") { $solution } Else { $project }
    & $msbuild $buildTarget /t:Build /p:Configuration=$Configuration /p:Platform=$Platform /m /v:minimal
    if ($LastExitCode) { throw "MSBuild failed with exit code $LastExitCode." }
}

Assert-RuntimeAssets

$version = [Reflection.AssemblyName]::GetAssemblyName($appExe).Version.ToString(3)
$packageName = "StaxRip2-v$version-$Platform"
$targetDirectory = Join-Path $ArtifactsDirectory $packageName
$archivePath = Join-Path $ArtifactsDirectory "$packageName.7z"

if (Test-Path $targetDirectory) { Remove-Item $targetDirectory -Recurse -Force }
if (Test-Path $archivePath) { Remove-Item $archivePath -Force }
New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null

$excludeRelativePatterns = @(
    "^Settings($|[\\/])",
    ".*\.log$",
    ".*\.pdb$",
    ".*recovery\.srip$",
    ".*(?<!eac3to)\.ini$",
    ".*help\.txt$",
    ".*\\eac3to\\bugreport\.txt$",
    ".*\\eac3to\\log\d*\.txt$",
    ".*\\log\d+\.txt$",
    ".*\\qaac\\QTfiles.*",
    ".*\\vs-temp-dl($|\\).*",
    "(^|.*[\\/])FrameServer\.(exp|ilk|lib|pdb)$",
    "(^|.*[\\/])ManagedCuda\.(pdb|xml)$",
    "(^|.*[\\/])System\.Management\.Automation\.xml$",
    ".*_pycache_.*"
)

Get-ChildItem -LiteralPath $binDirectory -Recurse -Force | ForEach-Object {
    $relativePath = $_.FullName.Substring($binDirectory.Length).TrimStart("\", "/")
    if (-not $relativePath) { return }

    foreach ($pattern in $excludeRelativePatterns) {
        if ($relativePath -match $pattern) { return }
    }

    $destination = Join-Path $targetDirectory $relativePath

    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }
    else {
        $destinationDirectory = Split-Path $destination -Parent
        if (-not (Test-Path $destinationDirectory)) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
    }
}

Copy-Item (Join-Path $repoRoot "README.md") (Join-Path $targetDirectory "README.md") -Force
Copy-Item (Join-Path $repoRoot "CHANGELOG.md") (Join-Path $targetDirectory "CHANGELOG.md") -Force
Copy-Item (Join-Path $repoRoot "License.txt") (Join-Path $targetDirectory "License.txt") -Force

if (-not $SkipArchive) {
    $sevenZip = Resolve-SevenZip $SevenZipPath
    Push-Location $ArtifactsDirectory
    try {
        $stdout = Join-Path $env:TEMP "staxrip2-release-7z-out.txt"
        $stderr = Join-Path $env:TEMP "staxrip2-release-7z-err.txt"
        Remove-Item $stdout, $stderr -ErrorAction SilentlyContinue
        $arguments = "a -t7z -mx$CompressionLevel -m0=LZMA2 -md64m -mfb64 -mmt=on `"$packageName.7z`" `"$packageName`""
        $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -RedirectStandardOutput $stdout -RedirectStandardError $stderr -Wait -PassThru
        if (Test-Path $stdout) { Get-Content $stdout | Write-Host }
        if (Test-Path $stderr) { Get-Content $stderr | Write-Host }
        if ($process.ExitCode) { throw "7-Zip failed with exit code $($process.ExitCode)." }
        Wait-FileReady (Join-Path $ArtifactsDirectory "$packageName.7z")
    }
    finally {
        Pop-Location
    }

    if (-not $KeepStaging) {
        Remove-Item $targetDirectory -Recurse -Force
    }
}

Write-Host "Release package prepared: $archivePath"
