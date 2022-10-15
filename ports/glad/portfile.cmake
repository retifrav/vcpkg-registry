vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:Dav1dde/glad.git
    REF 1ecd45775d96f35170458e6b148eb0708967e402
)

vcpkg_find_acquire_program(PYTHON3)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DPYTHON_EXECUTABLE=${PYTHON3}
        -DGLAD_API="gl="
        -DGLAD_REPRODUCIBLE=1
        -DGLAD_INSTALL=1
)

vcpkg_cmake_install()

# fixing possible problems with imported targets, such as "Policy CMP0111
# is not set: An imported target missing its location property fails during generation" and so on
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

#vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
