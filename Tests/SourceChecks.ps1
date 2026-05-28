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
Assert-Contains $globalClass "Private Sub SerializeWithMutex" "Profile and event saves must release mutexes in finally blocks."
Assert-Contains $globalClass "If mutexAcquired Then mutex.ReleaseMutex()" "Mutex-protected settings/profile writes must always release acquired mutexes."
Assert-NotContains $globalClass "formatter As New BinaryFormatter" "Profile and event serialization must use the guarded formatter factory."

$applicationSettings = Read-RepoFile "Source/General/ApplicationSettings.vb"
Assert-Contains $applicationSettings "Fonts = If(Fonts, New Dictionary(Of FontCategory, String))" "Fresh settings initialization must tolerate missing font settings."
Assert-Contains $applicationSettings "If AudioProfiles Is Nothing Then Return" "Settings migration must tolerate missing audio profiles."
Assert-Contains $applicationSettings "ap?.Migrate()" "Settings migration must skip null audio profile entries."
Assert-Contains $applicationSettings "EnsureFilterProfilesContainDefaults(AviSynthProfiles, FilterCategory.GetAviSynthDefaults)" "Corrupt AviSynth filter profile settings must be repaired from defaults."
Assert-Contains $applicationSettings "EnsureFilterProfilesContainDefaults(VapourSynthProfiles, FilterCategory.GetVapourSynthDefaults)" "Corrupt VapourSynth filter profile settings must be repaired from defaults."
Assert-Contains $applicationSettings "If profiles Is Nothing OrElse profiles.Count = 0 Then" "Empty filter profile settings must be rebuilt."
Assert-Contains $applicationSettings "Dim profileFilters = profileCategory.Filters" "Settings migration must normalize filter lists through the safe property getter."
Assert-Contains $applicationSettings "Dim existingScripts = New HashSet(Of String)(profileFilters.Select(Function(filter) filter.Script))" "Filter profile repair must detect missing default filters inside existing categories."
Assert-Contains $applicationSettings "For Each defaultFilter In defaultCategory.Filters" "Filter profile repair must add missing default filters inside existing categories."
Assert-NotContains $applicationSettings "profileCategory.Filters.Any()" "Settings migration must not call Any on possibly null filter lists."

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
Assert-Contains $general "Shared Function CreateFormatter() As BinaryFormatter" "BinaryFormatter use must be centralized behind a guarded factory."
Assert-Contains $general "Shared Function CreateCloneFormatter() As BinaryFormatter" "Internal object cloning must use a separate formatter from untrusted file deserialization."
Assert-Contains $general "SafeSerializationBinder" "BinaryFormatter deserialization must use an allow-list binder."
Assert-Contains $general "AllowedTypeNames" "BinaryFormatter binder must restrict allowed serialized type names."
Assert-Contains $general "AllowedTypeNamePrefixes" "BinaryFormatter binder must restrict allowed serialized type namespaces."
Assert-Contains $general "Private Shared Function IsAllowedTypeName" "BinaryFormatter binder must validate type names before resolving them."
Assert-Contains $general 'simpleAssemblyName.Equals("StaxRip2", StringComparison.OrdinalIgnoreCase)' "BinaryFormatter binder must remap older StaxRip2 assembly versions to the current executable assembly."
Assert-NotContains $general 'AllowedAssemblyNames.Contains(simpleAssemblyName)) Then' "BinaryFormatter binder must not rely only on assembly-name allow-listing."
Assert-NotContains $general "Dim bf As New BinaryFormatter" "Safe serialization must not instantiate unguarded BinaryFormatter instances."
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
Assert-Contains $project '<PlatformTarget>x86</PlatformTarget>' "x86 builds must produce a true 32-bit executable instead of AnyCPU Prefer32Bit output."

$assemblyInfo = Read-RepoFile "Source/My Project/AssemblyInfo.vb"
Assert-Contains $assemblyInfo 'AssemblyTitle("StaxRip2")' "Assembly title must identify the fork."
Assert-Contains $assemblyInfo 'AssemblyProduct("StaxRip2")' "Assembly product must identify the fork."
Assert-Contains $assemblyInfo 'AssemblyVersion("0.1.5")' "Assembly version must follow the StaxRip2 release line."
Assert-Contains $assemblyInfo 'AssemblyFileVersion("0.1.5")' "File version must follow the StaxRip2 release line."

