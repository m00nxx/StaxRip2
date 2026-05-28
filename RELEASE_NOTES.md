# StaxRip2 v0.1.4

This release fixes follow-up issues found during deeper bug hunting after v0.1.3.

## Changes

- Fixed internal object cloning by separating trusted in-memory clone serialization from guarded file deserialization.
- Changed x86 builds to true x86 output and strengthened smoke checks to validate 32-bit CLR flags.
- Added a release packaging fallback so x86 packages can use the bundled x64 7-Zip when needed.
- Added timeout handling for tool update extraction.
- Made package configuration saving recreate `Apps/Conf` when missing.
- Hardened temp cleanup and HDR metadata lookup against missing directories.
- Made update checks match release assets for the current process architecture.

## Notes

- Full release archive: `StaxRip2-v0.1.4-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
