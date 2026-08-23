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
SOURCE_SCRIPT="src/build.sh"

# 1. Проверяем наличие прав sudo в самом начале (нужны и для установки, и для удаления)
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Please run this script with sudo:"
    echo "sudo $0 ${1:-}"
    exit 1
fi

# 2. Обработка удаления (выполняется до любых проверок исходных файлов)
if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
    echo -e "${BLUE}-->${NC} Uninstalling $BINARY_NAME globally..."
    if [ -f "$TARGET_PATH" ]; then
        rm -f "$TARGET_PATH"
        echo -e "${GREEN}--> Success!${NC} $BINARY_NAME has been removed from your system."
    else
        echo -e "${RED}Error:${NC} $BINARY_NAME is not found in $INSTALL_DIR (already uninstalled)."
    fi
    exit 0
fi

# 3. Логика установки (срабатывает, если флага удаления не было)
echo -e "${BLUE}-->${NC} Installing $BINARY_NAME globally..."

# Проверяем, что исходный скрипт сборщика существует
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo -e "${RED}Error:${NC} Source script '$SOURCE_SCRIPT' not found!"
    echo "Make sure you are running install.sh from the repository root directory."
    exit 1
fi

# Копируем скрипт в системную директорию с новым именем
cp "$SOURCE_SCRIPT" "$TARGET_PATH"

# Даем права на исполнение
chmod +x "$TARGET_PATH"

echo -e "${GREEN}--> Success!${NC} $BINARY_NAME installed to $TARGET_PATH"
echo "You can now use it anywhere by typing: $BINARY_NAME"

