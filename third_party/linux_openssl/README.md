Linux OpenSSL 3.0.7 build helper.

Quick build (host architecture):
  ./third_party/linux_openssl/build_linux_openssl.sh

Outputs:
  third_party/linux_openssl/include/openssl/*.h
  third_party/linux_openssl/<arch>/libssl.so
  third_party/linux_openssl/<arch>/libcrypto.so
  third_party/linux_openssl/src/openssl-3.0.7/

Environment overrides:
  OPENSSL_VERSION=3.0.7
  OPENSSL_TARBALL=/path/to/openssl-3.0.7.tar.gz
  TARGET_ARCH=arm64
  CROSS_PREFIX=aarch64-linux-gnu-
  OPENSSL_TARGET=linux-x86_64
  OPENSSL_OUTPUT_ARCH=arm64
  OPENSSL_CONFIG_OPTS="shared no-tests no-apps"
