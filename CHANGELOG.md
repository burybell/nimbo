# Changelog

All notable changes to Nimbo will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/) for published releases.

## [Unreleased]

### Added

- Editable request and read-only response JSON code surfaces with native selection, caret, and syntax highlighting
- Global search for requests, collections, history, environments, and primary commands, available from the toolbar and `Ctrl+K`
- Persistent built-in Development, Staging, and Production environments
- Local custom-environment creation with variable editing and guarded deletion
- Native image and video response previews with metadata tabs, playback controls, and original-file saving
- Response-body search with match navigation, full-body clipboard copy, and content-type-aware downloads

### Changed

- Reworked the HTTP method picker with method-specific colors and a top-layer menu
- Combined New and import actions into a single split button and removed the duplicate settings entry
- Migrated local data to schema v5 while preserving existing environment values, imported environments, and older preferences
- Localized built-in environment names and the starter collection data in Simplified Chinese
- Removed the duplicate in-panel sending banner and pinned environment/history scroll content to the top
- Separated the URL group, Save action, and Send action with consistent toolbar spacing
- Refined the Nimbo app mark and replaced the toolbar settings glyph with a native-style rounded gear icon
- Added a persistent interface-font preference with HarmonyOS Sans, system-default, and compact choices
- Anchored per-request settings at the top and refined key-value table typography and column alignment
- Replaced the title-bar environment Select with a compact 28vp custom switcher and smaller typography
- Replaced font-glyph search marks with vertically centered SVG icons in the toolbar and search dialog
- Delegated title-bar click, double-click, and drag handling to the native window manager
- Stored media responses in replaceable app-cache files for safe native preview without persisting response bytes
- Replaced response text actions with compact search, copy, and download icon controls

### Fixed

- Synchronized RichEditor changes before request dispatch so edited JSON bodies cannot send stale content
- Kept the global search control centered when the desktop window is maximized
- Reserved response-header space correctly so the final JSON lines remain reachable
- Added persistent renaming for collection requests and their matching open tabs
- Added a light-theme code palette for JSON and raw response surfaces
- Prevented the New import menu from overlapping sidebar navigation items
- Reserved native title-button space when the desktop window enters the phone breakpoint
- Balanced collection-tree indentation so nested levels remain clear without consuming excessive horizontal space
- Centered the empty workspace state within all remaining content space below the request tab bar
- Anchored every settings section to the top of its scrollable content area on desktop and phone layouts
- Replaced collection-tree square glyphs with familiar closed and open folder icons
- Unified collection, folder, and request actions under row-level overflow menus with create, rename, duplicate, and guarded delete flows
- Positioned desktop collection menus at the pointer without shifting tree rows, added hover-only ellipsis coloring, and dismissed menus on pointer exit
- Made the collection sidebar resizable on PC and tablet layouts, with persisted width limits and double-click reset
- Smoothed JSON body editing by avoiding full syntax reconstruction and local-state serialization on every keystroke
- Added code-editor JSON behavior: smart newline indentation, colon spacing, Tab/Shift+Tab, paired deletion, delimiter pairing, selection wrapping, and closing-character overtype
- Aligned request-tab close actions to the trailing edge and unified Method/URL into one softly divided input control
- Replaced circular key-value toggles with compact square checkboxes and redesigned multipart type selection as a lightweight popup
- Removed decorative checks from key-value headers, replaced the Method caret glyph with a balanced SVG icon, and refreshed open tabs immediately after collection-request renames
- Added focused URL protocol completion: `h` + Tab expands to `http://` and `hs` + Tab expands to `https://`
- Made response search directly discoverable, reduced its input typography, and added `Esc` dismissal with automatic focus

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
