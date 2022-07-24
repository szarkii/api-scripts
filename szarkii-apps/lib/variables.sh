# Main
SZARKII_APPS_DIR="$(szarkii-apps --get-apps-root-dir)"
SZARKII_APPS_LIB_DIR="$(szarkii-apps --get-apps-lib-dir)"
SZARKII_APPS_CONFIG_DIR="$SZARKII_APPS_DIR/.config"

mkdir -p "$SZARKII_APPS_LIB_DIR"
mkdir -p "$SZARKII_APPS_CONFIG_DIR"

# Libraries
LIB_HELP="$SZARKII_APPS_LIB_DIR/help.sh"
LIB_LOG="$SZARKII_APPS_LIB_DIR/log.sh"