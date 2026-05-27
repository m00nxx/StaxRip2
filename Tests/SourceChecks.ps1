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
Assert-Contains $globalClass 'Software\StaxRip2\SettingsLocation' "SettingsFolderExists must use the StaxRip2 registry key."
Assert-Contains $globalClass 'Settings.LegacyStaxRip.' "Legacy StaxRip settings must be quarantined instead of loaded by the fork."
Assert-Contains $globalClass '"staxrip2 settings file"' "Settings mutex must be isolated for StaxRip2."
Assert-Contains $globalClass '"staxrip2 audio profiles file"' "Audio profile mutex must be isolated for StaxRip2."
Assert-Contains $globalClass '"staxrip2 video encoder profiles file"' "Video encoder profile mutex must be isolated for StaxRip2."
Assert-Contains $globalClass '"staxrip2 events file"' "Event command mutex must be isolated for StaxRip2."
Assert-Contains $globalClass 'Process.GetProcessesByName("StaxRip2")' "Process checks must use the StaxRip2 executable name."
Assert-NotContains $globalClass '"staxrip settings file"' "Settings mutex must not be shared with upstream StaxRip."
Assert-NotContains $globalClass '"staxrip audio profiles file"' "Audio profile mutex must not be shared with upstream StaxRip."
Assert-NotContains $globalClass '"staxrip video encoder profiles file"' "Video encoder profile mutex must not be shared with upstream StaxRip."
Assert-NotContains $globalClass '"staxrip events file"' "Event command mutex must not be shared with upstream StaxRip."
Assert-NotContains $globalClass 'Process.GetProcessesByName("StaxRip")' "Process checks must not use the upstream executable name."

$applicationSettings = Read-RepoFile "Source/General/ApplicationSettings.vb"
Assert-Contains $applicationSettings "Fonts = If(Fonts, New Dictionary(Of FontCategory, String))" "Fresh settings initialization must tolerate missing font settings."
Assert-Contains $applicationSettings "If AudioProfiles Is Nothing Then Return" "Settings migration must tolerate missing audio profiles."
Assert-Contains $applicationSettings "ap?.Migrate()" "Settings migration must skip null audio profile entries."
Assert-Contains $applicationSettings "EnsureFilterProfilesContainDefaults(AviSynthProfiles, FilterCategory.GetAviSynthDefaults)" "Corrupt AviSynth filter profile settings must be repaired from defaults."
Assert-Contains $applicationSettings "EnsureFilterProfilesContainDefaults(VapourSynthProfiles, FilterCategory.GetVapourSynthDefaults)" "Corrupt VapourSynth filter profile settings must be repaired from defaults."
Assert-Contains $applicationSettings "If profiles Is Nothing OrElse profiles.Count = 0 Then" "Empty filter profile settings must be rebuilt."

$general = Read-RepoFile "Source/General/General.vb"
Assert-Contains $general 'Software\StaxRip2\SettingsLocation' "Settings directory selection must use the StaxRip2 registry key."
Assert-NotContains $general 'Software\StaxRip\SettingsLocation' "Settings directory selection must not reuse the original StaxRip registry key."
Assert-Contains $general 'Path.Combine(AppDataRoaming, "StaxRip2")' "Roaming settings fallback must use a StaxRip2 directory."
Assert-Contains $general 'Path.Combine(AppDataCommon, "StaxRip2")' "Common settings fallback must use a StaxRip2 directory."
Assert-NotContains $general 'Path.Combine(AppDataRoaming, "StaxRip")' "Roaming settings fallback must not reuse the upstream StaxRip directory."
Assert-NotContains $general 'Path.Combine(AppDataCommon, "StaxRip")' "Common settings fallback must not reuse the upstream StaxRip directory."
Assert-Contains $general "Dim version = 45" "Template update version must advance when default templates change."
Assert-Contains $general 'auto.Script.Filters(0) = If(VideoFilter.GetDefault("Source", "Automatic", ScriptEngine.VapourSynth), auto.Script.Filters(0))' "Automatic workflow templates must not serialize a null source filter."
Assert-Contains $general 'manual.Script.Filters(0) = If(VideoFilter.GetDefault("Source", "Manual"), manual.Script.Filters(0))' "Manual workflow templates must not serialize a null source filter."
Assert-Contains $general "Dim settingsFileExists = File.Exists(path)" "Fresh settings initialization must track whether a settings file existed."
Assert-Contains $general "If settingsFileExists AndAlso safeInstance.WasUpdated AndAlso TypeOf DirectCast(instance, Object) Is ApplicationSettings Then" "Project/template deserialization must not immediately reserialize migrated projects."
Assert-NotContains $general "DeserializeTrace.log" "Temporary deserialization trace logging must not be committed."

