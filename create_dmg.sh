#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

VERSION="1.0.5"
DMG_NAME="MacClip-${VERSION}.dmg"
DIST_DIR="$DIR/dist"
STAGING_DIR="/tmp/macclip_dmg_staging"

echo "🚀 Ensuring release build is up to date..."
./build_app.sh

mkdir -p "$DIST_DIR"
rm -rf "$STAGING_DIR" "$DIST_DIR/$DMG_NAME" "$DIST_DIR/MacClip.dmg"
mkdir -p "$STAGING_DIR"

echo "📦 Staging MacClip.app and Applications drag-and-drop symlink..."
cp -R "$DIR/build/MacClip.app" "$STAGING_DIR/MacClip.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "💿 Creating compressed DMG disk image..."
hdiutil create \
    -volname "MacClip" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$DMG_NAME"

# Copy as standard unversioned MacClip.dmg as well
cp "$DIST_DIR/$DMG_NAME" "$DIST_DIR/MacClip.dmg"

echo "🔏 Code-signing DMG..."
codesign --force --sign - "$DIST_DIR/$DMG_NAME"
codesign --force --sign - "$DIST_DIR/MacClip.dmg"

rm -rf "$STAGING_DIR"

DMG_SIZE=$(ls -lh "$DIST_DIR/$DMG_NAME" | awk '{print $5}')

echo ""
echo "========================================================"
echo "✅ DMG package successfully created! ($DMG_SIZE)"
echo "📍 Versioned: $DIST_DIR/$DMG_NAME"
echo "📍 Standard:  $DIST_DIR/MacClip.dmg"
echo "========================================================"
