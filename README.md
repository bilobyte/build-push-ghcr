# build-push-ghcr

A composite GitHub Action that builds a Docker image, publishes branch and
full-commit tags to GitHub Container Registry, and returns an immutable digest
reference for deployment.

## Usage

The caller must check out the repository and grant `packages: write`.

```yaml
permissions:
  contents: read
  packages: write

steps:
  - uses: actions/checkout@v6

  - name: Build and push image
    id: image
    uses: bilobyte/build-push-ghcr@v1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}

  - name: Use immutable image
    env:
      IMAGE: ${{ steps.image.outputs.image }}
    run: echo "$IMAGE"
```

By default, the action publishes to the lowercase form of
`ghcr.io/<owner>/<repository>`. Use the `image` input to select another
untagged repository under `ghcr.io`.

Never place credentials in `build-args`. Stage sensitive values as files with
restrictive permissions and pass them through `secret-files`.

## Inputs

| Input | Required | Default | Purpose |
| --- | --- | --- | --- |
| `token` | Yes | | Token with `packages: write` |
| `context` | No | `.` | Docker build context |
| `file` | No | Context Dockerfile | Dockerfile path |
| `image` | No | Current GitHub repository | Untagged GHCR repository |
| `platforms` | No | Runner platform | Comma-separated platforms |
| `build-args` | No | | Newline-separated build arguments |
| `secret-files` | No | | Newline-separated BuildKit secret file mappings |

## Outputs

| Output | Purpose |
| --- | --- |
| `repository` | Normalized untagged GHCR repository |
| `digest` | Published image digest |
| `image` | Immutable `repository@digest` reference |
| `sha-tag` | Compatible `repository:sha-<commit>` reference |

## Development

Run the dependency-free contract tests:

```bash
./tests/test.sh
```

The hosted smoke test publishes a minimal fixture image on pushes to `main`.
The action owns Docker setup, GHCR authentication, metadata, and build caching.
Callers own checkout and any temporary secret files they create.