$filtersListView = Read-RepoFile "Source/Controls/FiltersListView.vb"
Assert-NotContains $filtersListView "FiltersLoadTrace.log" "Temporary filter loading trace logging must not be committed."

$extensions = Read-RepoFile "Source/General/Extensions.vb"
Assert-Contains $extensions "Return value.Split({Microsoft.VisualBasic.ControlChars.CrLf, Microsoft.VisualBasic.ControlChars.Lf, Microsoft.VisualBasic.ControlChars.Cr}, StringSplitOptions.RemoveEmptyEntries)" "Line splitting must handle LF-only embedded text resources."

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
Assert-Contains $updateChecker "Would you like StaxRip2 to check for updates periodically?" "Update prompts must identify the fork."

$mainForm = Read-RepoFile "Source/Forms/MainForm.vb"
Assert-Contains $mainForm 'https://github.com/m00nxx/StaxRip2' "Help menu must point to the StaxRip2 repository."
Assert-Contains $mainForm 'https://github.com/m00nxx/StaxRip2/issues/new/choose' "Issue reporting must point to the StaxRip2 repository."
Assert-Contains $mainForm '[Reflection.Assembly]::LoadWithPartialName(""StaxRip2"")' "PowerShell integration must load the fork assembly name."
Assert-Contains $mainForm 'Startup template failed to load' "Startup template load failures must not recurse indefinitely."
Assert-Contains $mainForm 'Startup template failed to initialize' "Startup template initialization failures must not recurse indefinitely."
Assert-Contains $mainForm 'Return OpenProject(startupTemplatePath, False)' "Startup template fallback must bypass save-current recursion."
Assert-NotContains $mainForm 'Function(cat) cat.Name = "Source").First.Filters' "Source filter lookup must tolerate missing Source profile categories."
Assert-Contains $mainForm 'Dim sourceCategory = profiles?.FirstOrDefault(Function(cat) cat.Name = "Source")' "Source filter lookup must use a nullable category lookup."
Assert-Contains $mainForm 'sourceCategory = FilterCategory.GetVapourSynthDefaults().FirstOrDefault(Function(cat) cat.Name = "Source")' "Source filter lookup must fall back to built-in VapourSynth defaults."
Assert-NotContains $mainForm "ModifyFiltersTrace.log" "Temporary source filter trace logging must not be committed."
Assert-Contains $mainForm "NormalizeCommandLineArguments(ParseCommandLine(commandLine)).ToArray()" "Command-line parsing must normalize unquoted template names with spaces."
Assert-Contains $mainForm 'arg.StartsWith("-" & NameOf(LoadTemplate) & ":", StringComparison.OrdinalIgnoreCase)' "LoadTemplate command-line arguments must tolerate unquoted spaces."
Assert-NotContains $mainForm '"staxrip.log"' "Main form runtime cleanup must not use upstream log filenames."

$mainFormShowSettings = Read-RepoFile "Source/Forms/MainForm_ShowSettings.vb"
Assert-Contains $mainFormShowSettings "Dim sourceFilters = If(sourceCategory?.Filters, New List(Of VideoFilter))" "Filter preference settings must tolerate a missing Source category."
Assert-NotContains $mainFormShowSettings ".First.Filters" "Filter preference settings must not assume Source filter categories exist."

$globalClassSource = Read-RepoFile "Source/General/GlobalClass.vb"
Assert-NotContains $globalClassSource "StaxRip2ExceptionTrace.log" "Temporary exception trace logging must not be committed."

$processingForm = Read-RepoFile "Source/Forms/ProcessingForm.vb"
Assert-Contains $processingForm 'NotifyIcon.Text = "StaxRip2"' "Tray icon text must identify the fork."
Assert-Contains $processingForm "this StaxRip2 instance" "Processing tooltips must identify the fork."

$updateForm = Read-RepoFile "Source/Forms/UpdateForm.vb"
Assert-NotContains $updateForm "Revan654/staxrip" "Legacy update form must not download from old upstream release mirrors."
Assert-NotContains $updateForm "StaxRip.rar" "Legacy update form must not create upstream-named update archives."

