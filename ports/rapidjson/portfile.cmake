# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:Tencent/rapidjson.git
    REF 24b5e7a8b27f42fa16b96fc70aade9106cf7102f
    PATCHES
        001-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DRAPIDJSON_BUILD_DOC=0
        -DRAPIDJSON_BUILD_EXAMPLES=0
        -DRAPIDJSON_BUILD_TESTS=0
        -DRAPIDJSON_BUILD_THIRDPARTY_GTEST=0
        -DRAPIDJSON_ENABLE_INSTRUMENTATION_OPT=1
        -DRAPIDJSON_HAS_STDSTRING=1
        -DRAPIDJSON_USE_MEMBERSMAP=0
        -DRAPIDJSON_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME "RapidJSON")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/license.txt")
