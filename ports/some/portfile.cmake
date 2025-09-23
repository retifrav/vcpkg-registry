vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:retifrav/cmake-library-example.git
    REF fb463aa8fe49d1d316faba8b48b01676d053593c
    PATCHES
        001-dynamic-library.patch
        002-installation.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/internal-project/libraries/SomeLibrary"
    OPTIONS
        -DPRINT_SOME_SILLY_THING=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