$logBuilder = Read-RepoFile "Source/General/LogBuilder.vb"
Assert-Contains $logBuilder '"StaxRip2:"' "Diagnostic logs must identify the fork."
Assert-Contains $logBuilder '"staxrip2.log"' "Diagnostic logs must use fork-specific filenames."
Assert-NotContains $logBuilder '"StaxRip:"' "Diagnostic logs must not identify as upstream StaxRip."
Assert-NotContains $logBuilder '"staxrip.log"' "Diagnostic logs must not use upstream log filenames."

$imageUtils = Read-RepoFile "Source/UI/ImageUtils.vb"
Assert-NotContains $imageUtils 'MsgWarn("Correct font was not found, using default instead!")' "Missing icon fonts must not show a startup warning dialog."

$toolUpdate = Read-RepoFile "Source/General/ToolUpdate.vb"
Assert-Contains $toolUpdate "Application.ProductName" "Tool update dialogs must identify the current product."
Assert-NotContains $toolUpdate '"StaxRip", MessageBoxButtons.OKCancel' "Tool update dialogs must not hardcode upstream branding."

$documentation = Read-RepoFile "Source/General/Documentation.vb"
Assert-Contains $documentation "https://github.com/m00nxx/StaxRip2/issues/new?template=request-a-feature.md" "Generated documentation must link feature requests to the fork."
Assert-Contains $documentation "This page is based on the StaxRip2 version" "Generated documentation must identify the fork."
Assert-NotContains $documentation "https://github.com/staxrip/staxrip" "Generated runtime documentation must not link back to upstream issue pages."

$packageSource = Read-RepoFile "Source/General/Package.vb"
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/ffmpeg" "Package help links must target the fork wiki for ffmpeg."
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/qaac" "Package help links must target the fork wiki for qaac."
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/aomenc" "Package help links must target the fork wiki for aomenc."
Assert-NotContains $packageSource "https://github.com/staxrip/staxrip/wiki" "Package help links must not point to upstream StaxRip wiki pages."

$qsvEncSource = Read-RepoFile "Source/Encoding/QSVEnc.vb"
Assert-Contains $qsvEncSource "https://github.com/m00nxx/StaxRip2/wiki/qsvenc-bitrate-modes" "QSVEnc help links must target the fork wiki."
Assert-NotContains $qsvEncSource "https://github.com/staxrip/staxrip/wiki" "QSVEnc help links must not point to upstream StaxRip wiki pages."

$previewForm = Read-RepoFile "Source/Forms/PreviewForm.vb"
Assert-Contains $previewForm "ImageCodecInfo.GetImageEncoders.FirstOrDefault" "Preview image saving must tolerate a missing JPEG encoder."
Assert-Contains $previewForm "If info Is Nothing Then" "Preview image saving must check JPEG encoder lookup results."
Assert-NotContains $previewForm "ImageCodecInfo.GetImageEncoders.Where(Function(arg) arg.FormatID = ImageFormat.Jpeg.Guid).First" "Preview image saving must not assume a JPEG encoder exists."

$readme = Read-RepoFile "README.md"
Assert-Contains $readme "[Building from source](BUILDING.md)" "README must link to source build instructions."
Assert-Contains $readme "StaxRip2 uses its own settings registry key" "README must document StaxRip2 settings isolation."
Assert-Contains $readme "StaxRip2 is a portable application" "README usage docs must identify the fork."
Assert-Contains $readme '`StaxRip2.exe`' "README usage docs must use the fork executable name."

$changelog = Read-RepoFile "CHANGELOG.md"
Assert-Contains $changelog "Fixed command-line template loading" "Changelog must mention the command-line template loading fix."
Assert-Contains $changelog "AppData fallbacks, mutex names, process checks" "Changelog must mention fork isolation cleanup."
Assert-Contains $changelog "StaxRip2-Release-x64" "Changelog must mention the GitHub Actions artifact."
Assert-Contains $changelog "Hardened source filter preference settings and preview JPEG saving" "Changelog must mention the targeted lookup hardening."

$issueTemplateConfig = Read-RepoFile ".github/ISSUE_TEMPLATE/config.yml"
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/discussions/new/choose" "Issue template discussion links must target the fork."
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/blob/master/Docs/README.md" "Issue template documentation links must target the fork."
Assert-NotContains $issueTemplateConfig "https://github.com/staxrip/staxrip" "Issue template config must not point users back to upstream StaxRip."