$updateChecker = Read-RepoFile "Source/General/StaxRipUpdate.vb"
Assert-Contains $updateChecker 'api.github.com/repos/m00nxx/StaxRip2/releases?per_page=5' "Update checks must target the StaxRip2 fork releases."
Assert-NotContains $updateChecker 'api.github.com/repos/staxrip/staxrip/releases?per_page=5' "Update checks must not target upstream StaxRip releases."
Assert-Contains $updateChecker "Would you like StaxRip2 to check for updates periodically?" "Update prompts must identify the fork."
Assert-Contains $updateChecker 'Dim assetPlatforms = If(x64, {"x64"}, If(Environment.Is64BitOperatingSystem, {"x86", "x64"}, {"x86"}))' "32-bit update checks must fall back to x64 assets only on 64-bit Windows when x86 packages are not published."
Assert-Contains $updateChecker 'For Each assetPlatform In assetPlatforms' "Update checks must search all supported asset platforms for the current process."
Assert-Contains $updateChecker 'Regex.Escape(assetPlatform)' "Update checks must not hardcode x64 release asset matching."
Assert-Contains $updateChecker "(?<tag>v\d+\.\d+\.\d+" "Update checks must support multi-digit version components."
Assert-Contains $updateChecker "(?<version>\d+\.\d+\.\d+" "Update asset matching must support multi-digit version components."

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
Assert-Contains $mainForm "Dim sourceFilters = If(sourceCategory.Filters, New List(Of VideoFilter))" "Source filter preference matching must tolerate null filter lists."
Assert-NotContains $mainForm "sourceCategory.Filters.Where" "Source filter preference matching must not query possibly null filter lists."
Assert-NotContains $mainForm "MediaInfo.GetVideo(p.SourceFile, ""Format"").ToLowerInvariant" "Source filter preference matching must not query MediaInfo inside nested loops."
Assert-Contains $mainForm "Dim sourceFormat = MediaInfo.GetVideo(p.SourceFile, ""Format"")" "ModifyFilters must compute source video format once per pass."
Assert-Contains $mainForm "SetSourceFilter(sourceFilter, preferences, profiles, sourceFormat" "Source filter matching must reuse the cached source format."
Assert-Contains $mainForm "If Not String.IsNullOrWhiteSpace(sourceFormat) Then" "Source filter format matching must tolerate missing MediaInfo values."
Assert-Contains $mainForm "Dim matchedFilter = sourceFilters.FirstOrDefault(Function(cat) cat.Name = pref.Value)" "Source filter preference matching must avoid repeated filter enumeration."
Assert-NotContains $mainForm "sourceFilters.Where(Function(cat) cat.Name = pref.Value)" "Source filter preference matching must not enumerate source filters more than needed."
Assert-NotContains $mainForm "ModifyFiltersTrace.log" "Temporary source filter trace logging must not be committed."
Assert-Contains $mainForm "NormalizeCommandLineArguments(ParseCommandLine(commandLine)).ToArray()" "Command-line parsing must normalize unquoted template names with spaces."
Assert-Contains $mainForm 'arg.StartsWith("-" & NameOf(LoadTemplate) & ":", StringComparison.OrdinalIgnoreCase)' "LoadTemplate command-line arguments must tolerate unquoted spaces."
Assert-Contains $mainForm "Dim metadatas = FindHdrMetadata(p)" "HDR metadata discovery must not block on Task.Result from the UI flow."
Assert-NotContains $mainForm "Task.Run(Async Function() Await FindHdrMetadataAsync(p)).Result" "HDR metadata discovery must not synchronously wait on an async task."
Assert-Contains $mainForm "Function FindHdrMetadata(proj As Project)" "HDR metadata discovery must expose a synchronous helper for synchronous callers."
Assert-Contains $mainForm "GetExistingHdrSourcePaths(proj)" "HDR metadata extraction must filter missing source paths before directory scanning."
Assert-Contains $mainForm "Private Function GetExistingHdrSourcePaths(proj As Project) As String()" "HDR metadata extraction must use a shared path guard."
Assert-Contains $mainForm "File.Exists(path)" "HDR metadata extraction must skip missing source paths."
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

