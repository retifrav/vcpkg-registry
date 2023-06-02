vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:curl/curl.git
    REF 7ab9d43720bc34d9aa351c7ca683c1668ebf8335
    PATCHES
        installation-and-targets.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        openssl   CURL_USE_OPENSSL # although OpenSSL port is missing at the moment
        openssl   USE_OPENSSL # this one is never declared, only set to ON if CURL_USE_OPENSSL is set
        sspi      CURL_WINDOWS_SSPI
        schannel  CURL_USE_SCHANNEL
        sectransp CURL_USE_SECTRANSP
        tool      BUILD_CURL_EXE
)

if("sectransp" IN_LIST FEATURES)
    list(APPEND FEATURE_OPTIONS
        -DCURL_CA_PATH=none
        -DCURL_CA_BUNDLE=none
    )
endif()

if(VCPKG_TARGET_IS_UWP)
    list(APPEND FEATURE_OPTIONS
        -DCURL_DISABLE_TELNET=1
        -DENABLE_IPV6=0
        -DENABLE_UNIX_SOCKETS=0
    )
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND FEATURE_OPTIONS -DENABLE_UNICODE=1)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_TESTING=0
        -DENABLE_MANUAL=0
        -DCURL_CA_FALLBACK=1
        -DCURL_USE_LIBPSL=0
)

vcpkg_cmake_install()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES curl AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/COPYING"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
