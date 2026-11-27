# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:yhirose/cpp-httplib.git
    REF 7800c3dc5b33285cbb18baa5998de4ff7ef63515
    PATCHES
        001-dependencies-and-installation.patch
)

# dependencies are supposed to be found via their CMake configs
file(REMOVE "${SOURCE_PATH}/cmake/FindBrotli.cmake")

file(
    COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(
    COPY "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        brotli  HTTPLIB_REQUIRE_BROTLI
        openssl HTTPLIB_REQUIRE_OPENSSL
        zlib    HTTPLIB_REQUIRE_ZLIB
        zstd    HTTPLIB_REQUIRE_ZSTD
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        # dependencies are enabled by the features only, nothing is to be used
        # just because it happens to be installed (most of these are enabled by default)
        -DHTTPLIB_USE_BROTLI_IF_AVAILABLE=0
        -DHTTPLIB_USE_MBEDTLS_IF_AVAILABLE=0
        -DHTTPLIB_USE_OPENSSL_IF_AVAILABLE=0
        -DHTTPLIB_USE_WOLFSSL_IF_AVAILABLE=0
        -DHTTPLIB_USE_ZLIB_IF_AVAILABLE=0
        -DHTTPLIB_USE_ZSTD_IF_AVAILABLE=0
        # OpenSSL is the only TLS back end here, there is no MbedTLS port in this registry,
        # and wolfSSL lacks `OPENSSL_ALL` (see _notes.md)
        -DHTTPLIB_REQUIRE_MBEDTLS=0
        -DHTTPLIB_REQUIRE_WOLFSSL=0
        # the patch covers only the header-only variant (see _notes.md)
        -DHTTPLIB_COMPILE=0
        -DHTTPLIB_BUILD_MODULES=0
        -DHTTPLIB_TEST=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
