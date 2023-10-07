# default values from the original x64-windows-static-md.cmake
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# without this the VCPKG_ROOT environment variable
# won't be available in the chainloaded toolchain
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED VCPKG_ROOT)
#
# overriding default flags to remove /Z7 from Release builds,
# because no one (except Microsoft) needs Debug stuff in Release binaries
#
# this could do with a better path instead of ..
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchains/windows.cmake)
# on Windows VCPKG_CHAINLOAD_TOOLCHAIN_FILE deactivates VS variables,
# so those need to be loaded again
set(VCPKG_LOAD_VCVARS_ENV 1)
