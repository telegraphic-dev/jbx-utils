# jbx-utils

Sidecar Java utilities used by `jbx` commands. Each helper is a separate Maven artifact so consumers only download the dependencies they actually need.

## Artifacts

```text
dev.telegraphic.jbx:jbx-check:<version>
dev.telegraphic.jbx:jbx-graph:<version>
```

- `jbx-check` contains `dev.telegraphic.jbx.check.JbxCheckCompiler`, a dependency-free Compiler API wrapper used by `jbx check`.
- `jbx-graph` contains `dev.telegraphic.jbx.graph.JbxGraph`, a JavaParser native JSON dump/import helper used by `jbx graph`.

## Local verification

```bash
scripts/smoke-check.sh
scripts/verify-publish-bundle.sh
```

`verify-publish-bundle.sh` uses `jbx publish --dry-run --skip-signing` for both projects, checks the Maven Central bundle layout, and verifies each jar contains only its own helper class.

## Publishing

Publishing is handled by `.github/workflows/publish.yml` on a GitHub release or manual workflow dispatch. The workflow imports the signing key, builds and publishes both artifacts with `jbx publish --publish`, uploads them to Maven Central, and waits for publication.

Required GitHub secrets:

- `CENTRAL_TOKEN_USERNAME`
- `CENTRAL_TOKEN_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`
