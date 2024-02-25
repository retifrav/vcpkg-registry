vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:glfw/glfw.git
    REF 7b6aead9fb88b3623e3b3725ebb42670cbe4c579
    PATCHES
        disable-pkgconfig.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DGLFW_BUILD_EXAMPLES=0
        -DGLFW_BUILD_TESTS=0
        -DGLFW_BUILD_DOCS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "glfw3"
    CONFIG_PATH "lib/cmake/glfw3"
)

#vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
