# jbx-utils

Sidecar Java utilities used by `jbx` commands.

The artifact is published to Maven Central as:

```text
dev.telegraphic.jbx:jbx-utils:<version>
```

Included utilities:

- `dev.telegraphic.jbx.check.JbxCheckCompiler` — Compiler API wrapper used by `jbx check`.
- `dev.telegraphic.jbx.graph.JbxGraph` — JavaParser native JSON dump/import helper used by `jbx graph`.

## Local verification

```bash
scripts/smoke-check.sh
scripts/verify-publish-bundle.sh
```

`verify-publish-bundle.sh` uses `jbx publish --dry-run --skip-signing`, checks the Maven Central bundle layout, and verifies both utility classes are packaged in the jar.

## Publishing

Publishing is handled by `.github/workflows/publish.yml` on a GitHub release or manual workflow dispatch. The workflow imports the signing key, builds the bundle with `jbx publish --publish`, uploads it to Maven Central, and waits for publication.

Required GitHub secrets:

- `CENTRAL_TOKEN_USERNAME`
- `CENTRAL_TOKEN_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`
