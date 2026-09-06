#!/usr/bin/env bash
#
# Verify that every url "..." in Formula/*.rb is actually downloadable.
#
# This tap ships prebuilt bottles: Homebrew has no compile fallback, so a URL
# that 404s is a hard install failure for the user. Nothing else in the repo
# checked the URLs, which is how ged's bottles stayed broken for six months.
#
# Usage:
#   scripts/check-formula-urls.sh                    # HEAD every URL, expect 200
#   scripts/check-formula-urls.sh --sha              # also verify the sha256
#   scripts/check-formula-urls.sh Formula/cv.rb ...  # limit to given formulae
#
# Exits non-zero if any URL fails to resolve (or, with --sha, mismatches).

set -euo pipefail

readonly OK_STATUS=200
readonly CONNECT_TIMEOUT_SECS=10
readonly MAX_TIME_SECS=120

check_sha=0
formulae=()
for arg in "$@"; do
  case "${arg}" in
    --sha) check_sha=1 ;;
    -*)
      echo "unknown option: ${arg}" >&2
      exit 2
      ;;
    *) formulae+=("${arg}") ;;
  esac
done

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${repo_root}"

if [[ ${#formulae[@]} -eq 0 ]]; then
  for f in Formula/*.rb; do formulae+=("${f}"); done
fi

# sha256sum is GNU-only; macOS ships shasum.
if command -v sha256sum > /dev/null 2>&1; then
  sha256_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum > /dev/null 2>&1; then
  sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
  echo "neither sha256sum nor shasum found" >&2
  exit 2
fi

payload=""
pairs="$(mktemp)"
trap 'rm -f "${pairs}" "${payload}"' EXIT
awk -f "${repo_root}/scripts/formula-urls.awk" "${formulae[@]}" > "${pairs}"

total=0
failed=0

while IFS="$(printf '\t')" read -r file lineno url sha; do
  total=$((total + 1))
  status="$(curl -sIL -o /dev/null -w '%{http_code}' \
    --connect-timeout "${CONNECT_TIMEOUT_SECS}" --max-time "${MAX_TIME_SECS}" \
    "${url}" || echo 000)"
  if [[ "${status}" != "${OK_STATUS}" ]]; then
    printf 'FAIL  %s:%s  HTTP %s  %s\n' "${file}" "${lineno}" "${status}" "${url}"
    failed=$((failed + 1))
    continue
  fi
  if [[ ${check_sha} -eq 1 && "${sha}" != "-" ]]; then
    payload="$(mktemp)"
    curl -sL --connect-timeout "${CONNECT_TIMEOUT_SECS}" \
      --max-time "${MAX_TIME_SECS}" -o "${payload}" "${url}"
    got="$(sha256_of "${payload}")"
    rm -f "${payload}"
    payload=""
    if [[ "${got}" != "${sha}" ]]; then
      printf 'FAIL  %s:%s  sha256 %s != declared %s  %s\n' \
        "${file}" "${lineno}" "${got}" "${sha}" "${url}"
      failed=$((failed + 1))
      continue
    fi
    printf 'ok    %s:%s  HTTP %s sha256 ok  %s\n' \
      "${file}" "${lineno}" "${status}" "${url}"
    continue
  fi
  printf 'ok    %s:%s  HTTP %s  %s\n' "${file}" "${lineno}" "${status}" "${url}"
done < "${pairs}"

printf '\n%d URL(s) checked, %d failed\n' "${total}" "${failed}"
[[ ${failed} -eq 0 ]]
