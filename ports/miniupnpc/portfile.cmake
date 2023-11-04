vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:miniupnp/miniupnp.git
    REF 58837ef586278d18cbebee50be758835ed4be79a
    PATCHES
        friendlyname.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" MINIUPNPC_BUILD_SHARED)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" MINIUPNPC_BUILD_STATIC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/miniupnpc"
    OPTIONS
    -DUPNPC_BUILD_STATIC=${MINIUPNPC_BUILD_STATIC}
    -DUPNPC_BUILD_SHARED=${MINIUPNPC_BUILD_SHARED}
    -DUPNPC_BUILD_TESTS=0
    -DUPNPC_BUILD_SAMPLE=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    CONFIG_PATH "/lib/cmake/${PORT}"
)

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/bin"
        "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
else()
    file(GLOB RELEASE_TOOLS "${CURRENT_PACKAGES_DIR}/bin/*.exe")
    file(GLOB DEBUG_TOOLS "${CURRENT_PACKAGES_DIR}/debug/bin/*.exe")
    file(
        INSTALL ${RELEASE_TOOLS}
        DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
    )
    vcpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    file(REMOVE
        ${RELEASE_TOOLS}
        ${DEBUG_TOOLS}
    )
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