$bugTemplate = Read-RepoFile ".github/ISSUE_TEMPLATE/01-bug_report.yml"
Assert-Contains $bugTemplate "_staxrip2.log" "Bug report template must reference StaxRip2 log filenames."
Assert-NotContains $bugTemplate "_staxrip.log" "Bug report template must not reference upstream log filenames."

$installationDocs = Read-RepoFile "Docs/Introduction/Installation.md"
Assert-Contains $installationDocs "StaxRip2 is a portable application" "Installation docs must identify the fork."
Assert-Contains $installationDocs '`StaxRip2.exe`' "Installation docs must use the fork executable name."
Assert-NotContains $installationDocs '`StaxRip.exe`' "Installation docs must not tell users to launch upstream executable names."

$macroDocs = Read-RepoFile "Docs/Usage/Macros.md"
Assert-Contains $macroDocs "https://github.com/m00nxx/StaxRip2/issues/new?template=request-a-feature.md" "Macro docs must link feature requests to the fork."
Assert-NotContains $macroDocs "https://github.com/staxrip/staxrip" "Macro docs must not link feature requests to upstream StaxRip."

$uiMisc = Read-RepoFile "Source/UI/Misc.vb"
Assert-Contains $uiMisc 'Return "StaxRip2"' "Window position keys must identify the fork main window."

$applicationSettingsSource = Read-RepoFile "Source/General/ApplicationSettings.vb"
Assert-Contains $applicationSettingsSource '"StaxRip2", "Crop", "Jobs"' "Default remembered window positions must identify the fork main window."

$frameServerResource = Read-RepoFile "Source/FrameServer/FrameServer.rc"
Assert-Contains $frameServerResource 'VALUE "ProductName", "StaxRip2"' "FrameServer metadata must identify the fork."

$buildDocs = Read-RepoFile "BUILDING.md"
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.VCTools" "Build docs must list the Build Tools C++ workload."
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.NativeDesktop" "Build docs must list the Visual Studio C++ desktop workload."
Assert-Contains $buildDocs "Microsoft.Cpp.Default.props" "Build docs must explain the missing C++ props error."
Assert-Contains $buildDocs "Source/StaxRip.sln" "Build docs must explain full solution builds."
Assert-Contains $buildDocs "Source/StaxRip.vbproj" "Build docs must explain app-only builds."
Assert-Contains $buildDocs "GitHub Actions" "Build docs must describe the GitHub Actions build."
Assert-Contains $buildDocs "StaxRip2-Release-x64" "Build docs must document the CI artifact name."
Assert-Contains $buildDocs "app-only artifact" "Build docs must clarify the CI artifact scope."
Assert-Contains $buildDocs "Source/Release.ps1" "Build docs must document full release packaging."
Assert-Contains $buildDocs "StaxRip2-v0.1.1-x64.7z" "Build docs must document the v0.1.1 release archive name."
Assert-Contains $buildDocs "Source/bin/Apps" "Build docs must document required packaged runtime apps."
Assert-Contains $buildDocs "Source/bin/Fonts" "Build docs must document required packaged fonts."
Assert-Contains $buildDocs "-CompressionLevel 0..9" "Build docs must document release compression tuning."

$workflow = Read-RepoFile ".github/workflows/build.yml"
Assert-Contains $workflow "windows-latest" "GitHub Actions build must run on Windows."
Assert-Contains $workflow "actions/checkout@v6.0.2" "GitHub Actions build must use a Node 24 compatible checkout action."
Assert-Contains $workflow "vswhere.exe" "GitHub Actions build must locate MSBuild with vswhere."
Assert-Contains $workflow "NuGet/setup-nuget@v4.0" "GitHub Actions build must provision NuGet with a Node 24 compatible action."
Assert-Contains $workflow "Tests\SourceChecks.ps1" "GitHub Actions build must run source checks."
Assert-Contains $workflow "Source\StaxRip.vbproj" "GitHub Actions build must build the app project."
Assert-Contains $workflow "StaxRip2-Release-x64" "GitHub Actions build must publish the expected artifact."
Assert-Contains $workflow "actions/upload-artifact@v7.0.1" "GitHub Actions build must upload artifacts with a Node 24 compatible action."

