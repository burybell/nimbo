# QuickJS-NG

This directory contains the minimal source set required to embed QuickJS-NG in Nimbo.

- Upstream: <https://github.com/quickjs-ng/quickjs>
- Version: `v0.16.2`
- Commit: `1ab8676f4b6d6d669baeb5f21790fb9734636a20`
- License: MIT; see `LICENSE`

Nimbo links the engine statically into its private native script bridge. The QuickJS standard library and CLI are intentionally excluded so scripts do not receive filesystem, process, module-loading, or network APIs.
