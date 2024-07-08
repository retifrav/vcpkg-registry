vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:paullouisageneau/libdatachannel.git
    REF a0598f214b46217dd709f09522c601d5bc94b518
    PATCHES
        001-dependencies-and-installation.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DNO_EXAMPLES=1
        -DNO_TESTS=1
        -DPREFER_SYSTEM_LIB=0
        -DUSE_NETTLE=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
