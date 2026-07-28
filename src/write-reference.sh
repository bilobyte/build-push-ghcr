#!/usr/bin/env bash

set -Eeuo pipefail

repository="${BUILD_PUSH_GHCR_REPOSITORY:-}"
digest="${BUILD_PUSH_GHCR_DIGEST:-}"

if [[ -z "$repository" || -z "$digest" ]]; then
  printf '%s\n' \
    "::error title=Cannot create immutable image reference::The build did not return a repository and digest."
  exit 1
fi

if [[ ! "$digest" =~ ^sha256:[a-f0-9]{64}$ ]]; then
  printf '%s\n' \
    "::error title=Invalid image digest::The Docker build returned an unexpected digest."
  exit 1
fi

printf 'image=%s@%s\n' "$repository" "$digest" >> "$GITHUB_OUTPUT"
printf 'Published immutable image: %s@%s\n' "$repository" "$digest"
