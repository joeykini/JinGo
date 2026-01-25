#!/bin/bash

# 使用方法: ./generate_icns.sh input.png output.icns

INPUT_IMAGE="$1"
OUTPUT_ICNS="$2"

if [ -z "$INPUT_IMAGE" ] || [ -z "$OUTPUT_ICNS" ]; then
    echo "Usage: $0 <input.png> <output.icns>"
    echo "Example: $0 icon.png app.icns"
    exit 1
fi

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "Error: Input file $INPUT_IMAGE not found"
    exit 1
fi

# 创建临时 iconset 目录
ICONSET_DIR="${OUTPUT_ICNS%.icns}.iconset"
mkdir -p "$ICONSET_DIR"

# 生成各种尺寸
echo "Generating icon sizes..."
sips -z 16 16     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

# 转换为 icns
echo "Converting to icns..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# 清理临时文件
rm -rf "$ICONSET_DIR"

echo "✓ Generated: $OUTPUT_ICNS"
