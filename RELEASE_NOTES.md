# StaxRip2 v0.1.2

This release hardens project/settings serialization, build tooling, update checks, and release packaging.

## Changes

- Hardened binary serialization through a centralized formatter factory with an allow-list binder.
- Fixed mutex handling for settings, profile, and event serialization so acquired mutexes are always released.
- Fixed update release detection for multi-digit StaxRip2 version components.
- Hardened tool updates so download-page failures are handled instead of escaping from `Async Sub`.
- Repaired partially missing source filter defaults inside existing filter profile categories.
- Optimized release packaging by pruning excluded runtime directories before recursive copy.
- Delegated legacy build helper scripts to the maintained release packaging script.
- Aligned GitHub Actions MSBuild discovery and build documentation with release script behavior.

## Notes

- Full release archive: `StaxRip2-v0.1.2-x64.7z`
- The GitHub Actions artifact is app-only and is not a full runtime package.
- MIT license and original StaxRip attribution are preserved.