foreach ($buildScriptPath in @("Source/Build.ps1", "Source/BuildAndPack.ps1", "Source/Release.ps1")) {
    $buildScript = Read-RepoFile $buildScriptPath
    Assert-Contains $buildScript "StaxRip2.exe" "$buildScriptPath must package the StaxRip2 executable."
    Assert-Contains $buildScript "StaxRip2" "$buildScriptPath must use fork-specific package names."
    Assert-NotContains $buildScript "StaxRip.exe" "$buildScriptPath must not package the upstream executable."
    Assert-NotContains $buildScript "A:\StaxRip-Releases" "$buildScriptPath must not require the maintainer-specific release drive."
}

$releaseScript = Read-RepoFile "Source/Release.ps1"
Assert-Contains $releaseScript "param(" "Release packaging must be configurable from the command line."
Assert-Contains $releaseScript "Source/StaxRip.vbproj" "Release packaging must support app-only builds for source checkouts."
Assert-Contains $releaseScript 'StaxRip2-v$version-$Platform' "Release archive naming must match update-check expectations."
Assert-Contains $releaseScript "README.md" "Release packages must include README.md."
Assert-Contains $releaseScript "CHANGELOG.md" "Release packages must include CHANGELOG.md."
Assert-Contains $releaseScript '"^Settings($|[\\/])"' "Release packages must exclude user settings."
Assert-Contains $releaseScript "Test-Path (Join-Path `$binDirectory 'Apps')" "Release packaging must validate bundled runtime apps."
Assert-Contains $releaseScript "Test-Path (Join-Path `$binDirectory 'Fonts')" "Release packaging must validate bundled fonts."
Assert-Contains $releaseScript "vs-temp-dl" "Release packages must exclude temporary VapourSynth download caches."
Assert-Contains $releaseScript '(^|.*[\\/])ManagedCuda\.(pdb|xml)$' "Release packages must exclude top-level ManagedCuda debug metadata."
Assert-Contains $releaseScript '(^|.*[\\/])System\.Management\.Automation\.xml$' "Release packages must exclude top-level PowerShell XML metadata."
Assert-Contains $releaseScript "function Wait-FileReady" "Release packaging must wait until the 7z archive is fully written."
Assert-Contains $releaseScript "Start-Process -FilePath `$sevenZip" "Release packaging must run 7-Zip with explicit process exit handling."
Assert-Contains $releaseScript "CompressionLevel = 5" "Release packaging must use a practical default compression level."
Assert-Contains $releaseScript "-mx`$CompressionLevel" "Release packaging compression must be configurable."
Assert-Contains $releaseScript "7z" "Release packaging must create a 7z archive."

$smokePackage = Read-RepoFile "Tests/SmokePackage.ps1"
Assert-Contains $smokePackage "Tests\SourceChecks.ps1" "Package smoke test must run source checks first."
Assert-Contains $smokePackage "Source\Release.ps1" "Package smoke test must exercise release packaging."
Assert-Contains $smokePackage 'Join-Path $ArtifactsDirectory "$packageName.7z"' "Package smoke test must validate updater-compatible archive naming."
Assert-Contains $smokePackage 'Join-Path $PSHOME "powershell.exe"' "Package smoke test must invoke Windows PowerShell reliably."
Assert-Contains $smokePackage 'SevenZipPath' "Package smoke test must support explicit 7-Zip paths."
Assert-Contains $smokePackage 'CompressionLevel' "Package smoke test must pass through release compression settings."
Assert-Contains $smokePackage "Start-Process -FilePath `$SevenZipPath" "Package smoke test must list archives with explicit process exit handling."
Assert-Contains $smokePackage "7z listing failed after waiting for the archive" "Package smoke test must retry archive listing while the file is settling."
Assert-Contains $smokePackage "StaxRip2.exe" "Package smoke test must validate executable presence."
Assert-Contains $smokePackage "Apps\Conf" "Package smoke test must validate packaged app configuration."
Assert-Contains $smokePackage "Fonts\Icons" "Package smoke test must validate packaged fonts."
Assert-Contains $smokePackage "Assert-ArchiveDoesNotContain" "Package smoke test must validate release exclusions."
Assert-Contains $smokePackage "ManagedCuda.xml" "Package smoke test must reject debug XML files."
Assert-Contains $smokePackage "vs-temp-dl" "Package smoke test must reject temporary download caches."
Assert-Contains $smokePackage "Start-Sleep -Milliseconds 500" "Package smoke test must tolerate filesystem visibility delay after packaging."

Write-Host "Source checks passed."
