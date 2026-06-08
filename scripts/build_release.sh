#!/usr/bin/env bash
# scripts/build_release.sh — SmartSpend production release builder
#
# Always passes --obfuscate and --split-debug-info so class/method names are
# stripped from the binary. Running `flutter build --release` directly is
# intentionally unsupported for production; use this script instead.
#
# Usage:
#   scripts/build_release.sh android          # APK + AAB
#   scripts/build_release.sh ios              # IPA (requires signing certs)
#   scripts/build_release.sh all              # both
#
# Environment:
#   EXCHANGE_RATE_API_KEY   Required. Set in your shell or pass inline:
#                           EXCHANGE_RATE_API_KEY=xxx scripts/build_release.sh android

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

TARGET="${1:-}"
if [[ -z "${TARGET}" ]]; then
  echo "Usage: $(basename "$0") [android|ios|all]" >&2
  exit 1
fi

: "${EXCHANGE_RATE_API_KEY:?EXCHANGE_RATE_API_KEY must be set}"

DART_DEFINES=(
  "--dart-define=EXCHANGE_RATE_API_KEY=${EXCHANGE_RATE_API_KEY}"
)

OBFUSCATION=(
  "--obfuscate"
  "--split-debug-info=build/debug-info/${TARGET}"
)

build_android() {
  echo "▶ Building Android APK (release, obfuscated)…"
  flutter build apk \
    "${DART_DEFINES[@]}" \
    "${OBFUSCATION[@]/android/${TARGET}}" \
    --release

  echo "▶ Building Android App Bundle (release, obfuscated)…"
  flutter build appbundle \
    "${DART_DEFINES[@]}" \
    --obfuscate \
    --split-debug-info=build/debug-info/android \
    --release

  echo "✓ Android artifacts:"
  echo "  APK: build/app/outputs/flutter-apk/app-release.apk"
  echo "  AAB: build/app/outputs/bundle/release/app-release.aab"
  echo "  Debug symbols: build/debug-info/android  (keep private — needed for flutter symbolize)"
}

build_ios() {
  echo "▶ Building iOS IPA (release, obfuscated)…"
  flutter build ipa \
    "${DART_DEFINES[@]}" \
    --obfuscate \
    --split-debug-info=build/debug-info/ios \
    --release

  echo "✓ iOS artifacts:"
  echo "  IPA: build/ios/ipa/*.ipa"
  echo "  Debug symbols: build/debug-info/ios  (keep private — needed for flutter symbolize)"
}

case "${TARGET}" in
  android) build_android ;;
  ios)     build_ios ;;
  all)     build_android; build_ios ;;
  *)
    echo "Unknown target '${TARGET}'. Valid: android | ios | all" >&2
    exit 1
    ;;
esac

echo ""
echo "Release build complete. Before distributing:"
echo "  1. Verify cert pin matches live server (see cert_pinning.dart)."
echo "  2. Confirm LE intermediate backup pin is in _productionPins."
echo "  3. Run scripts/apply_legal_placeholders.sh --check."
