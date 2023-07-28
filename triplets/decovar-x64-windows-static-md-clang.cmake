set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_PLATFORM_TOOLSET ClangCL)

# otherwise these environment variables won't be available in the chainloaded toolchain
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED LLVMInstallDir LLVMToolsVersion)
# finding and setting C/CXX compiler to Clang
# this could do with a better path instead of ..
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchains/windows-clang.cmake)
# on Windows VCPKG_CHAINLOAD_TOOLCHAIN_FILE deactivates automatic VS variables, so those need to be loaded again
set(VCPKG_LOAD_VCVARS_ENV 1)

# not sure if these are needed
#set(VCPKG_POLICY_SKIP_ARCHITECTURE_CHECK enabled)
#set(VCPKG_POLICY_SKIP_DUMPBIN_CHECKS enabled)
