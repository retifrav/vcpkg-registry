set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES "arm64;x86_64")

#set(VCPKG_ENV_PASSTHROUGH_UNTRACKED VCPKG_ROOT)
# unlike fat iOS toolchain, this one has no effect (but `VCPKG_OSX_ARCHITECTURES` does)
# so there is actually no `osx-fat.cmake` toolchain (as it wouldn't do anything useful at the moment)
#set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchains/osx-fat.cmake)
