vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:fmtlib/fmt.git
    REF 0c9fce2ffefecfdce794e1859584e25877b7b592
    PATCHES
        001-utf-only-for-msvc.patch
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

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