foreach ($legacyUpdateScriptPath in @("Source/Scripts/Legacy/Update.ps1", "Source/Scripts/Legacy/Update.py")) {
    $legacyUpdateScript = Read-RepoFile $legacyUpdateScriptPath
    Assert-Contains $legacyUpdateScript "disabled in StaxRip2" "$legacyUpdateScriptPath must be disabled in the fork."
    Assert-NotContains $legacyUpdateScript "Revan654/staxrip" "$legacyUpdateScriptPath must not download from old upstream release mirrors."
    Assert-NotContains $legacyUpdateScript "StaxRip.exe" "$legacyUpdateScriptPath must not launch or replace the upstream executable."
}

$logBuilder = Read-RepoFile "Source/General/LogBuilder.vb"
Assert-Contains $logBuilder '"StaxRip2:"' "Diagnostic logs must identify the fork."
Assert-Contains $logBuilder '"staxrip2.log"' "Diagnostic logs must use fork-specific filenames."
Assert-NotContains $logBuilder '"StaxRip:"' "Diagnostic logs must not identify as upstream StaxRip."
Assert-NotContains $logBuilder '"staxrip.log"' "Diagnostic logs must not use upstream log filenames."

$imageUtils = Read-RepoFile "Source/UI/ImageUtils.vb"
Assert-NotContains $imageUtils 'MsgWarn("Correct font was not found, using default instead!")' "Missing icon fonts must not show a startup warning dialog."

$toolUpdate = Read-RepoFile "Source/General/ToolUpdate.vb"
Assert-Contains $toolUpdate "Imports System.Threading.Tasks" "Tool update async methods must import Task."
Assert-Contains $toolUpdate "Application.ProductName" "Tool update dialogs must identify the current product."
Assert-Contains $toolUpdate "Async Function UpdateAsync() As Task" "Tool updates must expose an awaitable update task."
Assert-Contains $toolUpdate "Dim foundDownload = False" "Tool updates must report when no downloadable asset is found."
Assert-Contains $toolUpdate "Uri.TryCreate" "Tool updates must resolve relative download URLs through Uri instead of string slicing."
Assert-Contains $toolUpdate "No downloadable update asset was found" "Tool updates must tell the user when parsing found no asset."
Assert-Contains $toolUpdate "ExtractTimeoutMilliseconds" "Tool update extraction must have a timeout."
Assert-Contains $toolUpdate "If Not pr.WaitForExit(ExtractTimeoutMilliseconds) Then" "Tool update extraction must not block forever."
Assert-Contains $toolUpdate "pr.Kill()" "Tool update extraction must kill timed-out extractors."
Assert-Contains $toolUpdate "Function ConfirmReplacement()" "Tool updates must collect replacement confirmation before deleting current files."
Assert-Contains $toolUpdate "ReplaceFiles()" "Tool updates must replace files only after confirmation."
Assert-NotContains $toolUpdate 'MsgQuestion("Copy new files?"' "Tool updates must not ask a second copy confirmation after deleting current files."
Assert-Contains $toolUpdate "Catch ex As Exception" "Tool update network failures must be handled."
Assert-NotContains $toolUpdate '"StaxRip", MessageBoxButtons.OKCancel' "Tool update dialogs must not hardcode upstream branding."

$processHelp = Read-RepoFile "Source/General/Help.vb"
Assert-Contains $processHelp "DefaultConsoleOutputTimeoutMilliseconds" "Console output helpers must have a default timeout."
Assert-Contains $processHelp "RedirectStandardOutput = True" "Console output helpers must drain stdout to avoid process deadlocks."
Assert-Contains $processHelp "RedirectStandardError = True" "Console output helpers must drain stderr to avoid process deadlocks."
Assert-Contains $processHelp "ReadToEndAsync()" "Console output helpers must read redirected streams asynchronously."
Assert-Contains $processHelp "If Not proc.WaitForExit(timeoutMilliseconds) Then" "Console output helpers must not wait forever."
Assert-Contains $processHelp "Throw New TimeoutException" "Console output timeout failures must be explicit."

