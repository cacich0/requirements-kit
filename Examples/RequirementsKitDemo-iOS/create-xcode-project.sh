#!/bin/bash

# Скрипт для создания Xcode проекта для RequirementsKitDemo-iOS

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"

echo "🚀 Создание Xcode проекта для RequirementsKitDemo-iOS..."

# Проверяем наличие xcodegen
if command -v xcodegen &> /dev/null; then
    echo "✅ Найден xcodegen, создаю проект..."
    cd "$PROJECT_DIR"
    xcodegen generate
    echo "✅ Проект создан! Открываю в Xcode..."
    open RequirementsKitDemo-iOS.xcodeproj
else
    echo "⚠️  xcodegen не найден"
    echo ""
    echo "Для автоматического создания проекта установите xcodegen:"
    echo "  brew install xcodegen"
    echo ""
    echo "Или создайте проект вручную:"
    echo "  1. Откройте Xcode"
    echo "  2. File → New → Project"
    echo "  3. Выберите iOS → App"
    echo "  4. Заполните данные и сохраните в: $PROJECT_DIR"
    echo "  5. Добавьте файлы из RequirementsKitDemo-iOS/"
    echo "  6. Добавьте RequirementsKit как Local Package Dependency"
    echo ""
    echo "Подробные инструкции в README.md"
fi

