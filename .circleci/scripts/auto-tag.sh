#!/bin/bash
# Creates the release tag (vX.Y.Z) automatically on main, based on the latest
# entry of CHANGELOG.md. Pushing the tag triggers a new pipeline where
# .circleci/test-deploy.yml publishes the orb in production (pub-type: production).
#
# Rules:
#   - Version = first "## `[X.Y.Z ...]`" heading in CHANGELOG.md
#   - Tag already exists      -> skip (exit 0). E.g. docs/CI-only merges without bump
#   - Version <= latest tag   -> fail (forgotten or wrong bump)
#   - Examples not bumped     -> fail (src/examples must reference the new version)
set -eo pipefail

if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "Missing GITHUB_TOKEN environment (expected in the DEFAULT context)"
  exit 1
fi

VERSION=$(grep -m1 -oE '^## `\[[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
if [[ -z "${VERSION}" ]]; then
  echo "Could not find a version in CHANGELOG.md (expected a heading like: ## \`[1.2.3 YYYY-MM-DD]\`)"
  exit 1
fi
TAG="v${VERSION}"
echo "CHANGELOG version: ${VERSION} (tag ${TAG})"

if git ls-remote --exit-code --tags origin "refs/tags/${TAG}" >/dev/null 2>&1; then
  echo "Tag ${TAG} already exists. Nothing to release (did you forget to bump CHANGELOG.md?)."
  exit 0
fi

LATEST_TAG=$(git ls-remote --tags --refs origin 'v*' | awk -F/ '{print $3}' |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)
echo "Latest existing tag: ${LATEST_TAG:-none}"
if [[ -n "${LATEST_TAG}" ]] && [[ "$(printf '%s\n%s\n' "${LATEST_TAG}" "${TAG}" | sort -V | tail -1)" != "${TAG}" ]]; then
  echo "Version ${TAG} is lower than the latest tag ${LATEST_TAG}. Fix the CHANGELOG.md version."
  exit 1
fi

OUTDATED=$(grep -rnoE 'orb-standard-pipeline@[0-9]+\.[0-9]+\.[0-9]+' src/examples | grep -v "@${VERSION}$" || true)
if [[ -n "${OUTDATED}" ]]; then
  echo "The following examples do not reference version ${VERSION}:"
  echo "${OUTDATED}"
  exit 1
fi

git -c user.name="${GITHUB_USER_NAME:-circleci}" \
  -c user.email="${GITHUB_USER_EMAIL:-circleci@users.noreply.github.com}" \
  tag -a "${TAG}" -m "Release ${TAG}" "${CIRCLE_SHA1}"

git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git" "refs/tags/${TAG}"
echo "Tag ${TAG} pushed. A new pipeline will publish dafiti-group/orb-standard-pipeline@${VERSION}."