$documentation = Read-RepoFile "Source/General/Documentation.vb"
Assert-Contains $documentation "https://github.com/m00nxx/StaxRip2/issues/new?template=request-a-feature.md" "Generated documentation must link feature requests to the fork."
Assert-Contains $documentation "This page is based on the StaxRip2 version" "Generated documentation must identify the fork."
Assert-NotContains $documentation "https://github.com/staxrip/staxrip" "Generated runtime documentation must not link back to upstream issue pages."

$packageSource = Read-RepoFile "Source/General/Package.vb"
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/ffmpeg" "Package help links must target the fork wiki for ffmpeg."
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/qaac" "Package help links must target the fork wiki for qaac."
Assert-Contains $packageSource "https://github.com/m00nxx/StaxRip2/wiki/aomenc" "Package help links must target the fork wiki for aomenc."
Assert-NotContains $packageSource "https://github.com/staxrip/staxrip/wiki" "Package help links must not point to upstream StaxRip wiki pages."
Assert-Contains $packageSource "Directory.CreateDirectory(ConfPath.Dir)" "Package version saving must create Apps/Conf when the folder is missing."

$globalClassRuntime = Read-RepoFile "Source/General/GlobalClass.vb"
Assert-Contains $globalClassRuntime "If Not Directory.Exists(proj.TempDir) Then Return" "Temporary cleanup must tolerate missing temp directories."

$qsvEncSource = Read-RepoFile "Source/Encoding/QSVEnc.vb"
Assert-Contains $qsvEncSource "https://github.com/m00nxx/StaxRip2/wiki/qsvenc-bitrate-modes" "QSVEnc help links must target the fork wiki."
Assert-NotContains $qsvEncSource "https://github.com/staxrip/staxrip/wiki" "QSVEnc help links must not point to upstream StaxRip wiki pages."

$previewForm = Read-RepoFile "Source/Forms/PreviewForm.vb"
Assert-Contains $previewForm "ImageCodecInfo.GetImageEncoders.FirstOrDefault" "Preview image saving must tolerate a missing JPEG encoder."
Assert-Contains $previewForm "If info Is Nothing Then" "Preview image saving must check JPEG encoder lookup results."
Assert-NotContains $previewForm "ImageCodecInfo.GetImageEncoders.Where(Function(arg) arg.FormatID = ImageFormat.Jpeg.Guid).First" "Preview image saving must not assume a JPEG encoder exists."

$thumbnailer = Read-RepoFile "Source/General/Thumbnailer.vb"
Assert-Contains $thumbnailer "If imageCI Is Nothing Then" "Thumbnail saving must check image encoder lookup results."
Assert-Contains $thumbnailer "Image encoder was not found" "Thumbnail saving must fail with a clear encoder error."
Assert-Contains $thumbnailer "ImageCodecInfo.GetImageEncoders.FirstOrDefault(Function(arg)" "Thumbnail saving must avoid unnecessary encoder enumeration."
Assert-NotContains $thumbnailer "image.Save(imageFilePath, imageCI, imageEPs)" "Thumbnail saving must not use a possibly null image encoder."

$readme = Read-RepoFile "README.md"
Assert-Contains $readme "[Building from source](BUILDING.md)" "README must link to source build instructions."
Assert-Contains $readme "StaxRip2 uses its own settings registry key" "README must document StaxRip2 settings isolation."
Assert-Contains $readme "StaxRip2 does not currently publish project-specific donation links" "README must avoid confusing fork donations with upstream funding."
Assert-Contains $readme "StaxRip2 is a portable application" "README usage docs must identify the fork."
Assert-Contains $readme '`StaxRip2.exe`' "README usage docs must use the fork executable name."

