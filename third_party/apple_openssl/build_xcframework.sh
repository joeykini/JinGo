#!/bin/bash
# Build OpenSSL XCFramework for all Apple platforms
# Supports: iOS device (arm64), iOS simulator (arm64, x86_64), macOS (arm64, x86_64)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR"

OPENSSL_VERSION="${OPENSSL_VERSION:-3.0.7}"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
SRC_DIR="$BUILD_DIR/openssl-${OPENSSL_VERSION}"
TARBALL="$BUILD_DIR/android_openssl_${OPENSSL_VERSION}.tar.gz"
LOCAL_TARBALL="$SCRIPT_DIR/openssl-${OPENSSL_VERSION}.tar.gz"

MACOS_MIN="11.0"
IOS_MIN="13.0"
NCPU=$(sysctl -n hw.ncpu)

echo "=========================================="
echo "Building OpenSSL $OPENSSL_VERSION XCFramework"
echo "=========================================="
echo ""

download_openssl() {
    mkdir -p "$BUILD_DIR"

    # Check for local tarball first
    if [[ -f "$LOCAL_TARBALL" ]]; then
        echo ">>> Using local tarball: $LOCAL_TARBALL"
        cp "$LOCAL_TARBALL" "$TARBALL"
    elif [[ -f "$TARBALL" ]]; then
        echo ">>> Using cached tarball: $TARBALL"
    else
        echo ">>> Downloading OpenSSL ${OPENSSL_VERSION}..."
        curl -L --connect-timeout 30 -o "$TARBALL" "$OPENSSL_URL"
    fi

    if [[ -d "$SRC_DIR" ]]; then
        rm -rf "$SRC_DIR"
    fi

    echo ">>> Extracting OpenSSL..."
    tar -xzf "$TARBALL" -C "$BUILD_DIR"
}

build_openssl() {
    local NAME="$1"
    local TARGET="$2"
    local DIR="$BUILD_DIR/$NAME"

    echo ">>> Building $NAME..."
    rm -rf "$DIR"
    mkdir -p "$DIR"

    cd "$SRC_DIR"
    make clean 2>/dev/null || true

    ./Configure "$TARGET" \
        --prefix="$DIR" \
        --openssldir="$DIR" \
        no-shared \
        no-tests \
        no-async > /dev/null 2>&1

    make -j$NCPU > /dev/null 2>&1
    make install_sw > /dev/null 2>&1

    echo "    $NAME complete"
}

build_macos_arm64() {
    local SDK=$(xcrun --sdk macosx --show-sdk-path)
    export CFLAGS="-isysroot $SDK -mmacosx-version-min=$MACOS_MIN"
    export LDFLAGS="-isysroot $SDK"
    build_openssl "macos-arm64" "darwin64-arm64-cc"
    unset CFLAGS LDFLAGS
}

build_macos_x86_64() {
    local SDK=$(xcrun --sdk macosx --show-sdk-path)
    export CFLAGS="-isysroot $SDK -mmacosx-version-min=$MACOS_MIN"
    export LDFLAGS="-isysroot $SDK"
    build_openssl "macos-x86_64" "darwin64-x86_64-cc"
    unset CFLAGS LDFLAGS
}

build_ios_device() {
    local SDK=$(xcrun --sdk iphoneos --show-sdk-path)
    export CC="$(xcrun --sdk iphoneos --find clang)"
    export CFLAGS="-isysroot $SDK -mios-version-min=$IOS_MIN"
    export LDFLAGS="-isysroot $SDK"
    export CROSS_TOP="$(xcode-select --print-path)/Platforms/iPhoneOS.platform/Developer"
    export CROSS_SDK="iPhoneOS.sdk"
    build_openssl "ios-device" "ios64-xcrun"
    unset CC CFLAGS LDFLAGS CROSS_TOP CROSS_SDK
}

build_ios_sim_arm64() {
    local SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
    export CC="$(xcrun --sdk iphonesimulator --find clang)"
    export CFLAGS="-arch arm64 -isysroot $SDK -mios-simulator-version-min=$IOS_MIN -target arm64-apple-ios${IOS_MIN}-simulator"
    export LDFLAGS="-arch arm64 -isysroot $SDK"
    build_openssl "ios-sim-arm64" "iossimulator-xcrun"
    unset CC CFLAGS LDFLAGS
}

