#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
EXE="$DIST_DIR/RPIIUtility.exe"
WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/rpii-utility/wine"
DESKTOP_FILE="$HOME/.local/share/applications/rpii-utility.desktop"

build() {
  echo "Building RPII Utility for Windows (cross-compiling on Linux)..."
  echo ""

  dotnet publish \
    "$SCRIPT_DIR/RPIIUtility.csproj" \
    -c Release \
    -r win-x64 \
    --self-contained \
    -p:EnableWindowsTargeting=true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -o "$DIST_DIR"

  echo ""
  echo "Built: $EXE"
}

run() {
  if [ ! -f "$EXE" ]; then
    echo "No build found, building first..."
    build
  fi

  echo "Launching via Wine..."
  export WINEPREFIX
  export WINEDEBUG=-all
  export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
  mkdir -p "$WINEPREFIX"

  wine "$EXE" "$@"
}

install_desktop() {
  if [ ! -f "$EXE" ]; then
    echo "No build found, building first..."
    build
  fi

  mkdir -p "$(dirname "$DESKTOP_FILE")"

  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=RPII Utility
Comment=RPII Inflatable Inspection Utility
Exec=bash -c 'WINEPREFIX="${WINEPREFIX}" WINEDEBUG=-all DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 wine "${EXE}"'
Type=Application
Categories=Utility;Office;
Terminal=false
StartupWMClass=rpiiutility.exe
EOF

  echo "Installed desktop entry: $DESKTOP_FILE"
  echo "RPII Utility should now appear in your application launcher."

  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  fi
}

case "${1:-build}" in
  build)   build ;;
  run)     shift; run "$@" ;;
  install) install_desktop ;;
  *)
    echo "Usage: $0 [build|run|install]"
    echo ""
    echo "  build    Cross-compile the Windows exe (default)"
    echo "  run      Build (if needed) and launch via Wine"
    echo "  install  Build (if needed) and install .desktop launcher entry"
    exit 1
    ;;
esac