$changelog = Read-RepoFile "CHANGELOG.md"
Assert-Contains $changelog "v0.1.5 (2026-05-28)" "Changelog must include the v0.1.5 release entry."
Assert-Contains $changelog "Made tool updates confirm replacement before deleting existing files" "Changelog must mention the tool update replacement fix."
Assert-Contains $changelog "Added timeouts for console helper process output" "Changelog must mention console helper timeout hardening."
Assert-Contains $changelog "v0.1.4 (2026-05-28)" "Changelog must include the v0.1.4 release entry."
Assert-Contains $changelog "Fixed internal object cloning" "Changelog must mention the internal cloning serialization fix."
Assert-Contains $changelog "Made x86 smoke checks validate 32-bit CLR flags" "Changelog must mention stronger x86 validation."
Assert-Contains $changelog "v0.1.3 (2026-05-28)" "Changelog must include the v0.1.3 release entry."
Assert-Contains $changelog "Fixed x86 release packaging" "Changelog must mention the x86 package fix."
Assert-Contains $changelog "Narrowed binary serialization type binding" "Changelog must mention serialization binder hardening."
Assert-Contains $changelog "Added CI package smoke coverage" "Changelog must mention CI package smoke coverage."
Assert-Contains $changelog "v0.1.2 (2026-05-28)" "Changelog must include the v0.1.2 release entry."
Assert-Contains $changelog "Hardened binary serialization" "Changelog must mention v0.1.2 serialization hardening."
Assert-Contains $changelog "Fixed update release detection" "Changelog must mention v0.1.2 update detection work."
Assert-Contains $changelog "Delegated legacy build helper scripts" "Changelog must mention v0.1.2 build helper cleanup."
Assert-Contains $changelog "v0.1.1 (2026-05-27)" "Changelog must include the v0.1.1 release entry."
Assert-Contains $changelog "full local release packaging" "Changelog must mention v0.1.1 packaging work."
Assert-Contains $changelog "package smoke checks" "Changelog must mention v0.1.1 smoke checks."
Assert-Contains $changelog "Fixed command-line template loading" "Changelog must mention the command-line template loading fix."
Assert-Contains $changelog "AppData fallbacks, mutex names, process checks" "Changelog must mention fork isolation cleanup."
Assert-Contains $changelog "StaxRip2-Release-x64" "Changelog must mention the GitHub Actions artifact."
Assert-Contains $changelog "Hardened source filter preference settings and preview JPEG saving" "Changelog must mention the targeted lookup hardening."

$issueTemplateConfig = Read-RepoFile ".github/ISSUE_TEMPLATE/config.yml"
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/discussions/new/choose" "Issue template discussion links must target the fork."
Assert-Contains $issueTemplateConfig "https://github.com/m00nxx/StaxRip2/blob/master/Docs/README.md" "Issue template documentation links must target the fork."
Assert-Contains $issueTemplateConfig "StaxRip2 Community Support" "Issue template contact links must identify the fork."
Assert-NotContains $issueTemplateConfig "https://github.com/staxrip/staxrip" "Issue template config must not point users back to upstream StaxRip."

$funding = Read-RepoFile ".github/FUNDING.yml"
Assert-Contains $funding "custom: []" "Fork funding config must not route StaxRip2 users to upstream maintainer donation accounts."
Assert-NotContains $funding "Dendraspis" "Fork funding config must not advertise upstream funding accounts as StaxRip2 funding."

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
Assert-Contains $buildDocs "Tests/SmokePackage.ps1" "Build docs must document the package smoke-check command."
Assert-Contains $buildDocs "StaxRip2-v0.1.5-x64.7z" "Build docs must document the v0.1.5 release archive name."
Assert-Contains $buildDocs "-RequireFullRuntime" "Build docs must document full runtime package validation."
Assert-Contains $buildDocs "Source/bin/Apps" "Build docs must document required packaged runtime apps."
Assert-Contains $buildDocs "Source/bin/Fonts" "Build docs must document required packaged fonts."
Assert-Contains $buildDocs "Source/bin/Fonts/Icons" "Build docs must document the actual packaged icon font location."
Assert-NotContains $buildDocs "Source/bin/Icons" "Build docs must not document a non-validated icon folder."
Assert-Contains $buildDocs "-CompressionLevel 0..9" "Build docs must document release compression tuning."

