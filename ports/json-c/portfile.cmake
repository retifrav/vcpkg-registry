vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:json-c/json-c.git
    REF 41a55cfcedb54d9c1874f2f0eb07b504091d7e37
    PATCHES
        001-installation.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static"  ENABLE_STATIC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_SHARED_LIBS=${ENABLE_SHARED}
        -DBUILD_STATIC_LIBS=${ENABLE_STATIC}
        -DBUILD_APPS=0
        -DBUILD_TESTING=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
