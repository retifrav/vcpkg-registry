vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/brotli.git
    REF e61745a6b7add50d380cfd7d3883dd6c62fc2c71
    PATCHES
        split-debug-release-and-export-config.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBROTLI_BUNDLED_MODE=0
        -DBROTLI_DISABLE_TESTS=1
        # fascinating enough, even if you are in fact targeting Emscripten,
        # this still needs to be turned off, otherwise it won't install stuff
        -DBROTLI_EMSCRIPTEN=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
