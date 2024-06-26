# even though it can build a shared library and seems to export symbols for DLL,
# projects fail to find required symbols when linking dynamically
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:open-source-parsers/jsoncpp.git
    REF 5defb4ed1a4293b8e2bf641e16b156fb9de498cc
    PATCHES
        001-modern-cmake-version.patch
)

if(NOT VCPKG_TARGET_IS_WINDOWS)
    string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" JSONCPP_SHARED)
endif()
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" JSONCPP_STATIC)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}"     "static" JSONCPP_STATIC_CRT)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DJSONCPP_WITH_CMAKE_PACKAGE=1
        -DJSONCPP_WITH_TESTS=0
        -DJSONCPP_WITH_EXAMPLE=0
        -DJSONCPP_WITH_PKGCONFIG_SUPPORT=0
        -DBUILD_SHARED_LIBS=${JSONCPP_SHARED}
        -DBUILD_STATIC_LIBS=${JSONCPP_STATIC}
        -DBUILD_OBJECT_LIBS=0
        -DJSONCPP_STATIC_WINDOWS_RUNTIME=${JSONCPP_STATIC_CRT}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
