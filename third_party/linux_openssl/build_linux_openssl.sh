#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSSL_VERSION="${OPENSSL_VERSION:-3.0.7}"
SRC_DIR="$ROOT_DIR/src/openssl-$OPENSSL_VERSION"
TEMP_BUILD_DIR="$ROOT_DIR/build/openssl-$OPENSSL_VERSION"
OUTPUT_DIR="$ROOT_DIR"
OPENSSL_CONFIG_OPTS="${OPENSSL_CONFIG_OPTS:-shared no-tests}"

# Auto-detect tarball location (build/ has priority, then src/)
if [ -z "${OPENSSL_TARBALL:-}" ]; then
    if [ -f "$ROOT_DIR/build/android_openssl_$OPENSSL_VERSION.tar.gz" ] && [ -s "$ROOT_DIR/build/android_openssl_$OPENSSL_VERSION.tar.gz" ]; then
        TARBALL="$ROOT_DIR/build/android_openssl_$OPENSSL_VERSION.tar.gz"
    elif [ -f "$ROOT_DIR/build/openssl-$OPENSSL_VERSION.tar.gz" ] && [ -s "$ROOT_DIR/build/openssl-$OPENSSL_VERSION.tar.gz" ]; then
        TARBALL="$ROOT_DIR/build/openssl-$OPENSSL_VERSION.tar.gz"
    else
        # Default to build directory for new downloads
        TARBALL="$ROOT_DIR/build/openssl-$OPENSSL_VERSION.tar.gz"
    fi
else
    TARBALL="${OPENSSL_TARBALL}"
fi

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

download_openssl() {
    # Try multiple mirror URLs
    local urls=(
        "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"
        "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
        "https://ftp.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    )

    # Ensure build directory exists
    mkdir -p "$ROOT_DIR/build"

    # Check if tarball exists and is not empty - if so, keep it
    if [ -f "$TARBALL" ] && [ -s "$TARBALL" ]; then
        echo "Using existing tarball: $TARBALL"
        return
    fi

    # Remove incomplete/empty tarball if exists
    rm -f "$TARBALL"

    echo "Downloading OpenSSL ${OPENSSL_VERSION} to build directory..."

    local success=0
    for url in "${urls[@]}"; do
        echo "Trying: $url"
        if command -v wget >/dev/null 2>&1; then
            if wget --no-check-certificate --timeout=30 -O "$TARBALL" "$url" 2>/dev/null; then
                # Verify download succeeded
                if [ -s "$TARBALL" ]; then
                    success=1
                    echo "Download successful from: $url"
                    break
                fi
            fi
        elif command -v curl >/dev/null 2>&1; then
            if curl -k -L --connect-timeout 30 -o "$TARBALL" "$url" 2>/dev/null; then
                # Verify download succeeded
                if [ -s "$TARBALL" ]; then
                    success=1
                    echo "Download successful from: $url"
                    break
                fi
            fi
        fi
        rm -f "$TARBALL"
    done

    if [ $success -eq 0 ]; then
        echo "Failed to download from all mirrors. Please download manually:" >&2
        echo "  wget https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" >&2
        echo "  mv openssl-${OPENSSL_VERSION}.tar.gz $ROOT_DIR/build/" >&2
        exit 1
    fi
}

prepare_source() {
    # Ensure src directory exists
    mkdir -p "$ROOT_DIR/src"

    # Check if source already extracted and valid
    if [ -d "$SRC_DIR" ] && [ -f "$SRC_DIR/Configure" ]; then
        echo "Using existing source: $SRC_DIR"
        return
    fi

    # Remove incomplete source directory if exists
    rm -rf "$SRC_DIR"

    # Download if needed
    download_openssl

    echo "Extracting OpenSSL source..."
    tar -xzf "$TARBALL" -C "$ROOT_DIR/src" || {
        echo "Failed to extract tarball" >&2
        rm -rf "$SRC_DIR"
        exit 1
    }

    # Verify extraction succeeded
    if [ ! -f "$SRC_DIR/Configure" ]; then
        echo "Source directory incomplete after extraction" >&2
        rm -rf "$SRC_DIR"
        exit 1
    fi
}

normalize_arch() {
    case "$1" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        i386|i686|x86)
            echo "x86"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armv6l)
            echo "arm"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

target_from_arch() {
    case "$1" in
        x86_64)
            echo "linux-x86_64"
            ;;
        x86)
            echo "linux-x86"
            ;;
        arm64)
            echo "linux-aarch64"
            ;;
        arm)
            echo "linux-armv4"
            ;;
        *)
            echo ""
            ;;
    esac
}

output_arch_from_arch() {
    case "$1" in
        x86_64)
            echo "x86_64"
            ;;
        x86)
            echo "x86"
            ;;
        arm64)
            echo "arm64"
            ;;
        arm)
            echo "arm"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

arch_from_target() {
    case "$1" in
        linux-x86_64)
            echo "x86_64"
            ;;
        linux-x86)
            echo "x86"
            ;;
        linux-aarch64)
            echo "arm64"
            ;;
        linux-armv4)
            echo "arm"
            ;;
        *)
            echo ""
            ;;
    esac
}

