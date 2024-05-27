# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:gulrak/filesystem.git
    REF 8a2edd6d92ed820521d42c94d179462bf06b5ed3
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DGHC_FILESYSTEM_BUILD_EXAMPLES=0
        -DGHC_FILESYSTEM_BUILD_STD_TESTING=0
        -DGHC_FILESYSTEM_BUILD_TESTING=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "ghc_filesystem"
    CONFIG_PATH "lib/cmake/ghc_filesystem"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
