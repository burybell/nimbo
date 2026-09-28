# Nimbo User Guide

English · [简体中文](user-guide.zh-CN.md)

This guide covers features implemented in the current repository. Nimbo is a local-first desktop API client. Requests, collections, environments, history, and preferences are stored locally and require no account.

## 1. Quick start

1. Select New and choose an HTTP, WS, or SSE request.
2. For HTTP, choose a method, enter the URL, and configure parameters, headers, authentication, and body as needed.
3. Select Send or press `Ctrl+Enter`.
4. Inspect the body, headers, cookies, scripts, tests, and timeline in the lower pane.
5. Press `Ctrl+S`, choose a collection or folder, and save.

You can also select Import in the title bar to start from cURL, Postman, OpenAPI, or Swagger.

## 2. Workspace and request tabs

- New and opened requests appear in the top tab bar, ordered from left to right.
- Double-click a request name to rename it inline. Enter or blur confirms; Esc cancels.
- Right-click a request tab to close the current tab, close all tabs, or create a request.
- Closing a tab that is sending or connected attempts to cancel the active operation.
- When Restore workspace is enabled, request tabs and local state return after restart.

## 3. Collections, folders, and environments

Collections are top-level API groups, and folders can be nested. A collection or folder three-dot menu can:

- Create HTTP, WS, or SSE requests
- Create a child folder
- Edit scoped variables
- Run the current collection or folder
- Rename or delete the node

A request menu can rename, duplicate, or delete it. Destructive actions require confirmation.

The title-bar environment switcher selects the active environment. Development, Staging, and Production are protected defaults. Create custom environments from the Environment page. Environment variables form the base variable layer.

## 4. HTTP requests

### URL and parameters

Choose GET, POST, PUT, PATCH, DELETE, HEAD, or OPTIONS. Only enabled Params rows enter the query string. Type `h` and press Tab to complete `http://`, or type `hs` and press Tab to complete `https://`.

### Headers and authentication

Headers support variables and enabled states. Authentication supports:

- Bearer Token
- Basic username and password
- API Key in a Header or Query parameter

Literal credentials are masked after editing. `{{variable}}` expressions stay visible for inspection and completion.

### Request bodies

- JSON: highlighting, quote and bracket pairing, smart indentation, colon spacing, undo/redo, and variable completion.
- Text: raw text content.
- Form: URL-encoded key-value pairs.
- Multipart: text fields and local files.
- Binary: one local binary file.

### Request settings

Each request can configure timeout, redirects, SSL verification, and the cookie jar. Disabling SSL verification reduces security and should be limited to explicit local debugging needs.

## 5. Inspect responses

- Body: JSON Pretty/Raw, highlighting, caret selection, search, copy, and download.
- Headers: response headers.
- Cookies: response cookies.
- Scripts: Pre-request and Post-response output.
- Tests: expected, actual, and result for each declarative test.
- Timeline: DNS, connection, TLS, send, TTFB, download, and total duration.

Images can be previewed directly and videos can be played. Other binary responses can be saved as original files. Large text responses use a safe preview while downloads retain the original content.

On failure, the error view shows the summary, likely cause, suggested checks, stage, host, timeout, TLS and redirect settings, system code, and technical details. Copy diagnostics when investigating or sharing an issue.

## 6. Variables

Reference variables with:

```text
{{BASE_URL}}/users/{{USER_ID}}
```

Priority is:

```text
Runner data row > Nearest folder > Parent folder > Collection > Active environment
```

For HTTP, inspect final values under Settings → Effective variables. For WS and SSE, use the Variables tab. Every value shows its source, override chain, and direct edit action. Missing references appear before sending and can open the nearest configuration scope.

See the full [Variables guide](variables.en.md) for matching, Secret, export, and troubleshooting rules.

## 7. Pre-request and Post-response Scripts

A Pre-request script can adjust the current send through guarded APIs:

```javascript
nimbo.request.headers.set('X-Trace-Id', nimbo.environment.get('traceId'));
nimbo.request.url = `${nimbo.request.url}?source=nimbo`;
```

A Post-response script reads an immutable response and may write explicitly to the active environment:

```javascript
const payload = JSON.parse(nimbo.response.body);
nimbo.environment.set('responseId', payload.id);
console.log(nimbo.response.statusCode, payload.id);
```

Execution order is fixed:

```text
Pre-request → effective variables → HTTP → Post-response → JSONPath extraction → Tests
```

A failed Pre-request script blocks the send. Every script uses a fresh local sandbox with time, memory, stack, source, concurrency, and console-output limits. Remote modules, third-party packages, and the full Postman `pm.*` API are unavailable.

