#!/bin/bash
# Stages a public binary tree: xcframework + resources, no Swift source.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="$ROOT/build/binary-dist"
DIST_REPO="TienNguyen267/AdmobLibraryBinary"

cd "$ROOT"

if [[ ! -d "$ROOT/AdmobLibrary.xcframework" ]]; then
  echo "Missing AdmobLibrary.xcframework. Run Scripts/build-xcframework.sh first." >&2
  exit 1
fi

VERSION="$(awk -F"'" '/^[[:space:]]*s\.version[[:space:]]*=/{print $2; exit}' "$ROOT/AdmobLibrary.podspec")"
if [[ -z "$VERSION" ]]; then
  echo "Could not read s.version from AdmobLibrary.podspec" >&2
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$STAGE/Sources/AdmobLibrary"

cp "$ROOT/AdmobLibrary.podspec" "$STAGE/AdmobLibrary.podspec"
rsync -a --exclude '.DS_Store' "$ROOT/AdmobLibrary.xcframework/" "$STAGE/AdmobLibrary.xcframework/"
rsync -a --exclude '.DS_Store' "$ROOT/Sources/AdmobLibrary/Resources/" "$STAGE/Sources/AdmobLibrary/Resources/"

find "$STAGE" \( -name '*.private.swiftinterface' -o -name '*.abi.json' -o -name '*.swiftsourceinfo' -o -name '*.dSYM' -o -name '.DS_Store' \) -delete

# Debug symbols are not needed to link the static archive.
while IFS= read -r binary; do
  strip -S "$binary" || echo "strip skipped: $binary" >&2
done < <(find "$STAGE/AdmobLibrary.xcframework" -type f -name 'AdmobLibrary')

cat > "$STAGE/LICENSE" <<'EOF'
MIT License

Copyright (c) 2026 VietTienNguyen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

cat > "$STAGE/README.md" <<EOF
# AdmobLibrary

Public binary distribution for CocoaPods. This repository does not contain Swift source.

\`\`\`ruby
pod 'AdmobLibrary', '${VERSION}'
\`\`\`
EOF

swift_files="$(find "$STAGE" -name '*.swift' -print)"
if [[ -n "$swift_files" ]]; then
  echo "Refusing to package. Swift source is in the binary tree:" >&2
  echo "$swift_files" >&2
  exit 1
fi

if ! find "$STAGE" -name '*.swiftinterface' -print | grep -q .; then
  echo "Binary is missing .swiftinterface files, so apps cannot import the module." >&2
  exit 1
fi

echo "Packaged AdmobLibrary ${VERSION} at ${STAGE}"
echo "Publish target: https://github.com/${DIST_REPO}"
find "$STAGE" -type f | sed "s|^$STAGE/||" | sort
