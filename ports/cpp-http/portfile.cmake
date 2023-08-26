vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:yhirose/cpp-httplib.git
    REF f2f47284890e9ed1ab1750a21c06441bdd5fcb6c
    PATCHES
        dependencies-discovery-installation.patch
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

vcpkg_cmake_config_fixup(PACKAGE_NAME "httplib")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