See the complete [Scripts guide](scripts.en.md) for APIs, syntax, examples, and limits.

## 8. JSONPath extraction and Tests

An extraction rule previews its path against the latest JSON response before you choose an explicit target environment. Configure Secret and overwrite behavior deliberately. Invalid JSON, invalid paths, no match, missing targets, and conflicts are reported separately.

Declarative Tests support:

- Status code equals
- Response time less than
- Header exists or equals
- JSONPath exists or equals

Tests do not execute arbitrary code and never mutate the request or environment.

## 9. Collection Runner

Select the run icon beside a collection or folder:

1. Choose an environment and iteration count.
2. Optionally select a local CSV or JSON data file.
3. Review the request count and start.
4. Inspect status, status code, duration, and test totals for every request iteration.
5. Filter or export the report.

CSV requires a unique, non-empty header row and supports quoted fields, escaped quotes, and embedded newlines. JSON must be a non-empty array of flat objects with string, number, boolean, or null values.

Limits: 2 MB, 1000 rows, and 100 columns. Requests run sequentially, not concurrently. WS and SSE requests are skipped. Stop prevents new requests from starting and cancels the active request where possible. Reports never include data-row contents or secret values.

## 10. WebSocket

1. Create a WS request and choose WS or WSS.
2. Enter the URL and configure Headers and authentication.
3. Connect and inspect status and connection records.
4. Enter text and press Enter or Ctrl+Enter to send; use Shift+Enter for a new line, or select the integrated send icon. Search, copy, clear, or export the timeline. Valid JSON messages are formatted and highlighted automatically.
5. Disconnect explicitly when finished.

The URL, headers, authentication, and text messages support variables. Binary messages, automatic reconnect, Socket.IO, and GraphQL Subscription are not currently supported.

## 11. Server-Sent Events

1. Create an SSE request and choose an HTTP method.
2. Enter an HTTP/HTTPS URL and configure Headers, authentication, and a JSON or text Body when required by a POST streaming API.
3. Connect and inspect the HTTP status and Content-Type.
4. Search, copy, clear, or export received events. Valid JSON `data` is formatted and highlighted automatically, while plain text remains unchanged.
5. Stop explicitly to end a continuous stream.

The parser supports CRLF, events split across chunks, comments, default `message`, custom `event`, multiline `data`, `id`, and `retry`. Event bodies stay only in the current tab memory.

## 12. Import and export

### cURL

Open Import → cURL in the title bar, paste a command, and review the highlighted input. Supported methods, URLs, headers, authentication, and bodies become a new request.

### API files

Choose or drop a JSON file. Automatic detection supports:

- Postman Collection
- Postman Environment
- OpenAPI 3.0 / 3.1 JSON
- Swagger 2.0 JSON

Postman root variables become collection variables. OpenAPI tags become folders, with supported servers, parameters, security, and stable body examples mapped into requests. OpenAPI YAML is not currently accepted.

Import is atomic: required structural errors do not alter existing data, and skipped optional features are reported as warnings.

### Nimbo backups

Export local backups from Settings. A normal export recursively redacts Secret values. Exporting with secrets requires explicit confirmation. Never commit credential-bearing files to Git.

## 13. Search and keyboard shortcuts

- `Ctrl+K`: search requests, collections, history, environments, and commands.
- `Ctrl+Enter`: send the active HTTP request.
- `Ctrl+S`: save or update the active request.
- `Ctrl+A`: select all in an editor.
- `Ctrl+Z`: undo.
- `Ctrl+Shift+Z` / `Ctrl+Y`: redo.
- `Tab` / `Shift+Tab`: indent or outdent; Tab accepts an open suggestion.
- Arrow keys: select variable or script suggestions.
- `Enter`: accept a suggestion.
- `Esc`: close transient search or suggestion UI.

## 14. Troubleshooting

### A variable exists but is reported missing

Check exact casing, enabled state, and a non-empty value, then inspect the source and override chain in Effective variables. Runner data may override the value only during its iteration.

### DNS, connection, TLS, or timeout failure

Copy diagnostics first. Use the recorded stage to check protocol, host, port, service binding, VPN or proxy, certificate chain, system clock, SSL settings, redirects, and timeout.

### Import fails

Confirm the input is a complete cURL command or valid JSON and read the preview warnings. Convert OpenAPI YAML to JSON before importing.

### Workspace or history is not restored

Check Restore workspace, Save history, and the retention period in Settings. WebSocket messages, SSE event bodies, and connection records are intentionally memory-only.

### Restore safe defaults

Reset in Settings removes local application data and restores safe defaults. Export a redacted backup first.
