#!/bin/bash
# Builds AdmobLibrary.xcframework from the CocoaPods target.
# Requires a prior `pod install` so Pods/Pods.xcodeproj exists.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IOS_ARCHIVE="build/AdmobLibrary-iphoneos.xcarchive"
SIM_ARCHIVE="build/AdmobLibrary-iphonesimulator.xcarchive"
STAGE="build/xcframework-stage"

archive() {
  local sdk_name="$1"
  local destination="$2"
  local archive_path="$3"
  echo "Archiving ${sdk_name}..."
  mkdir -p build
  # Library evolution is set only on the AdmobLibrary target via the source podspec.
  # Do not pass BUILD_LIBRARY_FOR_DISTRIBUTION globally or dependency pods get a
  # different ABI than the copies apps install.
  xcodebuild archive \
    -project Pods/Pods.xcodeproj \
    -scheme AdmobLibrary \
    -configuration Release \
    -destination "$destination" \
    -archivePath "$archive_path" \
    SKIP_INSTALL=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    ONLY_ACTIVE_ARCH=NO \
    > "build/archive-${sdk_name}.log" 2>&1
  if ! grep -q "LoadingAdView.swift" "build/archive-${sdk_name}.log"; then
    echo "Archive ${sdk_name} did not compile AdmobLibrary sources. See build/archive-${sdk_name}.log" >&2
    exit 1
  fi
}

use_source_podspec() {
  mkdir -p build
  cp AdmobLibrary.podspec build/AdmobLibrary.podspec.dist
  python3 - <<'PY'
from pathlib import Path
path = Path("AdmobLibrary.podspec")
text = path.read_text()
old = "  s.vendored_frameworks = 'AdmobLibrary.xcframework'\n"
new = """  s.source_files = 'Sources/AdmobLibrary/**/*.swift'
  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'SWIFT_VERSION' => '6.0',
    'SWIFT_DEFAULT_ACTOR_ISOLATION' => 'MainActor',
    'SWIFT_APPROACHABLE_CONCURRENCY' => 'YES',
    'SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0'
  }
"""
if old not in text:
    raise SystemExit("distribution podspec is missing vendored_frameworks")
path.write_text(text.replace(old, new, 1))
PY
}

restore_dist_podspec() {
  if [[ -f build/AdmobLibrary.podspec.dist ]]; then
    mv build/AdmobLibrary.podspec.dist AdmobLibrary.podspec
    pod install > build/pod-install-restore.log 2>&1
  fi
}

if [[ "${1:-}" != "--package-only" ]]; then
  use_source_podspec
  trap restore_dist_podspec EXIT
  echo "Installing source pod to compile the binary..."
  pod install > build/pod-install-source.log 2>&1
  rm -rf "$IOS_ARCHIVE" "$SIM_ARCHIVE"
  archive "iphoneos" "generic/platform=iOS" "$IOS_ARCHIVE"
  archive "iphonesimulator" "generic/platform=iOS Simulator" "$SIM_ARCHIVE"
  restore_dist_podspec
  trap - EXIT
fi

IOS_FRAMEWORK="${IOS_ARCHIVE}/Products/Library/Frameworks/AdmobLibrary.framework"
SIM_FRAMEWORK="${SIM_ARCHIVE}/Products/Library/Frameworks/AdmobLibrary.framework"

if [[ ! -d "$IOS_FRAMEWORK" || ! -d "$SIM_FRAMEWORK" ]]; then
  echo "Missing archived AdmobLibrary.framework. Run this script without --package-only." >&2
  exit 1
fi

rm -rf "$STAGE" AdmobLibrary.xcframework
mkdir -p "$STAGE/ios" "$STAGE/sim"
cp -R "$IOS_FRAMEWORK" "$STAGE/ios/AdmobLibrary.framework"
cp -R "$SIM_FRAMEWORK" "$STAGE/sim/AdmobLibrary.framework"

# Drop readable internal interfaces. Public .swiftinterface stays so clients can import the module.
find "$STAGE" \( -name '*.private.swiftinterface' -o -name '*.abi.json' \) -delete

xcodebuild -create-xcframework \
  -framework "$STAGE/ios/AdmobLibrary.framework" \
  -framework "$STAGE/sim/AdmobLibrary.framework" \
  -output "$ROOT/AdmobLibrary.xcframework"

# create-xcframework drops .swiftmodule files. Copy them back so clients can import the module.
copy_swiftmodules() {
  local src="$1/Modules/AdmobLibrary.swiftmodule"
  local dest="$2/Modules/AdmobLibrary.swiftmodule"
  mkdir -p "$dest"
  cp "$src"/*.swiftmodule "$dest/"
}
copy_swiftmodules \
  "$STAGE/ios/AdmobLibrary.framework" \
  "$ROOT/AdmobLibrary.xcframework/ios-arm64/AdmobLibrary.framework"
copy_swiftmodules \
  "$STAGE/sim/AdmobLibrary.framework" \
  "$ROOT/AdmobLibrary.xcframework/ios-arm64_x86_64-simulator/AdmobLibrary.framework"

echo "Created $ROOT/AdmobLibrary.xcframework"
