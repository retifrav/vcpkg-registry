vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:fmtlib/fmt.git
    REF e69e5f977d458f2650bb346dadf2ad30c5320281
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DFMT_TEST=0
        -DFMT_DOC=0
        -DFMT_CMAKE_DIR="share/fmt"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
