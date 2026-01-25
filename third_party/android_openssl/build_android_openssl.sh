#!/bin/bash
#
# Build OpenSSL for Android (all architectures)
#
# Usage:
#   ./build_android_openssl.sh                    # Build all ABIs
#   ./build_android_openssl.sh arm64-v8a x86_64   # Build specific ABIs
#
# Environment variables:
#   ANDROID_NDK         - Path to Android NDK
#   ANDROID_API_LEVEL   - Minimum API level (default: 24)
#   OPENSSL_VERSION     - OpenSSL version (default: 3.0.7)
#   OPENSSL_TARBALL     - Path to OpenSSL tarball
#   BUILD_SHARED        - Build shared libs (default: 1)
#   BUILD_STATIC        - Build static libs (default: 1)
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSSL_VERSION="${OPENSSL_VERSION:-3.0.7}"
SRC_DIR="$ROOT_DIR/src/openssl-$OPENSSL_VERSION"
BUILD_DIR="$ROOT_DIR/build"
TARBALL="${OPENSSL_TARBALL:-$BUILD_DIR/android_openssl_${OPENSSL_VERSION}.tar.gz}"
OUTPUT_DIR="$ROOT_DIR"
ANDROID_API_LEVEL="${ANDROID_API_LEVEL:-24}"
BUILD_SHARED="${BUILD_SHARED:-1}"
BUILD_STATIC="${BUILD_STATIC:-1}"
REQUESTED_ABIS=("$@")

# Determine OpenSSL config options
if [ "$BUILD_SHARED" = "1" ]; then
    OPENSSL_CONFIG_OPTS="${OPENSSL_CONFIG_OPTS:-shared no-tests}"
elif [ "$BUILD_STATIC" = "1" ]; then
    OPENSSL_CONFIG_OPTS="${OPENSSL_CONFIG_OPTS:-no-shared no-tests}"
else
    echo "Both BUILD_SHARED and BUILD_STATIC are disabled." >&2
    exit 1
fi

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

detect_host_tag() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "$os" in
        Darwin)
            # Check what's actually available in NDK (some NDKs only have x86_64)
            if [ "$arch" = "arm64" ]; then
                echo "darwin-arm64"
            else
                echo "darwin-x86_64"
            fi
            ;;
        Linux)
            echo "linux-x86_64"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Find the actual host tag available in NDK
find_ndk_host_tag() {
    local ndk="$1"
    local detected="$2"
    local prebuilt_dir="$ndk/toolchains/llvm/prebuilt"

    # First try the detected host tag
    if [ -d "$prebuilt_dir/$detected" ]; then
        echo "$detected"
        return
    fi

    # Fallback: find any available host tag
    for tag in darwin-x86_64 darwin-arm64 linux-x86_64; do
        if [ -d "$prebuilt_dir/$tag" ]; then
            echo "$tag"
            return
        fi
    done

    echo ""
}

find_ndk() {
    if [ -n "${ANDROID_NDK:-}" ] && [ -d "$ANDROID_NDK" ]; then
        echo "$ANDROID_NDK"
        return
    fi
    if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "$ANDROID_NDK_HOME" ]; then
        echo "$ANDROID_NDK_HOME"
        return
    fi
    if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -d "$ANDROID_SDK_ROOT/ndk" ]; then
        ls -1d "$ANDROID_SDK_ROOT/ndk/"* 2>/dev/null | sort | tail -1
        return
    fi
    if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
        ls -1d "$ANDROID_HOME/ndk/"* 2>/dev/null | sort | tail -1
        return
    fi
    if [ -d "$HOME/Library/Android/sdk/ndk" ]; then
        ls -1d "$HOME/Library/Android/sdk/ndk/"* 2>/dev/null | sort | tail -1
        return
    fi
    if [ -d "$HOME/Android/Sdk/ndk" ]; then
        ls -1d "$HOME/Android/Sdk/ndk/"* 2>/dev/null | sort | tail -1
        return
    fi
    if [ -d "/Volumes/mindata/Library/Android/aarch64/sdk/ndk" ]; then
        ls -1d "/Volumes/mindata/Library/Android/aarch64/sdk/ndk/"* 2>/dev/null | sort | tail -1
        return
    fi
    echo ""
}

download_openssl() {
    local url="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    mkdir -p "$ROOT_DIR/src" "$BUILD_DIR"
    if [ -f "$TARBALL" ]; then
        echo "Using existing tarball: $TARBALL"
        return
    fi
    echo "Downloading OpenSSL $OPENSSL_VERSION..."
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$TARBALL" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$TARBALL" "$url"
    else
        echo "Need curl or wget to download OpenSSL." >&2
        exit 1
    fi
}

prepare_source() {
    if [ -d "$SRC_DIR" ]; then
        echo "Source already extracted"
        return
    fi
    download_openssl
    echo "Extracting..."
    tar -xzf "$TARBALL" -C "$ROOT_DIR/src"
}

cpu_count() {
    sysctl -n hw.ncpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4
}

