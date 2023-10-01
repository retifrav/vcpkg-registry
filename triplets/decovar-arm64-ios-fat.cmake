set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME iOS)
# to make a Mach-O combined/fat/universal binary, one needs to set both architectures,
# either here with `VCPKG_OSX_ARCHITECTURES` or in the chainloaded toolchain with `CMAKE_OSX_ARCHITECTURES`
set(VCPKG_OSX_ARCHITECTURES "arm64;x86_64")

# without this the VCPKG_ROOT environment variable won't be available in the chainloaded toolchain
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED VCPKG_ROOT)
# setting Xcode attributes for specifying device/simulator architectures
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchains/ios-fat.cmake)
