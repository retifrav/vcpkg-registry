vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:curl/curl.git
    REF fdb8a789d2b446b77bd7cdd2eff95f6cbc814cf4
    PATCHES
        001-dependencies-and-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        brotli    CURL_BROTLI
        openssl   CURL_USE_OPENSSL
        schannel  CURL_USE_SCHANNEL
        sectransp CURL_USE_SECTRANSP
        ssl       CURL_ENABLE_SSL
        sspi      CURL_WINDOWS_SSPI
        tool      BUILD_CURL_EXE
        zlib      CURL_ZLIB
        zstd      CURL_ZSTD
)

if(
    VCPKG_TARGET_IS_OSX
    AND
    "tool" IN_LIST FEATURES
    AND
    "openssl" IN_LIST FEATURES
)
    message(
        WARNING
            "Enabling OpenSSL on Mac OS might not succeed, because it can get a mess "
            "of OpenSSL resolved via vcpkg and OpenSSL package from Homebrew prefix, "
            "which might then fail on linking, so it is probably advisable to remove "
            "`openssl` from the list of enabled features"
    )
endif()

if("sectransp" IN_LIST FEATURES)
    list(APPEND FEATURE_OPTIONS
        -DCURL_CA_PATH=none
        -DCURL_CA_BUNDLE=none
    )
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND FEATURE_OPTIONS
        -DCURL_DISABLE_TELNET=1
        -DENABLE_UNIX_SOCKETS=0
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND FEATURE_OPTIONS -DENABLE_UNICODE=1)
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" CURL_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" CURL_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_SHARED_LIBS=${CURL_SHARED}
        -DBUILD_STATIC_LIBS=${CURL_STATIC}
        -DBUILD_STATIC_CURL=${CURL_STATIC}
        -DBUILD_LIBCURL_DOCS=0
        -DBUILD_TESTING=0
        -DCURL_CA_FALLBACK=1
        -DCURL_USE_LIBPSL=0
        -DCURL_USE_PKGCONFIG=0
        -DENABLE_CURL_MANUAL=0
        -DHTTP_ONLY=1
)

vcpkg_cmake_install()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES curl AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
