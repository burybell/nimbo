# Changelog

All notable changes to Nimbo will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/) for published releases.

## [Unreleased]

### Added

- Editable request and read-only response JSON code surfaces with native selection, caret, and syntax highlighting
- Global search for requests, collections, history, environments, and primary commands, available from the toolbar and `Ctrl+K`
- Persistent built-in Development, Staging, and Production environments

### Changed

- Reworked the HTTP method picker with method-specific colors and a top-layer menu
- Combined New and import actions into a single split button and removed the duplicate settings entry
- Migrated local data to schema v4 while preserving existing environment values and imported environments
- Removed the duplicate in-panel sending banner and pinned environment/history scroll content to the top

## [0.1.0-alpha] - 2026-09-10

### Added

- Native HarmonyOS request workspace for PC, tablet, and phone layouts
- HTTP request execution with params, headers, authentication, body types, redirects, cancellation, and environment variables
- Response body, headers, cookies, error, large-response, and binary-response states
- Persistent collections, nested folders, environments, history, preferences, and restored tabs
- Request saving into collections with automatic updates for saved requests
- cURL import/export, Postman Collection/Environment import, and Nimbo backup export
- Light, dark, and system themes with English and Simplified Chinese interfaces
- Immersive HarmonyOS PC window chrome and consistent motion across core interactions

### Security

- Signing profiles and machine-specific build credentials are excluded from version control
- Public build configuration is provided without credentials
- Private vulnerability reporting, dependency alerts, and automated security updates are enabled

### Project

- Added AGPL-3.0-only licensing, contributor governance, security policy, issue and pull request templates
- Added local repository checks and a GitHub Actions quality gate
- Verified a clean-clone unsigned HAP build without official signing credentials