$workflow = Read-RepoFile ".github/workflows/build.yml"
Assert-Contains $workflow "windows-latest" "GitHub Actions build must run on Windows."
Assert-Contains $workflow "actions/checkout@v6.0.2" "GitHub Actions build must use a Node 24 compatible checkout action."
Assert-Contains $workflow "vswhere.exe" "GitHub Actions build must locate MSBuild with vswhere."
Assert-Contains $workflow '-products "*"' "GitHub Actions must quote the vswhere product wildcard."
Assert-Contains $workflow '(& $vswhere' "GitHub Actions must wrap vswhere invocation before piping its output."
Assert-Contains $workflow "NuGet/setup-nuget@v4.0" "GitHub Actions build must provision NuGet with a Node 24 compatible action."
Assert-Contains $workflow "Tests\SourceChecks.ps1" "GitHub Actions build must run source checks."
Assert-Contains $workflow "Tests\SmokePackage.ps1" "GitHub Actions build must run package smoke checks."
Assert-Contains $workflow "-UseMinimalRuntimeFixture" "GitHub Actions package smoke checks must prepare a minimal runtime fixture."
Assert-Contains $workflow "Source\StaxRip.vbproj" "GitHub Actions build must build the app project."
Assert-Contains $workflow "/p:Platform=x86" "GitHub Actions build must compile the x86 app path."
Assert-Contains $workflow "StaxRip2SmokeX86" "GitHub Actions smoke checks must exercise x86 package staging."
Assert-Contains $workflow "StaxRip2-Release-x64" "GitHub Actions build must publish the expected artifact."
Assert-Contains $workflow "actions/upload-artifact@v7.0.1" "GitHub Actions build must upload artifacts with a Node 24 compatible action."

foreach ($buildScriptPath in @("Source/Build.ps1", "Source/BuildAndPack.ps1", "Source/Release.ps1")) {
    $buildScript = Read-RepoFile $buildScriptPath
    Assert-Contains $buildScript "StaxRip2.exe" "$buildScriptPath must package the StaxRip2 executable."
    Assert-Contains $buildScript "StaxRip2" "$buildScriptPath must use fork-specific package names."
    Assert-NotContains $buildScript "StaxRip.exe" "$buildScriptPath must not package the upstream executable."
    Assert-NotContains $buildScript "A:\StaxRip-Releases" "$buildScriptPath must not require the maintainer-specific release drive."
}

$buildScript = Read-RepoFile "Source/Build.ps1"
Assert-Contains $buildScript "Source/Release.ps1" "Legacy Build.ps1 must delegate to the maintained release script."
Assert-Contains $buildScript '& $releaseScript' "Legacy Build.ps1 must invoke the maintained release script directly."

$buildAndPackScript = Read-RepoFile "Source/BuildAndPack.ps1"
Assert-Contains $buildAndPackScript "Source/Release.ps1" "Legacy BuildAndPack.ps1 must delegate to the maintained release script."
Assert-Contains $buildAndPackScript '& $releaseScript' "Legacy BuildAndPack.ps1 must invoke the maintained release script directly."

$releaseScript = Read-RepoFile "Source/Release.ps1"
Assert-Contains $releaseScript "param(" "Release packaging must be configurable from the command line."
Assert-Contains $releaseScript "function Get-BinDirectory" "Release packaging must choose the runtime bin directory from the target platform."
Assert-Contains $releaseScript 'Get-BinDirectory "x64"' "Release packaging must fall back to the bundled x64 7-Zip when packaging x86 output."
Assert-Contains $releaseScript 'Get-BinDirectory $Platform' "Release packaging must not hardcode Source/bin for every platform."
Assert-Contains $releaseScript '"bin-x86"' "Release packaging must use Source/bin-x86 for x86 packages."
Assert-Contains $releaseScript 'ArchiveReadyTimeoutSeconds = 300' "Release archive readiness timeout must be configurable and long enough for large packages."
Assert-Contains $releaseScript "/t:Rebuild" "Release packaging must rebuild so version changes are reflected in the package."
Assert-Contains $releaseScript "Source/StaxRip.vbproj" "Release packaging must support app-only builds for source checkouts."
Assert-Contains $releaseScript '-products "*"' "Release packaging must quote the vswhere product wildcard."
Assert-Contains $releaseScript '(& $vswhere' "Release packaging must wrap vswhere invocation before piping its output."
Assert-Contains $releaseScript 'StaxRip2-v$version-$Platform' "Release archive naming must match update-check expectations."
Assert-Contains $releaseScript "README.md" "Release packages must include README.md."
Assert-Contains $releaseScript "CHANGELOG.md" "Release packages must include CHANGELOG.md."
Assert-Contains $releaseScript '"^Settings[\\/](?!Templates([\\/]|$)).*"' "Release packages must exclude user settings while keeping startup templates."
Assert-Contains $releaseScript "Test-Path (Join-Path `$binDirectory 'Apps')" "Release packaging must validate bundled runtime apps."
Assert-Contains $releaseScript "Test-Path (Join-Path `$binDirectory 'Fonts')" "Release packaging must validate bundled fonts."
Assert-Contains $releaseScript 'Test-Path (Join-Path $binDirectory "Settings\Templates")' "Release packaging must validate startup templates."
Assert-Contains $releaseScript "Assert-FullRuntimeAssets" "Release packaging must be able to validate key full runtime assets."
Assert-Contains $releaseScript "Apps\Support\MediaInfo.NET\MediaInfo.dll" "Release packaging full runtime validation must include MediaInfo."
Assert-Contains $releaseScript "Settings\Templates\Automatic Workflow.srip" "Release packaging full runtime validation must include startup templates."
Assert-Contains $releaseScript 'Test-Path (Join-Path $repoRoot "License.txt")' "Release packaging must validate the root license file instead of requiring a duplicate bin license."
Assert-NotContains $releaseScript 'Join-Path $binDirectory "License.txt"' "Release packaging must not require a duplicate license file in Source/bin."
Assert-Contains $releaseScript "vs-temp-dl" "Release packages must exclude temporary VapourSynth download caches."
Assert-Contains $releaseScript "function Copy-PackageItem" "Release packaging must prune excluded directories before recursion."
Assert-NotContains $releaseScript 'Get-ChildItem -LiteralPath $binDirectory -Recurse -Force' "Release packaging must not recursively enumerate excluded runtime trees."

