#!/usr/bin/env bash

set -euo pipefail

# Цвета для красивого вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="cpm"
TARGET_PATH="$INSTALL_DIR/$BINARY_NAME"

echo -e "${BLUE}-->${NC} Uninstalling $BINARY_NAME..."

# 1. Проверяем наличие прав sudo (так как удаление из /usr/local/bin требует root-прав)
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Please run uninstall.sh with sudo:"
    echo "sudo ./uninstall.sh"
    exit 1
fi

# 2. Проверяем, установлена ли утилита вообще
if [ ! -f "$TARGET_PATH" ]; then
    echo -e "${RED}Error:${NC} $BINARY_NAME is not found in $INSTALL_DIR. It might not be installed."
    exit 1
fi

# 3. Удаляем бинарник
rm "$TARGET_PATH"

echo -e "${GREEN}--> Success!${NC} $BINARY_NAME has been successfully removed from your system."

