#!/bin/bash

# Упрощенный скрипт для создания DMG
# Использование: ./create_dmg_simple.sh [путь_к_app]

set -e

APP_PATH="${1:-build/Letta.app}"
DMG_NAME="Letta"
VERSION="3.0.0"

echo "📦 Создание DMG для $APP_PATH..."

# Удаляем приложение из build и копируем новое Letta.app в build/
rm -rf build/Letta.app
cp -R ~/Library/Developer/Xcode/DerivedData/letta-swift-*/Build/Products/Debug/Letta.app build/

# Проверяем, существует ли .app файл
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Ошибка: $APP_PATH не найден!"
    echo ""
    echo "💡 Варианты:"
    echo "   1. Соберите приложение в Xcode (Product > Build)"
    echo "   2. Найдите .app файл в:"
    echo "      ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug/Letta.app"
    echo "   3. Скопируйте его в build/ или укажите путь:"
    echo "      ./create_dmg_simple.sh /путь/к/Letta.app"
    exit 1
fi

# Создаем временную директорию для DMG
DMG_DIR="dmg_temp"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Копируем .app в директорию DMG
echo "📋 Копирование приложения..."
cp -R "$APP_PATH" "$DMG_DIR/"

# Создаем символическую ссылку на Applications
ln -s /Applications "$DMG_DIR/Applications"

# Вычисляем размер DMG
SIZE=$(du -sm "$DMG_DIR" | cut -f1)
SIZE=$((SIZE + 10)) # Добавляем 10MB запаса

# Создаем DMG файл
DMG_FILE="${DMG_NAME}-${VERSION}.dmg"
echo "🔨 Создание DMG файла: $DMG_FILE"

hdiutil create -srcfolder "$DMG_DIR" \
    -volname "$DMG_NAME" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -size ${SIZE}M \
    "$DMG_FILE"

# Удаляем временную директорию
rm -rf "$DMG_DIR"

echo ""
echo "✅ Готово! DMG файл создан: $DMG_FILE"
echo "📊 Размер файла: $(du -h "$DMG_FILE" | cut -f1)"