$smokePackage = Read-RepoFile "Tests/SmokePackage.ps1"
Assert-Contains $smokePackage 'ArchiveReadyTimeoutSeconds = 300' "Package smoke archive readiness timeout must be configurable and long enough for large packages."
Assert-Contains $smokePackage "function Resolve-SevenZip" "Package smoke checks must resolve 7-Zip once instead of duplicating listing logic."
Assert-Contains $smokePackage 'Get-BinDirectory "x64"' "Package smoke checks must fall back to the bundled x64 7-Zip when validating x86 archives."
Assert-Contains $smokePackage "RequireFullRuntime" "Package smoke checks must support full runtime validation."
Assert-Contains $smokePackage "Assert-FullRuntimeArchive" "Package smoke checks must validate key runtime files in full release archives."
Assert-Contains $releaseScript '(^|.*[\\/])ManagedCuda\.(pdb|xml)$' "Release packages must exclude top-level ManagedCuda debug metadata."
Assert-Contains $releaseScript '(^|.*[\\/])System\.Management\.Automation\.xml$' "Release packages must exclude top-level PowerShell XML metadata."
Assert-Contains $releaseScript "function Wait-FileReady" "Release packaging must wait until the 7z archive is fully written."
Assert-Contains $releaseScript "If (`$SkipArchive)" "Release packaging must report staging output when archive creation is skipped."
Assert-Contains $releaseScript "Release staging prepared" "Release packaging skip-archive output must not claim a 7z package exists."
Assert-Contains $releaseScript "function Join-Argument" "Release packaging must escape 7-Zip command arguments consistently."
Assert-Contains $releaseScript "Start-Process -FilePath `$sevenZip" "Release packaging must run 7-Zip with explicit process exit handling."
Assert-Contains $releaseScript "CompressionLevel = 5" "Release packaging must use a practical default compression level."
Assert-Contains $releaseScript "-mx`$CompressionLevel" "Release packaging compression must be configurable."
Assert-Contains $releaseScript "7z" "Release packaging must create a 7z archive."

