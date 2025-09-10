#!/bin/bash

# Script para generar todos los tamaños de iconos de iOS desde el icono base
# Requiere ImageMagick: brew install imagemagick

BASE_ICON="StepsTracker/Assets.xcassets/AppIcon.appiconset/iOS Icon light mode.png"
OUTPUT_DIR="StepsTracker/Assets.xcassets/AppIcon.appiconset"

# Verificar que existe ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick no está instalado. Instálalo con: brew install imagemagick"
    exit 1
fi

# Verificar que existe el icono base
if [ ! -f "$BASE_ICON" ]; then
    echo "❌ No se encuentra el icono base: $BASE_ICON"
    exit 1
fi

echo "🎨 Generando iconos de app desde $BASE_ICON..."

# Tamaños requeridos para iOS
declare -a sizes=(
    "20:app-icon-20.png"
    "40:app-icon-20@2x.png"
    "60:app-icon-20@3x.png"
    "29:app-icon-29.png"
    "58:app-icon-29@2x.png"
    "87:app-icon-29@3x.png"
    "40:app-icon-40.png"
    "80:app-icon-40@2x.png"
    "120:app-icon-40@3x.png"
    "120:app-icon-60@2x.png"
    "180:app-icon-60@3x.png"
    "76:app-icon-76.png"
    "152:app-icon-76@2x.png"
    "167:app-icon-83.5@2x.png"
)

# Generar cada tamaño
for size_info in "${sizes[@]}"; do
    IFS=':' read -r size filename <<< "$size_info"
    echo "  📱 Generando ${filename} (${size}x${size}px)"
    convert "$BASE_ICON" -resize "${size}x${size}" "$OUTPUT_DIR/$filename"
done

echo "✅ ¡Iconos generados exitosamente!"
echo ""
echo "📋 Tamaños generados:"
echo "   • 20x20 (1x, 2x, 3x) - Notificaciones"
echo "   • 29x29 (1x, 2x, 3x) - Configuración"
echo "   • 40x40 (1x, 2x, 3x) - Spotlight"
echo "   • 60x60 (2x, 3x) - App iPhone"
echo "   • 76x76 (1x, 2x) - App iPad"
echo "   • 83.5x83.5 (2x) - App iPad Pro"
echo "   • 1024x1024 - App Store"
echo ""
echo "🚀 Tu app ya tiene todos los iconos requeridos para la App Store!"
