# Building StaxRip2 from Source

This repository contains both the main StaxRip2 application and the native FrameServer project.

## Required Tools

Use Visual Studio 2022 or Visual Studio Build Tools 2022 on Windows.

For the main VB.NET application:

- .NET Framework 4.8 Developer Pack or targeting pack
- MSBuild for .NET Framework projects
- NuGet package restore support

For the full solution, including `Source/FrameServer/FrameServer.vcxproj`:

- Visual Studio workload: `Microsoft.VisualStudio.Workload.NativeDesktop`
- Build Tools workload: `Microsoft.VisualStudio.Workload.VCTools`
- MSVC x64/x86 build tools, included by the recommended C++ workload components

If the full solution fails with an error mentioning `Microsoft.Cpp.Default.props`, the C++ workload is missing or MSBuild is not running from an environment that can find the Visual C++ targets.

## Installing the C++ Build Workload

For Visual Studio Community 2022:

```powershell
& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify --installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --passive --norestart
```

For Visual Studio Build Tools 2022:

```powershell
& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart
```

Run these commands from an elevated PowerShell prompt. If they are started from a non-elevated shell, the Visual Studio Installer can fail with exit code `5007`.

## App-only Build

This builds the main StaxRip2 executable without rebuilding the native FrameServer project:

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Source/StaxRip.vbproj /t:Build /p:Configuration=Release /p:Platform=x64 /m
```

Expected output:

```text
Source\bin\StaxRip2.exe
```

## GitHub Actions

The repository includes a GitHub Actions workflow at `.github/workflows/build.yml`.

The workflow runs on Windows, restores NuGet packages, runs `Tests/SourceChecks.ps1`, builds `Source/StaxRip.vbproj`, and uploads an artifact named `StaxRip2-Release-x64`.

This is an app-only artifact. It contains the compiled executable and nearby build outputs, but it is not a complete release package with bundled runtime tools, fonts, and application assets.

## Full Solution Build

This builds the main application and FrameServer:

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Source/StaxRip.sln /t:Build /p:Configuration=Release /p:Platform=x64 /m
```

Use this mode when preparing a complete source build.

## Runtime Assets

The Git repository contains source code and project files. Published release archives are expected to include runtime assets such as bundled tools, fonts, icons, and settings templates. If you run a locally built executable directly from a clean source tree, make sure the expected runtime folders are present under the application startup directory.

StaxRip2 includes startup guards for missing `Fonts` and `Apps/Conf` folders, but a complete package should still include the runtime assets needed for normal encoding workflows.

## Full Release Package

Use `Source/Release.ps1` from a source tree that already has the full runtime payload under `Source/bin`.

Required runtime folders include:

- `Source/bin/Apps`
- `Source/bin/Apps/Conf`
- `Source/bin/Fonts`
- `Source/bin/Fonts/Icons`

Example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Source/Release.ps1 -Platform x64
```

Before publishing a package, run the package smoke checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tests/SmokePackage.ps1 -Platform x64 -CompressionLevel 5
```

Use `-CompressionLevel 0..9` if you need to trade package size for packaging speed. The default is `5`.

For `v0.1.4`, the release archive is expected to be named `StaxRip2-v0.1.4-x64.7z`.

The GitHub Actions workflow intentionally publishes only an app-only artifact. Full release packaging is local until the runtime payload is made reproducible from a clean checkout.
