# jbx-check

Compiler API wrapper used by `jbx check`.

The artifact is published to Maven Central as:

```text
dev.telegraphic.jbx:jbx-check:<version>
```

## Local verification

```bash
scripts/smoke-check.sh
scripts/verify-publish-bundle.sh
```

`verify-publish-bundle.sh` uses `jbx publish --dry-run --skip-signing` and checks the Maven Central bundle layout.

## Publishing

Publishing is handled by `.github/workflows/publish.yml` on a GitHub release or manual workflow dispatch. The workflow imports the signing key, builds the bundle with `jbx publish --publish`, uploads it to Maven Central, and waits for publication.
