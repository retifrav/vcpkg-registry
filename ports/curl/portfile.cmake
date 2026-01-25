vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:curl/curl.git
    REF 2eebc58c4b8d68c98c8344381a9f6df4cca838fd
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
        brotli      CURL_BROTLI
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
    ((VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_UWP) OR VCPKG_TARGET_IS_MINGW))
    list(APPEND FEATURE_OPTIONS
        -DCURL_USE_SCHANNEL=1
    )
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND FEATURE_OPTIONS
        -DCURL_DISABLE_TELNET=1
        -DENABLE_UNIX_SOCKETS=0
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND FEATURE_OPTIONS
        -DENABLE_UNICODE=1
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
        -DBUILD_STATIC_CURL=${CURL_STATIC}
        -DBUILD_STATIC_LIBS=${CURL_STATIC}
        -DBUILD_TESTING=0
        -DCURL_USE_LIBPSL=0
        -DCURL_USE_PKGCONFIG=0
        -DENABLE_CURL_MANUAL=0
        -DHTTP_ONLY=1
        -DSHARE_LIB_OBJECT=0
)

vcpkg_cmake_install()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES curl AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
