# Changelog

All notable changes to Nimbo will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/) for published releases.

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
