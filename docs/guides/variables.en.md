# Nimbo Variables Guide

English · [简体中文](variables.zh-CN.md)

Nimbo variables let requests reuse service addresses, identifiers, and other data. Resolution happens locally. Before a request is sent, each `{{variable}}` reference is replaced with its final effective value.

## Create variables

- Environment variables: open Environments and edit the active environment. Use them for development, staging, production, and other global configuration.
- Collection variables: open a collection's three-dot menu and choose Variables. Use them for values shared by one API collection.
- Folder variables: open a folder's three-dot menu and choose Variables. Use them to override collection defaults for one module.
- Runner data: select a CSV or JSON file when running a collection. Each row becomes a temporary variable layer for one iteration.

Each variable has an enabled state, key, value, Secret flag, and description. A disabled variable, empty key, or empty final value does not satisfy a request reference.

## Priority

When the same key exists in multiple scopes, the source closest to the request wins:

```text
Runner data row
  > Nearest folder
  > Parent folder
  > Collection
  > Active environment
```

For example, a collection `BASE_URL` overrides the environment value. If the request is inside a child folder that also defines `BASE_URL`, the child folder wins. Runner data applies only to its iteration and is never written back to a persistent scope.

## Use variables in requests

Reference a variable with double braces:

```text
{{BASE_URL}}/users/{{USER_ID}}
```

Supported locations include:

- URLs and query parameters
- Request headers
- Bearer, Basic, and API Key authentication
- JSON, text, form, and multipart text fields
- WebSocket URLs and text messages
- SSE URLs, headers, and authentication
- Environment reads in Pre-request and Post-response Scripts
- Collection Runner request execution

Type `{{` in a supported editor to open suggestions. Use the arrow keys to select a candidate and Enter or Tab to accept it.

## Inspect final values

- HTTP: open the request Settings tab and scroll to Effective variables.
- WebSocket / SSE: open the Variables tab.

Each row shows the final value, source type, source name, and overridden scopes. Select Edit to open the environment, collection, or folder that currently provides the value.

References without an enabled non-empty value appear in Missing values before a send. Configure variables opens the nearest collection or folder; for an unsaved request it opens the active environment.

## Secrets and exports

Mark tokens, passwords, cookies, and other credentials as Secret. The effective-variable view also masks common Authorization, Password, Secret, Token, API Key, Access Key, Private Key, Credential, and Cookie key names automatically.

A normal Nimbo export recursively removes Secret values from environments, collections, and folders. Only the explicit export-with-secrets flow keeps them. Never commit real credentials to Git or distribute them in public examples.

## Troubleshooting

### A variable exists but is still reported missing

Confirm that it is enabled, the key matches exactly, and its value is not empty. Variable names are case-sensitive.

### The active environment value is not used

Inspect the source and override chain in Effective variables. A collection or folder value with the same key may override the environment.

### Runner variables disappear after a run

A Runner data row is a temporary highest-priority input for one iteration. Store long-lived values in an environment, collection, or folder.

### Do script writes modify collection variables?

No. `nimbo.environment.set` and JSONPath extraction write only to an explicitly selected environment. They never modify collection or folder variables implicitly.

