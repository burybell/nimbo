# Nimbo Scripts Guide

English · [简体中文](scripts.zh-CN.md)

Nimbo provides Pre-request and Post-response JavaScript stages. Scripts run in a restricted local sandbox and are intended for adjusting a send, reading a response, logging diagnostics, and publishing values to the active environment.

## 1. Open the editor

Open an HTTP request and select Pre-request Script or Post-response Script in the request configuration area. Enable the stage and enter code. Type `nimbo.`, `nimbo.request.`, or `nimbo.response.` for API suggestions. Use Arrow keys to choose, Enter or Tab to complete, and Esc to close the list.

Common JavaScript syntax is available: `const`, `let`, strings, numbers, booleans, arrays, objects, conditions, loops, functions, template literals, `JSON.parse`, `JSON.stringify`, and `throw`.

## 2. Execution order

```text
Pre-request → apply environment writes → resolve effective variables → HTTP
            → Post-response → apply environment writes → JSONPath extraction → Tests
```

- A failed Pre-request script blocks the network request.
- A failed Post-response script preserves the received response; extraction and Tests continue.
- Environment writes are atomic for one script run. If the script ultimately fails, none of its writes apply.
- `nimbo.request` changes affect only this send and never silently overwrite the saved collection request.

## 3. Pre-request API

| API | Type | Behavior |
| --- | --- | --- |
| `nimbo.request.method` | string | Read/write HTTP method; writes are uppercased and must be supported |
| `nimbo.request.url` | string | Read/write URL for this send |
| `nimbo.request.body` | string | Read/write body; assigning while type is `none` switches it to `text` |
| `nimbo.request.bodyType` | string | Read/write body type |
| `nimbo.request.headers.get(name)` | function | Case-insensitive lookup; missing values return `undefined` |
| `nimbo.request.headers.set(name, value)` | function | Add or replace a header; values become strings |
| `nimbo.request.headers.remove(name)` | function | Case-insensitive removal |

Add authentication and tracing:

```javascript
const token = nimbo.environment.get('ACCESS_TOKEN');
if (!token) throw new Error('ACCESS_TOKEN is required');

nimbo.request.headers.set('Authorization', 'Bearer ' + token);
nimbo.request.headers.set('X-Trace-Id', 'nimbo-' + Date.now());
```

Modify a JSON body:

```javascript
const payload = JSON.parse(nimbo.request.body);
payload.source = 'nimbo';
payload.sentAt = new Date().toISOString();
nimbo.request.bodyType = 'json';
nimbo.request.body = JSON.stringify(payload);
```

## 4. Post-response API

The response snapshot is read-only:

| API | Type | Behavior |
| --- | --- | --- |
| `nimbo.response.statusCode` | number | HTTP status code |
| `nimbo.response.statusText` | string | Status text |
| `nimbo.response.body` | string | Raw text body; parse JSON explicitly |
| `nimbo.response.contentType` | string | Content-Type |
| `nimbo.response.size` | string | Display response size |
| `nimbo.response.duration` | string | Display total duration |
| `nimbo.response.protocol` | string | HTTP protocol version |
| `nimbo.response.headers.get(name)` | function | Case-insensitive header lookup |

Save an ID on success:

```javascript
if (nimbo.response.statusCode >= 200 && nimbo.response.statusCode < 300) {
  const payload = JSON.parse(nimbo.response.body);
  nimbo.environment.set('LAST_RESPONSE_ID', payload.id);
}
```

Read a response header and log diagnostics:

```javascript
const requestId = nimbo.response.headers.get('x-request-id');
console.log('status', nimbo.response.statusCode);
console.log('request-id', requestId);
```

## 5. Environment API

Both stages support:

- `nimbo.environment.get(name)` reads the selected environment and returns `undefined` when missing.
- `nimbo.environment.set(name, value)` writes a string to the selected environment.

`set` requires a selected environment and a non-empty key. Scripts cannot directly modify collection, folder, or Runner variables. A higher-priority value can still override the newly written environment value; inspect Effective variables to see the source chain.

## 6. Console and results

`console.log`, `console.info`, `console.warn`, and `console.error` append ordered lines to the response Scripts tab. Multiple arguments are joined with spaces. Logging is diagnostic and does not alter script success. Never log tokens, passwords, cookies, or complete Authorization headers.

The Scripts tab also reports the stage, duration, success, error, timeout, or memory limit, plus the error stack.

## 7. Limits and unavailable features

- Default execution timeout: 500 ms
- Default memory: 8 MB
- Stack: 512 KB
- Source: 1 MB
- Concurrent scripts: at most 2
- Console: at most 200 lines or 64 KB
- Every execution has a fresh context; globals do not persist
- No file access, extra network requests, remote modules, or third-party packages
- No full Postman `pm.*` API; use `nimbo.*`

Prefer declarative JSONPath when you only need a response value. Prefer Tests for status, duration, header, or JSON assertions. Use scripts for conditional, composed, or dynamic behavior.

## 8. Troubleshooting

### `environment.set` throws

Select an environment in the title bar and use a non-empty key. Writes are discarded if the script fails.

### JSON parsing fails

`body` is always a string. Confirm the content is JSON before calling `JSON.parse`; use `try/catch` for optional diagnostic parsing.

### The sent request changed but the saved request did not

This is intentional. A Pre-request script changes only the current send snapshot. Edit the request and press `Ctrl+S` for a permanent change.

### The environment value was written but is not effective

Open Effective variables and check whether a Runner, folder, or collection variable with higher priority overrides the same name.
