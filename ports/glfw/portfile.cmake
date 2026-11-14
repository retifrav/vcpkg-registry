vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:glfw/glfw.git
    REF d9d6f0f1f967807ffade6598ea9a631ebaf37a56
    PATCHES
        001-disable-pkgconfig.patch
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

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