cpu_count() {
    getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4
}

setup_cross_compile() {
    local target_arch="$1"
    local host_arch="$2"

    CROSS_PREFIX="${CROSS_PREFIX:-}"
    CROSS_COMPILE_OPT=""

    if [ "$host_arch" != "$target_arch" ]; then
        if [ -z "$CROSS_PREFIX" ] && [ -z "${CC:-}" ]; then
            case "$target_arch" in
                arm64)
                    CROSS_PREFIX="aarch64-linux-gnu-"
                    ;;
                x86)
                    # For x86 on x86_64 host, use -m32
                    if [ "$host_arch" = "x86_64" ]; then
                        export CC="gcc -m32"
                        export CXX="g++ -m32"
                        echo "Using -m32 for x86 build on x86_64 host"
                    else
                        CROSS_PREFIX="i686-linux-gnu-"
                    fi
                    ;;
                arm)
                    CROSS_PREFIX="arm-linux-gnueabihf-"
                    ;;
                *)
                    echo "Cross-compile requested for unsupported arch: $target_arch" >&2
                    echo "Please set CROSS_PREFIX or CC manually." >&2
                    exit 1
                    ;;
            esac
        fi

        if [ -n "$CROSS_PREFIX" ]; then
            require_cmd "${CROSS_PREFIX}gcc"
            require_cmd "${CROSS_PREFIX}ar"
            require_cmd "${CROSS_PREFIX}ranlib"
            CROSS_COMPILE_OPT="--cross-compile-prefix=$CROSS_PREFIX"
            echo "Using cross compiler: $CROSS_PREFIX"
        fi
    fi
}

# Main execution
require_cmd perl
require_cmd make
require_cmd tar

prepare_source

HOST_ARCH="$(normalize_arch "$(uname -m)")"
TARGET_ARCH="${TARGET_ARCH:-}"

if [ -z "$TARGET_ARCH" ] && [ -n "${OPENSSL_TARGET:-}" ]; then
    TARGET_ARCH="$(arch_from_target "$OPENSSL_TARGET")"
fi

if [ -z "$TARGET_ARCH" ]; then
    TARGET_ARCH="$HOST_ARCH"
fi

TARGET_ARCH="$(normalize_arch "$TARGET_ARCH")"

OPENSSL_TARGET="${OPENSSL_TARGET:-$(target_from_arch "$TARGET_ARCH")}"
if [ -z "$OPENSSL_TARGET" ]; then
    echo "Unable to detect OpenSSL target. Set OPENSSL_TARGET explicitly." >&2
    exit 1
fi

OUT_ARCH="${OPENSSL_OUTPUT_ARCH:-$(output_arch_from_arch "$TARGET_ARCH")}"

echo "Building OpenSSL $OPENSSL_VERSION for $TARGET_ARCH (host: $HOST_ARCH)"

setup_cross_compile "$TARGET_ARCH" "$HOST_ARCH"

# Clean and prepare build directory
rm -rf "$TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR"
cp -R "$SRC_DIR/." "$TEMP_BUILD_DIR/"

pushd "$TEMP_BUILD_DIR" >/dev/null

echo "Configuring OpenSSL with target: $OPENSSL_TARGET"
./Configure "$OPENSSL_TARGET" $OPENSSL_CONFIG_OPTS $CROSS_COMPILE_OPT \
    --prefix="$TEMP_BUILD_DIR/out" \
    --openssldir="$TEMP_BUILD_DIR/out/ssl"

echo "Building OpenSSL (using $(cpu_count) cores)..."
make -j"$(cpu_count)"

echo "Installing OpenSSL..."
make install_sw

popd >/dev/null

# Copy outputs to final locations
mkdir -p "$OUTPUT_DIR/include" "$OUTPUT_DIR/$OUT_ARCH"
rm -rf "$OUTPUT_DIR/include/openssl"
cp -R "$TEMP_BUILD_DIR/out/include/openssl" "$OUTPUT_DIR/include/"

# OpenSSL may install to lib or lib64 depending on platform
if [ -d "$TEMP_BUILD_DIR/out/lib64" ]; then
    cp -a "$TEMP_BUILD_DIR/out/lib64/." "$OUTPUT_DIR/$OUT_ARCH/"
elif [ -d "$TEMP_BUILD_DIR/out/lib" ]; then
    cp -a "$TEMP_BUILD_DIR/out/lib/." "$OUTPUT_DIR/$OUT_ARCH/"
else
    echo "Error: Neither lib nor lib64 directory found" >&2
    exit 1
fi

echo ""
echo "==================================="
echo "Linux OpenSSL build complete!"
echo "==================================="
echo "Architecture: $OUT_ARCH"
echo "Output dir: $OUTPUT_DIR"
echo "Headers: $OUTPUT_DIR/include/openssl/"
echo "Libraries: $OUTPUT_DIR/$OUT_ARCH/"
echo ""
