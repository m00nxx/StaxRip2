# StaxRip2 v0.1.7

This release fixes follow-up issues found during deeper bug hunting after v0.1.6.

## Changes

- Added optional SHA256 validation for runtime payload archives and made URL downloads use temporary `.download` files before cache reuse.
- Separated tool file replacement rollback from post-copy version metadata updates and command tests.
- Cleaned temporary tool extraction folders on failed extraction, cancellation, and replacement failure paths.
- Hardened update checks against malformed GitHub release data and corrupted dismissed-version settings.
- Added stream-drain timeout handling and safer process-tree termination for external console helpers.
- Improved eac3to analysis robustness by draining stderr and using an explicit longer analysis timeout.
- Fixed release and smoke packaging script process invocation and made archive readiness checks tolerate antivirus or indexer readers.
- Made missing source filter failures explicit and avoided duplicate job-file error dialogs.

## Notes

- Full release archive: `StaxRip2-v0.1.7-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
