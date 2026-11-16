# BoringSSL is a replacement for OpenSSL with the same targets and headers
if("boringssl" IN_LIST FEATURES AND "openssl" IN_LIST FEATURES)
    message(
        FATAL_ERROR
            "Can't have both BoringSSL and OpenSSL, you need to choose one"
    )
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:curl/curl.git
    REF 3163ec065643ba20709f190111f42c3e1fe95273
    PATCHES
        001-dependencies-and-installation.patch
        002-wolfssl-bio-retry-flags.patch # until it is fixed upstream
)

# dependencies are supposed to be found via their CMake configs
file(REMOVE
    "${SOURCE_PATH}/CMake/FindBrotli.cmake"
    "${SOURCE_PATH}/CMake/FindNGHTTP2.cmake"
    "${SOURCE_PATH}/CMake/FindWolfSSL.cmake"
    "${SOURCE_PATH}/CMake/FindZstd.cmake"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        boringssl   HAVE_BORINGSSL
        brotli      CURL_BROTLI
        http2       USE_NGHTTP2
        openssl     CURL_CA_FALLBACK
        openssl     CURL_USE_OPENSSL
        ssls-export USE_SSLS_EXPORT
        sspi        CURL_WINDOWS_SSPI
        tool        BUILD_CURL_EXE
        wolfssl     CURL_USE_WOLFSSL
        zlib        CURL_ZLIB
        zstd        CURL_ZSTD
)

if(
    "ssl" IN_LIST FEATURES
    AND
    NOT "http3" IN_LIST FEATURES
    AND
    # `(windows & !uwp) | mingw` to match curl[ssl] platform
    (
        (VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_UWP)
        OR
        VCPKG_TARGET_IS_MINGW
    )
)
    list(APPEND FEATURE_OPTIONS
        -DCURL_USE_SCHANNEL=1
    )
endif()

# since both `boringssl` and `openssl` features are already guarded for,
# it means that `openssl`-specific options are explicitly set to `OFF` in `vcpkg_check_features()`,
# so now we need them set to `ON`/`1`
if("boringssl" IN_LIST FEATURES)
    list(REMOVE_ITEM FEATURE_OPTIONS
        -DCURL_CA_FALLBACK=OFF
        -DCURL_USE_OPENSSL=OFF
    )
    list(APPEND FEATURE_OPTIONS
        "-DCURL_CA_FALLBACK=1" # should this be here too or only for `openssl`?
        "-DCURL_USE_OPENSSL=1"
    )
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND FEATURE_OPTIONS
        -DENABLE_UNIX_SOCKETS=0
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND FEATURE_OPTIONS
        -DENABLE_UNICODE=1
    )
endif()

# static BoringSSL needs C++ runtime, which cURL links as `stdc++` by default,
# but Apple SDKs only have LLVM's `c++`
if(
    "boringssl" IN_LIST FEATURES
    AND
    (VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
)
    list(APPEND FEATURE_OPTIONS
        -D_curl_stdlib_cxx=c++
    )
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" CURL_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" CURL_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_LIBCURL_DOCS=0
        -DBUILD_MISC_DOCS=0
        -DBUILD_SHARED_LIBS=${CURL_SHARED}
        -DBUILD_STATIC_LIBS=${CURL_STATIC}
        -DBUILD_TESTING=0
        # no build host paths baked in. Instead, unless an application sets its own CA (CURLOPT_CAINFO and such),
        # the OS-native CA store is used by default, as if `CURLSSLOPT_NATIVE_CA` (`--ca-native` for the tool)
        # was set, where the backend supports that: `wolfssl`, and `openssl`/`boringssl` on Windows (Schannel
        # always uses it anyway). Elsewhere `openssl`/`boringssl` have `CURL_CA_FALLBACK`, which defers to OpenSSL
        # default paths at runtime. On Windows this also turns `CURL_DISABLE_CA_SEARCH` on, so there is no (unsafe)
        # search for `curl-ca-bundle.crt` in `PATH`
        -DCURL_CA_BUNDLE=none
        -DCURL_CA_NATIVE=1
        -DCURL_CA_PATH=none
        # HTTP(S) and WS(S) only. Before 8.23.0 that was `HTTP_ONLY`, which upstream dropped,
        # and these are the protocols it used to disable (except for SMB, which is gone for good)
        -DCURL_DISABLE_DICT=1
        -DCURL_DISABLE_FILE=1
        -DCURL_DISABLE_FTP=1
        -DCURL_DISABLE_GOPHER=1
        -DCURL_DISABLE_IMAP=1
        -DCURL_DISABLE_IPFS=1
        -DCURL_DISABLE_LDAP=1
        -DCURL_DISABLE_LDAPS=1
        -DCURL_DISABLE_MQTT=1
        -DCURL_DISABLE_POP3=1
        -DCURL_DISABLE_RTSP=1
        -DCURL_DISABLE_SMTP=1
        -DCURL_DISABLE_TELNET=1
        -DCURL_DISABLE_TFTP=1
        -DCURL_USE_LIBPSL=0 # should be a feature?
        -DCURL_USE_LIBSSH2=0 # should be a feature
        -DCURL_USE_LIBSSH=0 # should be a feature
        -DCURL_USE_PKGCONFIG=0
        -DENABLE_CURL_MANUAL=0
        -DSHARE_LIB_OBJECT=0
        -DUSE_APPLE_IDN=0 # should be a feature?
        -DUSE_LIBIDN2=0 # should be a feature?
    MAYBE_UNUSED_VARIABLES
        _curl_stdlib_cxx
        HAVE_BORINGSSL
)

vcpkg_cmake_install()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES curl AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
