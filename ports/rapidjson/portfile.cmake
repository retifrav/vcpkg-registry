# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:Tencent/rapidjson.git
    REF ab1842a2dae061284c0a62dca1cc6d5e7e37e346
    PATCHES
        installation.patch
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
        -DRAPIDJSON_BUILD_CXX11=0
        -DRAPIDJSON_BUILD_CXX17=1
        -DRAPIDJSON_BUILD_CXX20=0
        -DRAPIDJSON_BUILD_DOC=0
        -DRAPIDJSON_BUILD_EXAMPLES=0
        -DRAPIDJSON_BUILD_TESTS=0
        -DRAPIDJSON_BUILD_THIRDPARTY_GTEST=0
        -DRAPIDJSON_ENABLE_INSTRUMENTATION_OPT=1
        -DRAPIDJSON_HAS_STDSTRING=0
        -DRAPIDJSON_USE_MEMBERSMAP=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME "RapidJSON")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/license.txt")
