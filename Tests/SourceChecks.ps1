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

$globalClassSource = Read-RepoFile "Source/General/GlobalClass.vb"
Assert-NotContains $globalClassSource "StaxRip2ExceptionTrace.log" "Temporary exception trace logging must not be committed."

$imageUtils = Read-RepoFile "Source/UI/ImageUtils.vb"
Assert-NotContains $imageUtils 'MsgWarn("Correct font was not found, using default instead!")' "Missing icon fonts must not show a startup warning dialog."

$readme = Read-RepoFile "README.md"
Assert-Contains $readme "[Building from source](BUILDING.md)" "README must link to source build instructions."
Assert-Contains $readme "StaxRip2 uses its own settings registry key" "README must document StaxRip2 settings isolation."

$buildDocs = Read-RepoFile "BUILDING.md"
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.VCTools" "Build docs must list the Build Tools C++ workload."
Assert-Contains $buildDocs "Microsoft.VisualStudio.Workload.NativeDesktop" "Build docs must list the Visual Studio C++ desktop workload."
Assert-Contains $buildDocs "Microsoft.Cpp.Default.props" "Build docs must explain the missing C++ props error."
Assert-Contains $buildDocs "Source/StaxRip.sln" "Build docs must explain full solution builds."
Assert-Contains $buildDocs "Source/StaxRip.vbproj" "Build docs must explain app-only builds."

Write-Host "Source checks passed."
