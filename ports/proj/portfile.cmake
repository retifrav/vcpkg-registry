vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:OSGeo/PROJ.git
    REF b24cdfa5ecdcc26bf730a2d5a40fbaaf4e9bcc91
    PATCHES
        001-dependencies-and-installation.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        curl ENABLE_CURL
        tiff ENABLE_TIFF
)

find_program(SQLITE_TOOL
    NAMES "sqlite3"
    PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/sqlite"
    NO_DEFAULT_PATH
    REQUIRED
)

set(PROJ_EMBED_RESOURCE_FILES 0)
if("embed-resource-files" IN_LIST FEATURES)
    set(PROJ_EMBED_RESOURCE_FILES 1)
endif()


vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DEXE_SQLITE3=${SQLITE_TOOL}
        -DNLOHMANN_JSON_ORIGIN="external"
        -DPROJ_DATA_PATH="share/${PORT}/data"
        -DBUILD_TESTING=0
        -DBUILD_APPS=0
        -DINSTALL_LEGACY_CMAKE_FILES=0
        -DEMBED_RESOURCE_FILES=${PROJ_EMBED_RESOURCE_FILES}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    CONFIG_PATH "lib/cmake/${PORT}"
)

# don't enable it back, it will fail to find SQLite and TIFF, need to fix that first,
# but no one uses pkg-config, so
#vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
