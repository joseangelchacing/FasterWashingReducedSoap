# Changelog

All notable changes to Faster Washing & Reduced Soap Consumption are documented in this file.

This changelog follows a simplified version of the Keep a Changelog format.

## [Unreleased]

Changes currently in development and not yet included in a published release.

### Added

-

### Changed

-

### Fixed

-

### Technical

-

## [Published Baseline]

Historical features and improvements included in the published project baseline.

### Added

- Configurable clothing-washing duration.
- Configurable personal-washing duration.
- Configurable solid soap consumption.
- Configurable CleaningLiquid consumption.
- Independent Sandbox configuration options.
- English and Spanish Workshop descriptions.

### Changed

- Washing duration logic moved to shared Lua.
- Solid soap consumption logic moved to shared Lua.
- CleaningLiquid consumption logic moved to shared Lua.
- Target compatibility updated to Project Zomboid Build 42.22.2.

### Fixed

- Corrected the soap-availability estimate to account for reduced CleaningLiquid consumption.
- Corrected an issue with multiplayer synchronization.

### Technical

- Preserved vanilla instant timed-action behavior.
- Added internal markers to prevent duplicate patch installation and preserve adjusted solid-soap state.

---

## Changelog Guidelines

- Record meaningful changes, not every minor edit.
- Separate new features, modifications, fixes, and technical changes.
- Do not document planned features as completed.
- Move released changes from `[Unreleased]` into a dated version section.
- Only include changes that have actually been implemented and verified.

### Example

```text
## [1.1.0] - YYYY-MM-DD

### Added
- New configurable washing feature.

### Fixed
- Corrected an issue with multiplayer synchronization.
```
