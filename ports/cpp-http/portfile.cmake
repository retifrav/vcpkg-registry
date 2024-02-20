vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:yhirose/cpp-httplib.git
    REF 5c00bbf36ba8ff47b4fb97712fc38cb2884e5b98
    PATCHES
        dependencies-discovery-and-installation.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tests HTTPLIB_TEST
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DHTTPLIB_REQUIRE_BROTLI=1
        -DHTTPLIB_REQUIRE_ZLIB=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
