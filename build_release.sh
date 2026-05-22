#!/bin/bash
# build_release.sh — Genera los releases de Android e iOS para US y ES
# Los IPA y AAB quedan nombrados con _us / _es para identificarlos fácilmente.

set -e

IPA_DIR="build/ios/ipa"
AAB_DIR_US="build/app/outputs/bundle/usRelease"
AAB_DIR_ES="build/app/outputs/bundle/esRelease"

echo ""
echo "🚀 PromOff — Build Release"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── iOS US ────────────────────────────────────────────────────────────────────
echo ""
echo "🍎 [iOS US] Building..."
flutter build ipa --flavor us --release \
  --export-options-plist=ios/ExportOptions-us.plist
mv "$IPA_DIR/dealsnap_app.ipa" "$IPA_DIR/dealsnap_app_us.ipa"
echo "✅ [iOS US] → $IPA_DIR/dealsnap_app_us.ipa"

# ── iOS ES ────────────────────────────────────────────────────────────────────
echo ""
echo "🍎 [iOS ES] Building..."
flutter build ipa --flavor es --release \
  --export-options-plist=ios/ExportOptions-es.plist
mv "$IPA_DIR/dealsnap_app.ipa" "$IPA_DIR/dealsnap_app_es.ipa"
echo "✅ [iOS ES] → $IPA_DIR/dealsnap_app_es.ipa"

# ── Android US ───────────────────────────────────────────────────────────────
echo ""
echo "🤖 [Android US] Building..."
flutter build appbundle --flavor us --release
echo "✅ [Android US] → $AAB_DIR_US/app-us-release.aab"

# ── Android ES ───────────────────────────────────────────────────────────────
echo ""
echo "🤖 [Android ES] Building..."
flutter build appbundle --flavor es --release
echo "✅ [Android ES] → $AAB_DIR_ES/app-es-release.aab"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Todos los builds completados:"
echo ""
echo "  iOS:"
echo "    $(ls -lh $IPA_DIR/dealsnap_app_us.ipa | awk '{print $5, $NF}')"
echo "    $(ls -lh $IPA_DIR/dealsnap_app_es.ipa | awk '{print $5, $NF}')"
echo ""
echo "  Android:"
echo "    $(ls -lh $AAB_DIR_US/app-us-release.aab | awk '{print $5, $NF}')"
echo "    $(ls -lh $AAB_DIR_ES/app-es-release.aab | awk '{print $5, $NF}')"
echo ""
echo "📦 Abre la carpeta de IPAs:"
echo "   open $IPA_DIR"
echo ""
