# Changelog

All notable changes to SwiftCursesKit will be documented in this file. The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to [Semantic Versioning](https://semver.org/).

## How to use this file

1. Start every pull request by adding entries under the **Unreleased** section.
2. Group entries by the categories below and use bullet points written in the imperative mood.
3. When publishing a release, promote the **Unreleased** section to a dated version heading and create a new empty **Unreleased** section.
4. Link Git tags and compare ranges in version headings once the release is published.

## [Unreleased]

### Added
- _Example_: Introduce `Panel` scene helper for overlay windows.

### Changed
- _Example_: Adjust default tick rate to 60 FPS to smooth animations.

### Fixed
- _Example_: Prevent cursor flicker when rendering gauges on macOS terminals.

### Removed
- _Example_: Deprecate legacy color pairing APIs in favor of `ColorPalette` helpers.

### Documentation
- _Example_: Expand Dashboard tutorial with mouse event walkthrough.

---

## Template

Use the snippet below when cutting a new release entry. Replace `0.1.0` with the version and `2024-01-15` with the release date.

```
## [0.1.0] - 2024-01-15
### Added
- 

### Changed
- 

### Fixed
- 

### Removed
- 

### Documentation
- 
```

Link comparison URLs once tags exist, for example:

```
[Unreleased]: https://github.com/your-org/SwiftCursesKit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/SwiftCursesKit/releases/tag/v0.1.0
```
