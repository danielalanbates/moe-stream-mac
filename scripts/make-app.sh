#!/bin/bash
# Build /Applications/Drive AI.app — a launcher that starts serve.sh from the drive in Terminal and opens the web UI.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"; APP="/Applications/Drive AI.app"
[ -d "$APP" ] && { mkdir -p "$HERE/archive/app-builds"; mv "$APP" "$HERE/archive/app-builds/Drive AI-$(date +%Y%m%d-%H%M%S).app"; }
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Drive AI</string><key>CFBundleIdentifier</key><string>org.batesai.driveai</string>
<key>CFBundleVersion</key><string>$(date +%Y%m%d.%H%M)</string><key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleExecutable</key><string>DriveAI</string><key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string><key>LSUIElement</key><true/>
</dict></plist>
PL
cat > "$APP/Contents/MacOS/DriveAI" <<SH
#!/bin/bash
REPO="$HERE"
if pgrep -f "llama-server.*--port" >/dev/null; then open "http://localhost:8080"; exit 0; fi
osascript -e 'tell application "Terminal" to activate' -e "tell application \\"Terminal\\" to do script \\"'\$REPO/scripts/serve.sh' && open http://localhost:8080\\""
SH
chmod +x "$APP/Contents/MacOS/DriveAI"; codesign -fs - "$APP" 2>/dev/null || true
echo "built: $APP"
