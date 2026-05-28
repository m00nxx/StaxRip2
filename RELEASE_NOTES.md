# StaxRip2 v0.1.3

This release hardens release packaging, package smoke checks, serialization binding, HDR metadata discovery, and fork-facing documentation.

## Changes

- Fixed x86 release packaging so x86 archives are built from `Source/bin-x86`.
- Narrowed binary serialization type binding with explicit allowed type names and type-name prefixes.
- Added CI package smoke coverage with a minimal runtime fixture.
- Added package smoke validation for PowerShell discovery and executable architecture.
- Hardened HDR metadata discovery so missing source paths are skipped before MediaInfo and directory scans.
- Hardened tool update download parsing with URI-based relative URL resolution and a clear no-asset message.
- Removed confusing fork funding links and disabled the obsolete legacy upstream updater script.
- Updated build docs, issue templates, release notes, and inherited documentation notices for the StaxRip2 fork.

## Notes

- Full release archive: `StaxRip2-v0.1.3-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
