vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/OpenXR-SDK.git
    REF 8899a91c17ce9618f565f42408b47db1d6e9ccc7
    PATCHES
        not-hardcoding-crt-linking.patch
        jsoncpp-discovery.patch
)

set(DYNAMIC_LOADER 0)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(DYNAMIC_LOADER 1)
endif()

vcpkg_find_acquire_program(PYTHON3)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DPYTHON_EXECUTABLE="${PYTHON3}"
        -DDYNAMIC_LOADER=${DYNAMIC_LOADER}
        -DBUILD_TESTS=0
        -DBUILD_CONFORMANCE_TESTS=0
)

vcpkg_cmake_install()

if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "OpenXR"
        CONFIG_PATH "cmake"
    )
else()
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "OpenXR"
        CONFIG_PATH "lib/cmake/openxr"
    )
endif()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
