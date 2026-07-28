#!/usr/bin/env bash

set -Eeuo pipefail

image="${BUILD_PUSH_GHCR_IMAGE:-}"

if [[ -z "$image" ]]; then
  if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
    printf '%s\n' \
      "::error title=Cannot resolve image repository::GITHUB_REPOSITORY is unavailable and the image input is empty."
    exit 2
  fi

  image="ghcr.io/${GITHUB_REPOSITORY}"
fi

if [[ "$image" =~ [[:space:]] ]] || [[ "$image" == *"://"* ]]; then
  printf '%s\n' \
    "::error title=Invalid GHCR image::Use an untagged repository such as ghcr.io/owner/image."
  exit 2
fi

repository="$(printf '%s' "$image" | tr '[:upper:]' '[:lower:]')"
last_segment="${repository##*/}"

if [[ "$repository" != ghcr.io/* ]] ||
  [[ "$repository" == *@* ]] ||
  [[ "$last_segment" == *:* ]] ||
  [[ ! "$repository" =~ ^ghcr\.io/[a-z0-9][a-z0-9._-]*(/[a-z0-9][a-z0-9._-]*)+$ ]]; then
  printf '%s\n' \
    "::error title=Invalid GHCR image::Use an untagged repository such as ghcr.io/owner/image."
  exit 2
fi

if [[ -z "${GITHUB_SHA:-}" ]]; then
  printf '%s\n' "::error title=Cannot resolve SHA tag::GITHUB_SHA is unavailable."
  exit 2
fi

sha_tag="${repository}:sha-${GITHUB_SHA}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    printf 'repository=%s\n' "$repository"
    printf 'sha-tag=%s\n' "$sha_tag"
  } >> "$GITHUB_OUTPUT"
fi

printf 'Resolved image repository: %s\n' "$repository"
