#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate Windows ICO file from PNG
This script converts PNG images to ICO format for Windows applications
"""

import sys
import os
from pathlib import Path

# Set UTF-8 encoding for stdout on Windows
if sys.platform == 'win32':
    import codecs
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
    if sys.stderr.encoding != 'utf-8':
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

def generate_ico_from_png(png_path, ico_path):
    """
    Convert PNG to ICO format
    Tries multiple methods: PIL (Pillow) first, then imagemagick
    """
    png_path = Path(png_path)
    ico_path = Path(ico_path)

    if not png_path.exists():
        print(f"Error: PNG file not found: {png_path}")
        return False

    # Method 1: Try using Pillow (PIL)
    try:
        from PIL import Image

        # Open the PNG image
        img = Image.open(png_path)

        # Convert to RGBA if needed
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Generate multiple sizes for better Windows compatibility
        # Windows ICO typically includes: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256
        sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]

        # Create directory if it doesn't exist
        ico_path.parent.mkdir(parents=True, exist_ok=True)

        # Save as ICO with multiple sizes
        img.save(ico_path, format='ICO', sizes=sizes)

        print(f"✓ Successfully generated ICO file: {ico_path}")
        print(f"  Sizes included: {', '.join([f'{s[0]}x{s[1]}' for s in sizes])}")
        return True

    except ImportError:
        print("Warning: Pillow (PIL) not found, trying ImageMagick...")
    except Exception as e:
        print(f"Warning: Failed to generate ICO with Pillow: {e}")
        print("Trying ImageMagick...")

    # Method 2: Try using ImageMagick
    try:
        import subprocess

        # Check if convert (ImageMagick) is available
        result = subprocess.run(['convert', '-version'],
                              capture_output=True,
                              text=True)

        if result.returncode != 0:
            raise Exception("ImageMagick 'convert' command not found")

        # Convert PNG to ICO with multiple sizes
        cmd = [
            'convert',
            str(png_path),
            '-define', 'icon:auto-resize=256,128,64,48,32,16',
            str(ico_path)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            print(f"✓ Successfully generated ICO file with ImageMagick: {ico_path}")
            return True
        else:
            print(f"Error: ImageMagick conversion failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"Error: Failed to generate ICO with ImageMagick: {e}")

    # If we get here, both methods failed
    print("\nFailed to generate ICO file. Please install one of:")
    print("  1. Pillow: pip install Pillow")
    print("  2. ImageMagick: https://imagemagick.org/")
    return False

def main():
    if len(sys.argv) != 3:
        print("Usage: generate_icon.py <input.png> <output.ico>")
        sys.exit(1)

    png_path = sys.argv[1]
    ico_path = sys.argv[2]

    success = generate_ico_from_png(png_path, ico_path)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
