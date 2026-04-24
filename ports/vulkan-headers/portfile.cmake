vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/Vulkan-Headers.git
    REF b5c8f996196ba4aa6d8f97e52b5d3b6e70f7e4e2 # vulkan-sdk-1.4.341.0
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DVULKAN_HEADERS_ENABLE_TESTS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "VulkanHeaders"
    CONFIG_PATH "share/cmake/VulkanHeaders"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
