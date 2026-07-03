vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/SPIRV-Headers.git
    REF ad9184e76a66b1001c29db9b0a3e87f646c64de0 # vulkan-sdk-1.4.350.0 # vulkan-sdk-1.4.350.1
    PATCHES
        001-versions.patch
)

# vcpkg_find_acquire_program(PYTHON3)
# get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
# vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DSPIRV_HEADERS_VERSION="${VERSION}"
        -DSPIRV_HEADERS_ENABLE_TESTS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Headers"
    CONFIG_PATH "share/cmake/SPIRV-Headers"
)

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
