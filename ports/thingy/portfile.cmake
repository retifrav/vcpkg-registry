vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:retifrav/cmake-target-link-libraries-example.git
    REF 7ec26bb06614707302b66dc4a65601c0594da442
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/dpndnc"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME "Thingy")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
