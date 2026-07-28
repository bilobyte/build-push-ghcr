#!/usr/bin/env bash

set -u

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RESOLVER="${TEST_ROOT}/src/resolve-image.sh"
readonly REFERENCE_WRITER="${TEST_ROOT}/src/write-reference.sh"
readonly TEST_SHA="0123456789abcdef0123456789abcdef01234567"
readonly TEST_DIGEST="sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok - %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'not ok - %s\n' "$1"
}

run_resolver() {
  local output_file="$1"
  shift

  env -i \
    PATH="$PATH" \
    GITHUB_OUTPUT="$output_file" \
    GITHUB_SHA="$TEST_SHA" \
    "$@" \
    bash "$RESOLVER"
}

assert_resolver_success() {
  local description="$1"
  local expected_repository="$2"
  shift 2

  local github_output
  local log_output
  local status

  github_output="$(mktemp)"
  log_output="$(mktemp)"

  run_resolver "$github_output" "$@" >"$log_output" 2>&1
  status=$?

  if [[ "$status" -eq 0 ]] &&
    grep -Fqx "repository=${expected_repository}" "$github_output" &&
    grep -Fqx "sha-tag=${expected_repository}:sha-${TEST_SHA}" "$github_output"; then
    pass "$description"
  else
    fail "$description"
    sed 's/^/  /' "$log_output"
    sed 's/^/  /' "$github_output"
  fi

  rm -f "$github_output" "$log_output"
}

assert_resolver_failure() {
  local description="$1"
  shift

  local github_output
  local log_output
  local status

  github_output="$(mktemp)"
  log_output="$(mktemp)"

  run_resolver "$github_output" "$@" >"$log_output" 2>&1
  status=$?

  if [[ "$status" -eq 2 ]]; then
    pass "$description"
  else
    fail "$description"
    printf '  expected status 2, got %d\n' "$status"
    sed 's/^/  /' "$log_output"
  fi

  rm -f "$github_output" "$log_output"
}

assert_reference_writer() {
  local github_output
  local log_output
  local status

  github_output="$(mktemp)"
  log_output="$(mktemp)"

  env -i \
    PATH="$PATH" \
    GITHUB_OUTPUT="$github_output" \
    BUILD_PUSH_GHCR_REPOSITORY="ghcr.io/bilobyte/example" \
    BUILD_PUSH_GHCR_DIGEST="$TEST_DIGEST" \
    bash "$REFERENCE_WRITER" >"$log_output" 2>&1
  status=$?

  if [[ "$status" -eq 0 ]] &&
    grep -Fqx "image=ghcr.io/bilobyte/example@${TEST_DIGEST}" "$github_output"; then
    pass "creates an immutable digest reference"
  else
    fail "creates an immutable digest reference"
    sed 's/^/  /' "$log_output"
    sed 's/^/  /' "$github_output"
  fi

  rm -f "$github_output" "$log_output"
}

assert_resolver_success \
  "derives the repository from GitHub context" \
  "ghcr.io/bilobyte/example" \
  GITHUB_REPOSITORY="BiloByte/Example"

assert_resolver_success \
  "normalizes an explicit repository" \
  "ghcr.io/bilobyte/custom-image" \
  BUILD_PUSH_GHCR_IMAGE="GHCR.IO/BiloByte/Custom-Image"

assert_resolver_failure \
  "rejects another registry" \
  BUILD_PUSH_GHCR_IMAGE="docker.io/bilobyte/example"

assert_resolver_failure \
  "rejects a tagged image" \
  BUILD_PUSH_GHCR_IMAGE="ghcr.io/bilobyte/example:latest"

assert_resolver_failure \
  "rejects a digest reference" \
  BUILD_PUSH_GHCR_IMAGE="ghcr.io/bilobyte/example@${TEST_DIGEST}"

assert_resolver_failure \
  "rejects a URL" \
  BUILD_PUSH_GHCR_IMAGE="https://ghcr.io/bilobyte/example"

assert_reference_writer

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
