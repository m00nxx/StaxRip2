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

$readme = Read-RepoFile "README.md"
Assert-Contains $readme "[Building from source](BUILDING.md)" "README must link to source build instructions."
Assert-Contains $readme "StaxRip2 uses its own settings registry key" "README must document StaxRip2 settings isolation."
Assert-Contains $readme "StaxRip2 is a portable application" "README usage docs must identify the fork."
Assert-Contains $readme '`StaxRip2.exe`' "README usage docs must use the fork executable name."

$issueTemplateConfig = Read-RepoFile ".github/ISSUE_TEMPLATE/config.yml"
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/discussions/new/choose" "Issue template discussion links must target the fork."
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/blob/master/Docs/README.md" "Issue template documentation links must target the fork."
Assert-NotContains $issueTemplateConfig "https://github.com/staxrip/staxrip" "Issue template config must not point users back to upstream StaxRip."

$buildDocs = Read-RepoFile "BUILDING.md"
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.VCTools" "Build docs must list the Build Tools C++ workload."
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.NativeDesktop" "Build docs must list the Visual Studio C++ desktop workload."
Assert-Contains $buildDocs "Microsoft.Cpp.Default.props" "Build docs must explain the missing C++ props error."
Assert-Contains $buildDocs "Source/StaxRip.sln" "Build docs must explain full solution builds."
Assert-Contains $buildDocs "Source/StaxRip.vbproj" "Build docs must explain app-only builds."
Assert-Contains $buildDocs "GitHub Actions" "Build docs must describe the GitHub Actions build."
Assert-Contains $buildDocs "StaxRip2-Release-x64" "Build docs must document the CI artifact name."
Assert-Contains $buildDocs "app-only artifact" "Build docs must clarify the CI artifact scope."

$workflow = Read-RepoFile ".github/workflows/build.yml"
Assert-Contains $workflow "windows-latest" "GitHub Actions build must run on Windows."
Assert-Contains $workflow "vswhere.exe" "GitHub Actions build must locate MSBuild with vswhere."
Assert-Contains $workflow "NuGet/setup-nuget" "GitHub Actions build must provision NuGet explicitly."
Assert-Contains $workflow "Tests\SourceChecks.ps1" "GitHub Actions build must run source checks."
Assert-Contains $workflow "Source\StaxRip.vbproj" "GitHub Actions build must build the app project."
Assert-Contains $workflow "StaxRip2-Release-x64" "GitHub Actions build must publish the expected artifact."
Assert-Contains $workflow "actions/upload-artifact" "GitHub Actions build must upload a build artifact."

foreach ($buildScriptPath in @("Source/Build.ps1", "Source/BuildAndPack.ps1", "Source/Release.ps1")) {
    $buildScript = Read-RepoFile $buildScriptPath
    Assert-Contains $buildScript "StaxRip2.exe" "$buildScriptPath must package the StaxRip2 executable."
    Assert-Contains $buildScript "StaxRip2" "$buildScriptPath must use fork-specific package names."
    Assert-NotContains $buildScript "StaxRip.exe" "$buildScriptPath must not package the upstream executable."
    Assert-NotContains $buildScript "A:\StaxRip-Releases" "$buildScriptPath must not require the maintainer-specific release drive."
}

Write-Host "Source checks passed."