$smokePackage = Read-RepoFile "Tests/SmokePackage.ps1"
Assert-Contains $smokePackage "Tests\SourceChecks.ps1" "Package smoke test must run source checks first."
Assert-Contains $smokePackage "Source\Release.ps1" "Package smoke test must exercise release packaging."
Assert-Contains $smokePackage "function Get-BinDirectory" "Package smoke test must validate the platform-specific output directory."
Assert-Contains $smokePackage "function Resolve-PowerShell" "Package smoke test must not assume `$PSHOME\powershell.exe exists."
Assert-Contains $smokePackage "function Assert-ExecutableArchitecture" "Package smoke test must validate the packaged executable architecture."
Assert-Contains $smokePackage "function Get-PECorFlags" "Package smoke test must validate CLR architecture flags, not only the PE machine."
Assert-Contains $smokePackage "32BITREQ" "Package smoke test must require true 32-bit CLR output for x86 packages."
Assert-Contains $smokePackage "UseMinimalRuntimeFixture" "Package smoke test must support CI release packaging coverage without full runtime assets."
Assert-Contains $smokePackage 'Set-Content -LiteralPath $targetTemplate -Value "Minimal runtime fixture template."' "Package smoke minimal fixtures must create startup templates."
Assert-Contains $smokePackage 'Join-Path $ArtifactsDirectory "$packageName.7z"' "Package smoke test must validate updater-compatible archive naming."
Assert-NotContains $smokePackage 'Join-Path $PSHOME "powershell.exe"' "Package smoke test must not assume Windows PowerShell lives under `$PSHOME."
Assert-Contains $smokePackage 'SevenZipPath' "Package smoke test must support explicit 7-Zip paths."
Assert-Contains $smokePackage 'CompressionLevel' "Package smoke test must pass through release compression settings."
Assert-Contains $smokePackage "Start-Process -FilePath `$sevenZip" "Package smoke test must list archives with explicit process exit handling."
Assert-Contains $smokePackage "7z listing failed after waiting for the archive" "Package smoke test must retry archive listing while the file is settling."
Assert-Contains $smokePackage "StaxRip2.exe" "Package smoke test must validate executable presence."
Assert-Contains $smokePackage "Apps\Conf" "Package smoke test must validate packaged app configuration."
Assert-Contains $smokePackage "Fonts\Icons" "Package smoke test must validate packaged fonts."
Assert-Contains $smokePackage "Settings\Templates" "Package smoke test must validate packaged startup templates."
Assert-Contains $smokePackage "User settings must not be included" "Package smoke test must reject packaged user settings outside templates."
Assert-Contains $smokePackage "Assert-ArchiveDoesNotContain" "Package smoke test must validate release exclusions."
Assert-Contains $smokePackage "ManagedCuda.xml" "Package smoke test must reject debug XML files."
Assert-Contains $smokePackage "vs-temp-dl" "Package smoke test must reject temporary download caches."
Assert-Contains $smokePackage "Start-Sleep -Milliseconds 500" "Package smoke test must tolerate filesystem visibility delay after packaging."

$releaseNotes = Read-RepoFile "RELEASE_NOTES.md"
Assert-Contains $releaseNotes "# StaxRip2 v0.1.5" "Release notes must identify the v0.1.5 release."
Assert-Contains $releaseNotes "StaxRip2-v0.1.5-x64.7z" "Release notes must document the full package asset."
Assert-Contains $releaseNotes "app-only" "Release notes must distinguish CI artifact scope from full packages."

$docsReadme = Read-RepoFile "Docs/README.md"
Assert-Contains $docsReadme "inherited from upstream StaxRip and is being audited for StaxRip2" "Documentation root must disclose inherited upstream documentation state."
Assert-Contains $docsReadme "StaxRip2 does not currently publish project-specific donation links" "Documentation root must avoid confusing fork donations with upstream funding."
Assert-NotContains $docsReadme "Dendraspis" "Documentation root must not advertise upstream funding accounts as StaxRip2 funding."

$docsSupport = Read-RepoFile "Docs/Support/README.md"
Assert-Contains $docsSupport "StaxRip2 does not currently publish project-specific donation links" "Support docs must avoid confusing fork donations with upstream funding."
Assert-NotContains $docsSupport "Dendraspis" "Support docs must not advertise upstream funding accounts as StaxRip2 funding."

$jobManager = Read-RepoFile "Source/General/JobManager.vb"
Assert-NotContains $jobManager "formatter As New BinaryFormatter" "Job serialization must use the guarded formatter factory."

$helpSource = Read-RepoFile "Source/General/Help.vb"
Assert-Contains $helpSource "SafeSerialization.CreateCloneFormatter()" "Object cloning must use the dedicated internal clone formatter."
Assert-NotContains $helpSource "New BinaryFormatter" "Object cloning must use the guarded formatter factory."

$themeSource = Read-RepoFile "Source/UI/Theme.vb"
Assert-NotContains $themeSource "New BinaryFormatter" "Theme serialization must use the guarded formatter factory."

Write-Host "Source checks passed."
