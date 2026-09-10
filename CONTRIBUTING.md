# Contributing to Nimbo

Thank you for helping improve Nimbo. Contributions should keep the application focused, native, local-first, and buildable on HarmonyOS.

## Before you start

- Search existing issues before opening a new one.
- Open an issue before starting a large feature or architectural change.
- Read [`CODEX_HANDOFF.md`](docs/nimbo-dev-package/CODEX_HANDOFF.md) for the current scope and deferred capabilities.
- Do not add UI for unfinished features.

## Development setup

1. Fork and clone the repository.
2. Copy `build-profile.example.json5` to `build-profile.json5`.
3. Open the project in DevEco Studio and configure your own signing identity.
4. Run `./scripts/quality-check.sh --build` before submitting a pull request.

Never commit signing profiles, certificates, keystores, passwords, tokens, exported backups, or personal request data.

## Pull requests

- Keep each pull request focused on one coherent change.
- Explain the problem, the chosen solution, and how the change was tested.
- Include screenshots or a short recording for visible UI changes.
- Update both English and Simplified Chinese resources when adding user-facing text.
- Update the handoff document when completing or changing a milestone.
- Use clear commit messages, preferably in the Conventional Commits form, such as `fix: refresh nested collection nodes`.

All pull request checks must pass. A HarmonyOS build must also pass locally when the change touches application code.

## Contributor License Agreement

All contributors must accept the [Nimbo Contributor License Agreement](CLA.md). Add the following checkbox to your pull request description:

```text
- [x] I have read and agree to the Nimbo Contributor License Agreement.
```

The CLA does not transfer ownership of your contribution. It grants the project maintainer the rights needed to distribute Nimbo under its open-source license and, if required in the future, under additional commercial terms.

## Reporting security issues

Do not open a public issue for a suspected vulnerability. Follow the private reporting process in [`SECURITY.md`](SECURITY.md).
