# StaxRip2 v0.1.5

This release fixes follow-up issues found during deeper bug hunting after v0.1.4.

## Changes

- Made tool updates confirm replacement before deleting existing files.
- Added timeouts for console helper process output and drained stdout/stderr asynchronously.
- Made 32-bit update checks fall back to x64 release assets when no x86 package is published.
- Added full runtime package validation for key bundled tools, templates, and runtime files.
- Fixed release packaging so startup templates are included while user settings remain excluded.
- Updated release packaging smoke checks for full-runtime release validation.

## Notes

- Full release archive: `StaxRip2-v0.1.5-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
