vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:apache/xerces-c.git
    REF 5052c90b067dcc347d58822b450897d16e2c31e5
    PATCHES
        dependencies.patch
        disable-tests-samples-docs-pkg.patch
        remove-dll-export-macro.patch
        unified-cmake-install-path.patch
        file-manager-uwp.patch # https://gitlab.linphone.org/BC/public/external/xerces-c/-/merge_requests/4
)
file(REMOVE "${SOURCE_PATH}/cmake/FindICU.cmake")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        network network
        transcoder-icu CMAKE_REQUIRE_FIND_PACKAGE_ICU
)

if("transcoder-icu" IN_LIST FEATURES)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=icu")
elseif("transcoder-iconv" IN_LIST FEATURES) # OR VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_ANDROID OR VCPKG_HOST_IS_OSX
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=iconv")
# elseif(VCPKG_HOST_IS_OSX) # OR "transcoder-iconv" IN_LIST FEATURES
#     # because of a bug in the transcoder selection script, the option
#     # `macosunicodeconverter` is always selected when building on Mac OS,
#     # regardless of the target platform, and that breaks cross-compiling.
#     # As a workaround we force `iconv`, which should at least work for iOS.
#     # Upstream fix: https://github.com/apache/xerces-c/pull/52
#     vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=iconv")
elseif(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=windows")
elseif(VCPKG_TARGET_IS_OSX)
    vcpkg_list(APPEND FEATURE_OPTIONS "-Dtranscoder=macosunicodeconverter")
else()
    # it chooses gnuiconv or iconv in ./cmake/XercesTranscoderSelection.cmake
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
