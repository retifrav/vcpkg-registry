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
set(SQLITE_VERSION_YEAR "2023")
# is it the same genius who came up with this version string format
set(SQLITE_VERSION_VALUE "3410000")
# download the file yourself first and get its hash with sha512sum
set(SQLITE_VERSION_HASH "0280218058789e97a9ec874c8631aaa0a2b700ed040e5a721b5ccec411fe3cde81b55c7a94766c510e20044a3b1271204b98cde1d8451c4c0455b0aff630e88a")

vcpkg_download_distfile(ARCHIVE
    URLS "https://sqlite.org/${SQLITE_VERSION_YEAR}/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    FILENAME "sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    SHA512 ${SQLITE_VERSION_HASH}
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"  DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/license.md"      DESTINATION "${SOURCE_PATH}")

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

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES sqlite3 AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SQLite3"
    CONFIG_PATH "share/SQLite3"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/license.md"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)