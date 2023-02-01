vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:apache/xerces-c.git
    REF cf1912ac95d4147be08aef4e78f894a3919277d9
    PATCHES
        disabling-docs-samples-tests.patch
        unified-cmake-install-path.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        network network
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

set(ACTUAL_PACKAGE_NAME "XercesC")

vcpkg_cmake_config_fixup(
    PACKAGE_NAME ${ACTUAL_PACKAGE_NAME}
    CONFIG_PATH "lib/cmake/${ACTUAL_PACKAGE_NAME}"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${CURRENT_PORT_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${ACTUAL_PACKAGE_NAME}"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
