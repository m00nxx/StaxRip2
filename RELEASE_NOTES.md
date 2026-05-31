# StaxRip2 v0.1.6

This release fixes follow-up issues found during deeper bug hunting after v0.1.5.

## Changes

- Added runtime payload bootstrapping for release packaging from a previous StaxRip2 archive or URL.
- Made tool replacement transactional with rollback if copying the new tool files fails.
- Killed external helper process trees on timeout and added timeout handling to eac3to source analysis.
- Hardened source filter fallback handling for corrupt filter profile settings.
- Preserved corrupt `Jobs.dat` files with a `.corrupt` backup instead of silently dropping jobs.
- Added stricter full-runtime checks for default bundled UI/code fonts.

## Notes

- Full release archive: `StaxRip2-v0.1.6-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
