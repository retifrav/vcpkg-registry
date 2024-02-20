vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/brotli.git
    REF ed738e842d2fbdf2d6459e39267a633c4a9b2f5d
    PATCHES
        installation.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools BROTLI_BUILD_TOOLS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBROTLI_BUNDLED_MODE=0
        -DBROTLI_DISABLE_TESTS=1
        # fascinating enough, even if you are in fact targeting Emscripten,
        # this still needs to be turned off, otherwise it won't install stuff
        -DBROTLI_EMSCRIPTEN=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
