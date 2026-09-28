#!/bin/bash
# Wacchi をビルドして Wacchi.app を作る。Xcode 本体は不要（Command Line Tools のみで動く）。
set -euo pipefail

cd "$(dirname "$0")"

APP="Wacchi.app"
TARGET="arm64-apple-macos14.0"
# リリース時は release.sh から渡される。手元のビルドでは 0.0.0 のままでよい
VERSION="${WACCHI_VERSION:-0.0.0}"
SPARKLE_VERSION="2.9.5"

# 自動更新に Sparkle を使う。framework は大きいのでリポジトリに置かず、
# 無ければ取ってくる（Vendor/ は git の管理外）
if [ ! -d "Vendor/Sparkle.framework" ]; then
  echo "Sparkle $SPARKLE_VERSION を取得します…"
  mkdir -p Vendor
  TMP="$(mktemp -d)"
  curl -sL -o "$TMP/sparkle.tar.xz" \
    "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"
  tar xf "$TMP/sparkle.tar.xz" -C "$TMP"
  cp -R "$TMP/Sparkle.framework" Vendor/
  cp -R "$TMP/bin" Vendor/
  rm -rf "$TMP"
fi

rm -rf "$APP" build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks"

cp -R Vendor/Sparkle.framework "$APP/Contents/Frameworks/"

swiftc \
  -parse-as-library \
  -target "$TARGET" \
  -swift-version 6 \
  -O \
  -F Vendor \
  -framework AppKit \
  -framework IOKit \
  -framework Sparkle \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  -o "$APP/Contents/MacOS/Wacchi" \
  Sources/Localization.swift Sources/Power.swift \
  Sources/Settings.swift Sources/SelfTest.swift Sources/Updater.swift \
  Sources/SettingsWindow.swift Sources/main.swift

# アプリ本体のアイコン。元絵があれば .icns を組み立てる。
# 無くてもビルドは通る（Finder では白紙のままになる）
if [ -f Resources/wacchi-icon.png ]; then
  ICONSET="build/Wacchi.iconset"
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  for size in 16 32 128 256 512; do
    sips -z $size $size Resources/wacchi-icon.png \
      --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) Resources/wacchi-icon.png \
      --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
  done
  mkdir -p "$APP/Contents/Resources"
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Wacchi.icns"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Wacchi</string>
  <key>CFBundleDisplayName</key><string>Wacchi</string>
  <key>CFBundleExecutable</key><string>Wacchi</string>
  <key>CFBundleIconFile</key><string>Wacchi</string>
  <key>CFBundleIdentifier</key><string>io.kkweb.wacchi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <!-- Dock とアプリ切替に出さず、メニューバーだけに常駐させる -->
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>

  <!-- 自動更新（Sparkle）。確認は起動時に1回だけ行い、見つかったときだけ画面を出す。
       この2つを false にしておかないと、初回起動で「自動で確認していいか」を尋ねる画面が出る -->
  <key>SUFeedURL</key><string>https://github.com/piro0919/wacchi/releases/latest/download/appcast.xml</string>
  <!-- 更新の署名を確かめる公開鍵。対になる秘密鍵はログインキーチェーンにあり、これを失うと更新を配れなくなる -->
  <key>SUPublicEDKey</key><string>qYQq1iewXYNDhhkJJak1nXUXmFkZ0jAF6Gr+pjB4Bxo=</string>
  <key>SUEnableAutomaticChecks</key><false/>
  <key>SUAutomaticallyUpdate</key><false/>
</dict>
</plist>
PLIST

# framework は中から署名する。先にアプリを署名すると、後から中身が変わって壊れる
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework"
codesign --force --sign - "$APP"

echo "できました: $(pwd)/$APP"
