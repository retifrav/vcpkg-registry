vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:apache/xerces-c.git
    REF 5052c90b067dcc347d58822b450897d16e2c31e5
    PATCHES
        dependencies.patch
        disable-tests-samples-docs-pkg.patch
        remove-dll-export-macro.patch
        unified-cmake-install-path.patch
)
file(REMOVE "${SOURCE_PATH}/cmake/FindICU.cmake")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        network network
        icu CMAKE_REQUIRE_FIND_PACKAGE_ICU
)

if("icu" IN_LIST FEATURES)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=icu")
elseif(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=windows")
elseif(VCPKG_TARGET_IS_OSX)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=macosunicodeconverter")
else()
    # it chooses gnuiconv or iconv in ./cmake/XercesTranscoderSelection.cmake
    # so you might need to add iconv to dependencies in vcpkg.json:
    # {
    #     "name": "iconv",
    #     "platform": "!windows & !osx"
    # }
endif()

if("xmlch-wchar" IN_LIST FEATURES)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dxmlch-type=wchar_t")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDISABLE_TESTS=1
        -DDISABLE_SAMPLES=1
        -DDISABLE_DOC=1
        -DDISABLE_PKG=1
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
