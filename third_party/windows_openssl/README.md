Windows OpenSSL 3.0.7 build helper.

Run in "x64 Native Tools Command Prompt for VS" (or ensure cl/nmake in PATH):
  powershell -ExecutionPolicy Bypass -File .\\third_party\\windows_openssl\\build_windows_openssl.ps1

Outputs:
  third_party/windows_openssl/include/openssl/*.h
  third_party/windows_openssl/x64/libssl.lib
  third_party/windows_openssl/x64/libcrypto.lib
  third_party/windows_openssl/x64/libssl-3*.dll
  third_party/windows_openssl/x64/libcrypto-3*.dll
  third_party/windows_openssl/src/openssl-3.0.7/

MSYS2 构建（MinGW 版本）

Run inside msys2 shell with mingw toolchain:
  ARCH=x64 ./third_party/windows_openssl/build_windows_openssl_msys2.sh

Outputs in architecture folder with `.a` + `.dll`.

Environment overrides:
  OPENSSL_TARBALL=C:\\path\\to\\openssl-3.0.7.tar.gz
  OPENSSL_CONFIG_OPTS="no-tests no-apps shared"
