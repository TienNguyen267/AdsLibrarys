#!/bin/bash
# Publishes build/binary-dist to the public AdmobLibraryBinary repo.
# Source files are never copied. Requires a GitHub token with repo scope,
# either GH_TOKEN or the macOS git credential for github.com.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_OWNER="TienNguyen267"
DIST_NAME="AdmobLibraryBinary"
DIST_REPO="${DIST_OWNER}/${DIST_NAME}"

"$ROOT/Scripts/package-binary.sh"

STAGE="$ROOT/build/binary-dist"
VERSION="$(awk -F"'" '/^[[:space:]]*s\.version[[:space:]]*=/{print $2; exit}' "$ROOT/AdmobLibrary.podspec")"

if [[ -z "${GH_TOKEN:-}" ]]; then
  GH_TOKEN="$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | awk -F= '/^password=/{print $2}')"
fi
if [[ -z "$GH_TOKEN" ]]; then
  echo "No GitHub token. Set GH_TOKEN or sign in to github.com with git." >&2
  exit 1
fi

api() {
  curl -sS -H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json" "$@"
}

repo_status="$(curl -sS -o /tmp/admob-binary-repo.json -w "%{http_code}" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${DIST_REPO}")"

if [[ "$repo_status" == "404" ]]; then
  echo "Creating public repo ${DIST_REPO}..."
  api -X POST "https://api.github.com/user/repos" \
    -d "{\"name\":\"${DIST_NAME}\",\"private\":false,\"description\":\"Public binary distribution for AdmobLibrary. Swift source is not included.\",\"has_issues\":false,\"has_wiki\":false,\"auto_init\":false}" \
    > /tmp/admob-binary-create.json
  python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("/tmp/admob-binary-create.json").read_text())
if "full_name" not in data:
    message = data.get("message", "unknown error")
    errors = data.get("errors")
    raise SystemExit(f"Could not create repository: {message} {errors or ''}")
print("Created", data["full_name"])
PY
elif [[ "$repo_status" != "200" ]]; then
  echo "Could not read ${DIST_REPO} (HTTP ${repo_status})." >&2
  exit 1
else
  python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("/tmp/admob-binary-repo.json").read_text())
if data.get("private"):
    raise SystemExit("Refusing to publish: destination repo is private.")
print("Destination repo is public:", data["full_name"])
PY
fi

if git ls-remote --tags "https://github.com/${DIST_REPO}.git" | awk '{print $2}' | grep -qx "refs/tags/${VERSION}"; then
  echo "Tag ${VERSION} already exists on ${DIST_REPO}. Bump s.version before publishing again." >&2
  exit 1
fi

cd "$STAGE"
rm -rf .git
git init -b main
git add -A
git commit -m "Release AdmobLibrary ${VERSION} binary."
git remote add origin "https://github.com/${DIST_REPO}.git"
git tag -a "$VERSION" -m "AdmobLibrary ${VERSION}"
git push -u origin main
git push origin "$VERSION"

echo "Published https://github.com/${DIST_REPO}/tree/${VERSION}"
