vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:nghttp2/nghttp2.git
    REF 85e300c79fb6dbcfa9c1013215c8710c1c2cd3d2
    PATCHES
        001-single-target.patch
)

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" ENABLE_STATIC_CRT)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" ENABLE_STATIC_LIB)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        # BUILD_SHARED_LIBS is set (or not set) by vcpkg, no need to set it again
        -DBUILD_STATIC_LIBS=${ENABLE_STATIC_LIB}
        -DENABLE_STATIC_CRT=${ENABLE_STATIC_CRT}
        -DBUILD_TESTING=0
        -DCMAKE_DISABLE_FIND_PACKAGE_Jansson=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Jemalloc=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Libevent=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Libnghttp3=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Libngtcp2=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Libngtcp2_crypto_quictls=1
        -DCMAKE_DISABLE_FIND_PACKAGE_LibXml2=1
        -DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Python3=1
        -DCMAKE_DISABLE_FIND_PACKAGE_Systemd=1
        -DENABLE_DOC=0
        -DENABLE_LIB_ONLY=1
    MAYBE_UNUSED_VARIABLES
        CMAKE_DISABLE_FIND_PACKAGE_Libngtcp2_crypto_quictls
        ENABLE_STATIC_CRT
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(APPEND "${CURRENT_PACKAGES_DIR}/include/nghttp2/nghttp2ver.h" [[
#ifndef NGHTTP2_STATICLIB
#  define NGHTTP2_STATICLIB
#endif
]])
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
