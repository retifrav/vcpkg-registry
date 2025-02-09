vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:OSGeo/PROJ.git
    REF 7cd00d0b2ca594315acd6c76912df39be4607094
    PATCHES
        001-dependencies-discovery.patch
        002-installation.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tiff ENABLE_TIFF
        curl ENABLE_CURL
)

find_program(SQLITE_TOOL
    NAMES "sqlite3"
    PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/sqlite"
    NO_DEFAULT_PATH
    REQUIRED
)

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
