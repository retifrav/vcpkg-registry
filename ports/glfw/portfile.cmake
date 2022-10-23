vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:glfw/glfw.git
    REF 45ce5ddd197d5c58f50fdd3296a5131c894e5527
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DGLFW_BUILD_EXAMPLES=0
        -DGLFW_BUILD_TESTS=0
        -DGLFW_BUILD_DOCS=0
)

vcpkg_cmake_install()

# fixing possible problems with imported targets, such as "Policy CMP0111
# is not set: An imported target missing its location property fails during generation" and so on
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "glfw3"
    CONFIG_PATH "lib/cmake/glfw3"
)

#vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE.md"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
