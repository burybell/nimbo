# Changelog

All notable changes to Nimbo will be documented in this file.

The project follows [Semantic Versioning](https://semver.org/) for published releases.

## [Unreleased]

### Added

- Collection and nested-folder variables with deterministic inheritance across HTTP, WebSocket, SSE, scripts, and Collection Runner
- Effective-variable inspection with masked secrets, source labels, override chains, proactive missing-value detection, and direct source editing
- Collection-level Postman variable import and recursive secret redaction in Nimbo exports
- Offline in-app help center with eleven task-oriented guides covering collections, imports, requests, variables, scripts, automation, Runner, real-time connections, shortcuts, and troubleshooting
- Complete English and Simplified Chinese user manuals plus focused variable guides linked from the repository README files
- Detailed English and Simplified Chinese script references covering syntax, guarded APIs, completion, examples, execution order, limits, and troubleshooting
- Runnable OpenAI Responses and DeepSeek Chat Completions SSE examples with editable JSON request bodies
- Automatic pretty-printing and syntax highlighting for JSON WebSocket messages and SSE event data, with plain-text fallback

### Changed

- Migrated local data to schema v14, updated built-in examples to use scoped variables, and non-destructively added AI streaming requests to existing example collections
- Updated unresolved-variable diagnostics to account for environment, collection, folder, and Runner scopes
- Added JSON and text request bodies to SSE so POST-based streaming APIs can be configured and variable-resolved
- Stabilized title-bar action placement across full-screen restore and kept search before environment/import/settings at narrow desktop widths
- Replaced the detached WebSocket Send button with an integrated icon action; Enter/Ctrl+Enter sends and Shift+Enter inserts a line break

## [1.0] - 2026-09-12

### Added

- Editable request and read-only response JSON code surfaces with native selection, caret, and syntax highlighting
- Global search for requests, collections, history, environments, and primary commands, available from the toolbar and `Ctrl+K`
- Persistent built-in Development, Staging, and Production environments
- Local custom-environment creation with variable editing and guarded deletion
- Native image and video response previews with metadata tabs, playback controls, and original-file saving
- Response-body search with match navigation, full-body clipboard copy, and content-type-aware downloads
- AppGallery-ready PC artwork, five verified 16:9 screenshots, Chinese listing copy, and an importable showcase collection
- OpenAPI 3.0/3.1 and Swagger 2.0 JSON import with tag folders, request previews, generated body examples, and unsupported-feature warnings
- Response JSONPath preview and post-response environment extraction with explicit targets, secret flags, visible outcomes, and overwrite protection
- Declarative response tests for status code, response time, headers, and JSONPath with localized pass/fail details
- Unified title-bar import dialog with cURL and API-file tabs; cURL input has syntax highlighting, while API files support drag-and-drop detection for Postman, OpenAPI 3.x, and Swagger 2.0 without shifting the workspace
- Sandboxed QuickJS-NG runtime with asynchronous execution, time, memory, stack, source, concurrency, and console-output limits
- Per-request Pre-request and Post-response scripts with JavaScript editing, guarded request/response/environment APIs, and visible console, error, timing, and limit results
- Context-aware script completion for available `nimbo.request`, `nimbo.response`, `nimbo.environment`, `console`, and `JSON` APIs with keyboard navigation and Enter/Tab acceptance
- Real response timing timeline with DNS, connection, TLS, request send, TTFB, download, and total durations from the HarmonyOS network stack
- Request-tab context menu with close-current, close-all, and new-request actions
- Active-environment variable highlighting and completion across request URLs, Params, Headers, authentication, JSON/raw bodies, forms, and Multipart fields, with keyboard selection and Enter/Tab acceptance after typing `{{`
- Per-request code generation for cURL, JavaScript Fetch, Python Requests, and Go net/http, with one-click copy and unexpanded environment-variable references
- Syntax highlighting for generated Python and Go examples
- Inline request-tab renaming by double-click, with Enter/blur confirmation and Esc cancellation

### Changed

- Reworked the HTTP method picker with method-specific colors and a top-layer menu
- Combined New and import actions into a single split button and removed the duplicate settings entry
- Migrated local data to schema v9 while preserving existing requests, environments, extraction rules, tests, scripts, and older preferences
- Localized built-in environment names and the starter collection data in Simplified Chinese
- Removed the duplicate in-panel sending banner and pinned environment/history scroll content to the top
- Removed the request-toolbar Save button; `Ctrl+S` now updates collected requests directly or opens collection-folder selection for new requests
- Refined the Nimbo app mark and replaced the toolbar settings glyph with a native-style rounded gear icon
- Added a persistent interface-font preference with HarmonyOS Sans, system-default, and compact choices
- Anchored per-request settings at the top and refined key-value table typography and column alignment
- Replaced the title-bar environment Select with a compact 28vp custom switcher and smaller typography
- Replaced font-glyph search marks with vertically centered SVG icons in the toolbar and search dialog
- Delegated title-bar click, double-click, and drag handling to the native window manager
- Stored media responses in replaceable app-cache files for safe native preview without persisting response bytes
- Replaced response text actions with compact search, copy, and download icon controls
- Limited the current distribution manifest to HarmonyOS PC (`2in1`) while retaining responsive layouts in source
- Expanded the first-run Chinese examples into user, content, media, response, and authentication folders

### Fixed

- Preserved environment variable values and descriptions when toggling Secret by using stable row identity and field-level updates
- Masked environment values immediately after Secret is enabled while retaining the underlying value when toggled back
- Made URL variable completion accept both main/numpad Enter and Tab consistently, while retaining URL-editor focus without a trailing system focus ring
- Separated environment Save and Delete actions with consistent spacing and left-aligned environment details on desktop and compact layouts
- Evaluated response-time tests from the numeric timing snapshot instead of treating display values such as `684 ms` as numbers
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
- Restored reliable `Ctrl+Z` undo and `Ctrl+Shift+Z` / `Ctrl+Y` redo in styled JSON and JavaScript editors
- Restored `Ctrl+A` select-all in code surfaces and reapplied syntax styling whenever generated-code languages change
- Kept collection request names, saved request metadata, and matching open tabs synchronized after tab renaming
- Routed script-completion navigation and acceptance through RichEditor key dispatch so Up/Down, Enter, and Tab cannot be consumed as caret movement, newline, or focus traversal
- Kept empty and environment-variable authentication secrets visible for editing and completion, while masking only non-empty literal Bearer tokens, Basic passwords, and API key values
- Refreshed environment value editors immediately when Secret changes and aligned masked-value padding with the normal value column
- Kept the active script-completion candidate visible by automatically scrolling the compact suggestion list during keyboard navigation
- Replaced the sidebar New button's font plus with a fixed SVG so the icon remains centered and unclipped in non-maximized windows
- Replaced font-dependent sidebar and mobile navigation glyphs with a consistent rounded-stroke SVG family and stronger active states
- Redesigned the application mark as a dimensional pearl-ribbon N using the UI's restrained periwinkle and success-mint palette, including the 216 px AppGallery asset
- Synchronized custom title-bar action opacity with native window active and inactive states
- Rebuilt the five AppGallery screenshots as 1920 × 1080 posters using maximized, aspect-ratio-preserved UI captures and HarmonyOS Sans SC typography

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
