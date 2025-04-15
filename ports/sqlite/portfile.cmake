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
set(SQLITE_VERSION_YEAR "2025")
# is it the same genius who came up with this version string format
set(SQLITE_VERSION_VALUE "3490100")

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://sqlite.org/${SQLITE_VERSION_YEAR}/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
        "https://files.decovar.dev/public/packages/sqlite/v${VERSION}/src/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    FILENAME "sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    SHA512 8124e78110122e2792f54924877d3f394776b36a69c4b5129404e04cd01972cc3d38ac21de222f64a2659f60768f424c9053b33ec16fbaf910020b5a73df554b
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
        in-memory-vfs IN_MEMORY_VFS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
    MAYBE_UNUSED_VARIABLES
        IN_MEMORY_VFS
)

vcpkg_cmake_install()

set(INSTALLED_CMAKE_PACKAGE_NAME "sqlite3")

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "${INSTALLED_CMAKE_PACKAGE_NAME}"
    CONFIG_PATH "share/${INSTALLED_CMAKE_PACKAGE_NAME}"
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

if("in-memory-vfs" IN_LIST FEATURES)
    # it isn't available in amalgamated source package, is it
    vcpkg_download_distfile(
        MEMVFS_C
        URLS
            # the hash doesn't seem to have anything to do with the version commit hash,
            # it just doesn't change if there were no changes in the file, so there is no point
            # in making it a variable
            "https://sqlite.org/src/raw/7dffa8cc89c7f2d73da4bd4ccea1bcbd2bd283e3bb4cea398df7c372a197291b?at=memvfs.c"
            "https://files.decovar.dev/public/packages/sqlite/v${VERSION}/src/memvfs.c"
        FILENAME "memvfs.c"
        SHA512 e47757db92a4dfb0ad305d19175ef300fc9b86467605d34ed2133e2f80320a4b98f4f519359fd7ab0f3cbeef8958aad45fede63641c54b77aa8ad4d950fdae4c
    )
    # in general, this is needed for being able to serialize an SQLite database file
    # and then load it from VFS (virtual file system), which might be needed in cases
    # when database file cannot be loaded from local file system, such as in web-applications
    # with WebAssembly
    #
    # might need to come up with a better(?) way of compiling this source file
    # in the consuming project, perhaps it should be built together with SQLite sources?
    file(
        INSTALL "${MEMVFS_C}"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${INSTALLED_CMAKE_PACKAGE_NAME}/etc"
    )
endif()

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/license.md")
