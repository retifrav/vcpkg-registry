vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:curl/curl.git
    REF 45ac4d019475df03562fe0ac54eb67e1d1de0ca7
    PATCHES
        installation.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        #openssl   CURL_USE_OPENSSL # for that openssl feature needs to be added to curl port manifest (and also openssl port needs to exist), check Microsoft's port for an example
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
