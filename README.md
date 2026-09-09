# Nimbo

Nimbo is a native HarmonyOS API debugging client. The current implementation contains Milestone 0 (project foundation) and Milestone 1 (application shell) only.

## Huawei application identity

- Bundle name: `com.nimbo.app`
- App ID: `6917615930484878194`

The App ID belongs to the AppGallery Connect application/signing profile. The runtime bundle name is declared in `AppScope/app.json5`; no credential or signing material is committed to this repository.

## Build

Open the repository root in DevEco Studio, select a locally installed HarmonyOS 6.1.1 (API 24) SDK, configure signing for the application above, and run the `entry` module.

Command-line build with the SDK bundled in DevEco Studio:

```shell
./build_hap.sh
```

Without a signing profile this produces `entry/build/default/outputs/default/entry-default-unsigned.hap`. Configure the matching AppGallery Connect signing profile in DevEco Studio before installing it on a device.

See `docs/nimbo-dev-package/CODEX_HANDOFF.md` for the authoritative delivery scope.
