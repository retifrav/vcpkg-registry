if(
    EXISTS "${CURRENT_INSTALLED_DIR}/share/libressl/copyright"
    OR
    EXISTS "${CURRENT_INSTALLED_DIR}/share/boringssl/copyright"
)
    message(FATAL_ERROR "Can't build OpenSSL if LibreSSL/BoringSSL is installed. You need to remove those before installing OpenSSL")
endif()

if(VCPKG_TARGET_IS_EMSCRIPTEN)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

if (NOT "${VERSION}" MATCHES [[^([0-9]+)\.([0-9]+)\.([0-9]+)$]])
    message(FATAL_ERROR "Version regex did not match.")
endif()
set(OPENSSL_VERSION_MAJOR "${CMAKE_MATCH_1}")
set(OPENSSL_VERSION_MINOR "${CMAKE_MATCH_2}")
set(OPENSSL_VERSION_FIX "${CMAKE_MATCH_3}")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake.in"
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake"
    @ONLY
)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:openssl/openssl.git
    REF 01d5e2318405362b4de5e670c90d9b40a351d053 # "openssl-${VERSION}"
    PATCHES
        disable-apps.patch
        disable-install-docs.patch
        script-prefix.patch
        windows/install-layout.patch
        windows/install-pdbs.patch
        unix/android-cc.patch
        unix/move-openssldir.patch
        unix/no-empty-dirs.patch
        unix/no-static-libs-for-shared.patch
)

vcpkg_list(SET CONFIGURE_OPTIONS
    enable-static-engine
    enable-capieng
    no-ssl3
    no-weak-ssl-ciphers
    no-tests
)

set(INSTALL_FIPS "")
if("fips" IN_LIST FEATURES)
    vcpkg_list(APPEND INSTALL_FIPS install_fips)
    vcpkg_list(APPEND CONFIGURE_OPTIONS enable-fips)
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_list(APPEND CONFIGURE_OPTIONS shared)
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-shared no-module)
endif()

if(NOT "tools" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-apps)
endif()

if(DEFINED OPENSSL_USE_NOPINSHARED)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-pinshared)
endif()

if(OPENSSL_NO_AUTOLOAD_CONFIG)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-autoload-config)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    include("${CMAKE_CURRENT_LIST_DIR}/windows/portfile.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/install-pc-files.cmake")
else()
    include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
