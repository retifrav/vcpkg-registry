# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:chriskohlhoff/asio.git
    REF 03ae834edbace31a96157b89bf50e5ee464e5ef9
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        coroutine ASIO_COROUTINE
        openssl   ASIO_SSL
        regex     ASIO_REGEX
)

# doesn't seem to be a good way to go about it, instead the project itself
# should be defining `ASIO_STANDALONE`
#if(
#    NOT "coroutine" IN_LIST FEATURES
#    AND
#    NOT "regex" IN_LIST FEATURES
#)
#    # avoiding Boost dependency? What about OpenSSL?
#    vcpkg_replace_string("${SOURCE_PATH}/asio/include/asio/detail/config.hpp"
#        "defined(ASIO_STANDALONE)"
#        "!defined(VCPKG_DISABLE_ASIO_STANDALONE)"
#    )
#endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DASIO_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/asio/LICENSE_1_0.txt")
