#!/usr/bin/env bash
# Unity'den iOS Xcode projesi üretir ve `ios-xcode` dalına gönderir → GitHub Actions
# (ci/ios-sign.yml) imzalayıp TestFlight'a yükler.
#   Kullanım: bash tools/export_ios.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNITY="${UNITY:-/c/Users/omer.coskun/Unity/Hub/Editor/6000.0.84f1/Editor/Unity.exe}"
BUILD_NUMBER="$(date +%s)"
STAGE="$ROOT/build/ios-xcode-branch"

cd "$ROOT"
rm -rf build/iOS
echo "== Unity iOS export (build $BUILD_NUMBER)"
"$UNITY" -batchmode -quit -projectPath "$ROOT" \
  -executeMethod VinVin.EditorTools.VinVinBuild.BuildiOS \
  -buildNumber "$BUILD_NUMBER" -logFile "$ROOT/Logs/iosbuild.log"
grep -q "\[VinVin\] iOS build: Succeeded" Logs/iosbuild.log

echo "== Paketle + böl (GitHub dosya sınırı 100 MB)"
rm -rf "$STAGE" && mkdir -p "$STAGE/.github/workflows"
tar -czf - -C build/iOS iOS | split -b 90m - "$STAGE/xcode.tar.gz.part-"
cp ci/ios-sign.yml "$STAGE/.github/workflows/ios-sign.yml"
echo "$BUILD_NUMBER" > "$STAGE/BUILD_NUMBER"
ls -la "$STAGE"

echo "== ios-xcode dalına gönder"
SRC_SHA="$(git rev-parse --short HEAD)"
REMOTE="$(git remote get-url origin)"
cd "$STAGE"
git init -q -b ios-xcode
git add -A
git -c user.name="$(git -C "$ROOT" config user.name)" -c user.email="$(git -C "$ROOT" config user.email)" \
  commit -q -m "Xcode projesi: build $BUILD_NUMBER (kaynak $SRC_SHA)"
git push -f "$REMOTE" ios-xcode
echo "== Tamam: https://github.com/omerycoskun/vinvin/actions"
