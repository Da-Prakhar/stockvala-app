#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# build_brand.sh  —  Build one or all white-label brands
#
# Usage:
#   ./scripts/build_brand.sh                       # build all brands
#   ./scripts/build_brand.sh stockvala             # build one brand
#   ./scripts/build_brand.sh alphatrade release    # brand + build type
#   ./scripts/build_brand.sh all ios               # all brands for iOS
#
# Outputs go to build/brands/<brand>/
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
cd "$(dirname "$0")/.."   # always run from project root

BRAND="${1:-all}"
PLATFORM="${2:-android}"   # android | ios | all

BRANDS=(stockvala alphatrade goldfx nexustrade)

build_android() {
  local brand="$1"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Building Android APK  →  $brand"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  flutter build apk \
    --flavor "$brand" \
    --dart-define=BRAND="$brand" \
    --release \
    --obfuscate \
    --split-debug-info="build/symbols/$brand"

  local out="build/brands/$brand"
  mkdir -p "$out"
  cp "build/app/outputs/flutter-apk/app-${brand}-release.apk" \
     "$out/${brand}-release.apk"

  echo "  ✓ APK  →  $out/${brand}-release.apk"
}

build_ios() {
  local brand="$1"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Building iOS IPA  →  $brand"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  flutter build ipa \
    --dart-define=BRAND="$brand" \
    --release \
    --obfuscate \
    --split-debug-info="build/symbols/$brand"

  local out="build/brands/$brand"
  mkdir -p "$out"
  cp build/ios/ipa/*.ipa "$out/${brand}-release.ipa" 2>/dev/null || \
    echo "  ⚠ IPA not found — check Xcode signing config for flavor $brand"

  echo "  ✓ IPA  →  $out/${brand}-release.ipa"
}

run_for_brand() {
  local brand="$1"
  case "$PLATFORM" in
    android) build_android "$brand" ;;
    ios)     build_ios "$brand" ;;
    all)     build_android "$brand"; build_ios "$brand" ;;
    *)       echo "Unknown platform: $PLATFORM"; exit 1 ;;
  esac
}

echo "StockVala White-Label Build System"
echo "Platform: $PLATFORM | Brand: $BRAND"

if [[ "$BRAND" == "all" ]]; then
  for b in "${BRANDS[@]}"; do
    run_for_brand "$b"
  done
else
  # Validate brand name
  valid=false
  for b in "${BRANDS[@]}"; do
    [[ "$b" == "$BRAND" ]] && valid=true && break
  done
  if ! $valid; then
    echo "Unknown brand: $BRAND"
    echo "Valid brands: ${BRANDS[*]}"
    exit 1
  fi
  run_for_brand "$BRAND"
fi

echo ""
echo "Build complete. Artifacts in build/brands/"
