vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/Vulkan-Utility-Libraries.git
    REF 1b07de9a3a174b853833f7f87a824f20604266b9
    PATCHES
        001-dependencies-discovery.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "VulkanUtilityLibraries"
    CONFIG_PATH "lib/cmake/VulkanUtilityLibraries"
)

vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/VulkanUtilityLibraries/VulkanUtilityLibrariesConfig.cmake"
        [=[${PACKAGE_PREFIX_DIR}/lib/cmake/VulkanUtilityLibraries/VulkanUtilityLibraries-targets.cmake]=]
        [=[${CMAKE_CURRENT_LIST_DIR}/VulkanUtilityLibraries-targets.cmake]=]
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
