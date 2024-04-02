# one can try to transform the proper SemVer value into SQLite's version string,
# but that doesn't look great, plus there is still an unpredicted year value in the URL,
# and also SHA512 value still needs to be set manually
# string(REGEX REPLACE
#     "^([0-9]+)[.]([0-9]+)[.]([0-9]+)[.]([0-9]+)"
#     "\\1,0\\2,0\\3,0\\4,"
#     SQLITE_VERSION_VALUE
#     "${VERSION}.0"
# )
# string(REGEX REPLACE
#     "^([0-9]+),0*([0-9][0-9]),0*([0-9][0-9]),0*([0-9][0-9]),"
#     "\\1\\2\\3\\4"
#     SQLITE_VERSION_VALUE
#     "${SQLITE_VERSION_VALUE}"
# )
# what genius had the idea to put year into URL
set(SQLITE_VERSION_YEAR "2024")
# is it the same genius who came up with this version string format
set(SQLITE_VERSION_VALUE "3450200")
# download the file yourself first and get its hash with sha512sum
set(SQLITE_VERSION_HASH "7541c05cdb5954d37a45e5ca29fed7c5cbb53e65f0683cad7f7307564f470280574ca49acb3b637f4f5d82bb99e6ba28076826f9e8f6b28ad7e6bb96d01885cd")

vcpkg_download_distfile(
    ARCHIVE
    URLS "https://sqlite.org/${SQLITE_VERSION_YEAR}/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    FILENAME "sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    SHA512 ${SQLITE_VERSION_HASH}
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        recommended-options SQLITE_RECOMMENDED_OPTIONS
        column-metadata SQLITE_ENABLE_COLUMN_METADATA
        dbstat-vtab SQLITE_ENABLE_DBSTAT_VTAB
        fts3 SQLITE_ENABLE_FTS3
        fts4 SQLITE_ENABLE_FTS4
        fts5 SQLITE_ENABLE_FTS5
        geopoly SQLITE_ENABLE_GEOPOLY
        icu SQLITE_ENABLE_ICU
        math SQLITE_ENABLE_MATH_FUNCTIONS
        rbu SQLITE_ENABLE_RBU
        rtree SQLITE_ENABLE_RTREE
        stat4 SQLITE_ENABLE_STAT4
        omit-decltype SQLITE_OMIT_DECLTYPE
        omit-json SQLITE_OMIT_JSON
        use-uri SQLITE_USE_URI
        tool BUILD_SQLITE_TOOL
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "sqlite3"
    CONFIG_PATH "share/sqlite3"
)

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES sqlite3 AUTO_CLEAN)
    # the tool installation is only enabled in Release configuration
    # file(REMOVE
    #     "${CURRENT_PACKAGES_DIR}/debug/bin/sqlite3d"     # non-Windows
    #     "${CURRENT_PACKAGES_DIR}/debug/bin/sqlite3d.exe" # Windows
    # )
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/license.md")