build_one() {
    local abi="$1"
    local target="$2"
    local cc_prefix="$3"
    local out_dir="$BUILD_DIR/$abi"

    echo "Building OpenSSL for $abi ($target)..."

    rm -rf "$out_dir"
    mkdir -p "$out_dir"
    cp -R "$SRC_DIR/." "$out_dir/"

    # Add NDK toolchain to PATH
    export PATH="$TOOLCHAIN/bin:$PATH"
    export ANDROID_NDK_ROOT="$ANDROID_NDK"

    # Set compiler environment variables
    export CC="${cc_prefix}${ANDROID_API_LEVEL}-clang"
    export CXX="${cc_prefix}${ANDROID_API_LEVEL}-clang++"
    export AR="llvm-ar"
    export RANLIB="llvm-ranlib"
    export STRIP="llvm-strip"

    pushd "$out_dir" >/dev/null
    ./Configure "$target" $OPENSSL_CONFIG_OPTS \
        -D__ANDROID_API__=$ANDROID_API_LEVEL \
        --prefix="$out_dir/out" \
        --openssldir="$out_dir/out/ssl"
    make -j"$(cpu_count)"
    make install_sw
    popd >/dev/null

    # Copy output
    mkdir -p "$OUTPUT_DIR/$abi"

    # Copy headers (only once)
    if [ ! -d "$OUTPUT_DIR/include/openssl" ]; then
        mkdir -p "$OUTPUT_DIR/include"
        cp -R "$out_dir/out/include/openssl" "$OUTPUT_DIR/include/"
    fi

    # Copy shared libraries
    if [ "$BUILD_SHARED" = "1" ]; then
        if [ -f "$out_dir/out/lib/libssl.so" ]; then
            cp -f "$out_dir/out/lib/libssl.so" "$OUTPUT_DIR/$abi/libssl_3.so"
        elif [ -f "$out_dir/out/lib/libssl.so.3" ]; then
            cp -f "$out_dir/out/lib/libssl.so.3" "$OUTPUT_DIR/$abi/libssl_3.so"
        fi
        if [ -f "$out_dir/out/lib/libcrypto.so" ]; then
            cp -f "$out_dir/out/lib/libcrypto.so" "$OUTPUT_DIR/$abi/libcrypto_3.so"
        elif [ -f "$out_dir/out/lib/libcrypto.so.3" ]; then
            cp -f "$out_dir/out/lib/libcrypto.so.3" "$OUTPUT_DIR/$abi/libcrypto_3.so"
        fi
    fi

    # Copy static libraries
    if [ "$BUILD_STATIC" = "1" ]; then
        if [ -f "$out_dir/out/lib/libssl.a" ]; then
            cp -f "$out_dir/out/lib/libssl.a" "$OUTPUT_DIR/$abi/"
        fi
        if [ -f "$out_dir/out/lib/libcrypto.a" ]; then
            cp -f "$out_dir/out/lib/libcrypto.a" "$OUTPUT_DIR/$abi/"
        fi
    fi

    echo "Built $abi successfully"
}

want_abi() {
    local abi="$1"
    if [ "${#REQUESTED_ABIS[@]}" -eq 0 ]; then
        return 0
    fi
    for item in "${REQUESTED_ABIS[@]}"; do
        if [ "$item" = "$abi" ]; then
            return 0
        fi
    done
    return 1
}

require_cmd perl
require_cmd make
require_cmd tar

DETECTED_HOST_TAG="$(detect_host_tag)"
if [ -z "$DETECTED_HOST_TAG" ]; then
    echo "Unsupported host OS for Android OpenSSL build." >&2
    exit 1
fi

ANDROID_NDK="$(find_ndk)"
if [ -z "$ANDROID_NDK" ] || [ ! -d "$ANDROID_NDK" ]; then
    echo "Android NDK not found. Set ANDROID_NDK or ANDROID_SDK_ROOT." >&2
    exit 1
fi

# Find actual available host tag in NDK
HOST_TAG="$(find_ndk_host_tag "$ANDROID_NDK" "$DETECTED_HOST_TAG")"
if [ -z "$HOST_TAG" ]; then
    echo "No compatible NDK toolchain found in: $ANDROID_NDK/toolchains/llvm/prebuilt/" >&2
    exit 1
fi

TOOLCHAIN="$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG"
if [ ! -d "$TOOLCHAIN" ]; then
    echo "NDK toolchain not found at: $TOOLCHAIN" >&2
    exit 1
fi

prepare_source

echo "=== Building Android OpenSSL $OPENSSL_VERSION ==="
echo "NDK: $ANDROID_NDK"
echo "API Level: $ANDROID_API_LEVEL"
echo "Build shared: $BUILD_SHARED"
echo "Build static: $BUILD_STATIC"
echo ""

BUILT_ABIS=()

if want_abi "arm64-v8a"; then
    build_one "arm64-v8a" "android-arm64" "aarch64-linux-android"
    BUILT_ABIS+=("arm64-v8a")
fi
if want_abi "armeabi-v7a"; then
    build_one "armeabi-v7a" "android-arm" "armv7a-linux-androideabi"
    BUILT_ABIS+=("armeabi-v7a")
fi
if want_abi "x86_64"; then
    build_one "x86_64" "android-x86_64" "x86_64-linux-android"
    BUILT_ABIS+=("x86_64")
fi
if want_abi "x86"; then
    build_one "x86" "android-x86" "i686-linux-android"
    BUILT_ABIS+=("x86")
fi

echo ""
echo "=== Build Complete ==="
echo "Output directory: $OUTPUT_DIR"
echo "  include/openssl/  - Header files"
for abi in "${BUILT_ABIS[@]}"; do
    echo "  $abi/"
    ls -1 "$OUTPUT_DIR/$abi/" 2>/dev/null | sed 's/^/    /'
done