build_ios_sim_x86_64() {
    local SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
    export CC="$(xcrun --sdk iphonesimulator --find clang)"
    export CFLAGS="-arch x86_64 -isysroot $SDK -mios-simulator-version-min=$IOS_MIN -target x86_64-apple-ios${IOS_MIN}-simulator"
    export LDFLAGS="-arch x86_64 -isysroot $SDK"
    build_openssl "ios-sim-x86_64" "iossimulator-xcrun"
    unset CC CFLAGS LDFLAGS
}

create_fat_libraries() {
    echo ""
    echo ">>> Creating fat libraries..."

    mkdir -p "$BUILD_DIR/macos/lib"
    lipo -create \
        "$BUILD_DIR/macos-arm64/lib/libcrypto.a" \
        "$BUILD_DIR/macos-x86_64/lib/libcrypto.a" \
        -output "$BUILD_DIR/macos/lib/libcrypto.a"
    lipo -create \
        "$BUILD_DIR/macos-arm64/lib/libssl.a" \
        "$BUILD_DIR/macos-x86_64/lib/libssl.a" \
        -output "$BUILD_DIR/macos/lib/libssl.a"
    echo "    macOS universal complete"

    mkdir -p "$BUILD_DIR/ios-simulator/lib"
    lipo -create \
        "$BUILD_DIR/ios-sim-arm64/lib/libcrypto.a" \
        "$BUILD_DIR/ios-sim-x86_64/lib/libcrypto.a" \
        -output "$BUILD_DIR/ios-simulator/lib/libcrypto.a"
    lipo -create \
        "$BUILD_DIR/ios-sim-arm64/lib/libssl.a" \
        "$BUILD_DIR/ios-sim-x86_64/lib/libssl.a" \
        -output "$BUILD_DIR/ios-simulator/lib/libssl.a"
    echo "    iOS Simulator universal complete"
}

create_xcframeworks() {
    echo ""
    echo ">>> Copying headers..."
    mkdir -p "$OUTPUT_DIR/include"
    rm -rf "$OUTPUT_DIR/include/openssl"
    cp -r "$BUILD_DIR/macos-arm64/include/openssl" "$OUTPUT_DIR/include/"

    echo ">>> Creating libcrypto.xcframework..."
    rm -rf "$OUTPUT_DIR/libcrypto.xcframework"
    xcodebuild -create-xcframework \
        -library "$BUILD_DIR/macos/lib/libcrypto.a" \
        -library "$BUILD_DIR/ios-device/lib/libcrypto.a" \
        -library "$BUILD_DIR/ios-simulator/lib/libcrypto.a" \
        -output "$OUTPUT_DIR/libcrypto.xcframework"

    echo ">>> Creating libssl.xcframework..."
    rm -rf "$OUTPUT_DIR/libssl.xcframework"
    xcodebuild -create-xcframework \
        -library "$BUILD_DIR/macos/lib/libssl.a" \
        -library "$BUILD_DIR/ios-device/lib/libssl.a" \
        -library "$BUILD_DIR/ios-simulator/lib/libssl.a" \
        -output "$OUTPUT_DIR/libssl.xcframework"
}

show_result() {
    echo ""
    echo "=========================================="
    echo "Build Complete!"
    echo "=========================================="
    echo ""
    for lib in "$OUTPUT_DIR/libcrypto.xcframework"/*/*.a; do
        if [[ -f "$lib" ]]; then
            local platform=$(dirname "$lib" | xargs basename)
            echo "  $platform: $(lipo -archs "$lib")"
        fi
    done
    echo ""
    du -sh "$OUTPUT_DIR/libcrypto.xcframework"
    du -sh "$OUTPUT_DIR/libssl.xcframework"
}

# Main
download_openssl
build_macos_arm64
build_macos_x86_64
build_ios_device
build_ios_sim_arm64
build_ios_sim_x86_64
create_fat_libraries
create_xcframeworks
show_result

echo ""
echo ">>> Cleaning up build directory..."
if [[ -f "$TARBALL" ]]; then
    find "$BUILD_DIR" -mindepth 1 -maxdepth 1 ! -name "$(basename "$TARBALL")" -exec rm -rf {} +
else
    rm -rf "$BUILD_DIR"
fi
