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
set(SQLITE_VERSION_YEAR "2026")
# is it the same genius who came up with this version string format
set(SQLITE_VERSION_VALUE "3530100")

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://sqlite.org/${SQLITE_VERSION_YEAR}/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
        "https://files.decovar.dev/public/packages/sqlite/v${VERSION}/src/sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    FILENAME "sqlite-amalgamation-${SQLITE_VERSION_VALUE}.zip"
    SHA512 8f35db4083c77a2f3ff355551556043bea82d5411d748cea35f577592b47dc9a45b41e5e5a054dcce29861f077d6e6b223ae3d161b575b4b4e708ee8470255c2
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
        #
        # ICU is disabled for good, see _notes.md
        #icu SQLITE_ENABLE_ICU
        #
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
        -DSQLITE_VERSION="${VERSION}"
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

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    # consumers need to import the symbols from the DLL, otherwise the exported variables
    # (`sqlite3_version`, `sqlite3_temp_directory`, `sqlite3_data_directory`) won't link.
    # Setting it in the header makes it work for consumers without CMake too,
    # and it is still within `#ifndef`, so it can be overridden
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/sqlite3/sqlite3.h"
        "#ifndef SQLITE_API\n# define SQLITE_API\n#endif"
        "#ifndef SQLITE_API\n# define SQLITE_API __declspec(dllimport)\n#endif"
    )
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

if("in-memory-vfs" IN_LIST FEATURES)
    set(MEMVFS_FILE "memvfs.c")
    # it is not available in amalgamated source package, so it had to be downloaded
    # separately, but now isn't even a part of the repository anymore:
    # - https://sqlite.org/src/timeline?c=eb79110dcac80dde&y=a
    # - https://sqlite.org/src/info/2025-10-02T22:48Z
    # - https://sqlite.org/forum/forumpost/8070243b9080180d
    vcpkg_download_distfile(
        MEMVFS_FILE_DOWNLOADED
        URLS
            # the hash doesn't seem to have anything to do with the version commit hash,
            # it just doesn't change if there were no changes in the file, so there is no point
            # in making it a variable
            #"https://sqlite.org/src/raw/7dffa8cc89c7f2d73da4bd4ccea1bcbd2bd283e3bb4cea398df7c372a197291b?at=${MEMVFS_FILE}"
            #"https://files.decovar.dev/public/packages/sqlite/v${VERSION}/src/${MEMVFS_FILE}"
            # last saved version was from v3.49.1
            "https://files.decovar.dev/public/packages/sqlite/v3.49.1/src/${MEMVFS_FILE}"
        FILENAME "${MEMVFS_FILE}"
        SHA512 e47757db92a4dfb0ad305d19175ef300fc9b86467605d34ed2133e2f80320a4b98f4f519359fd7ab0f3cbeef8958aad45fede63641c54b77aa8ad4d950fdae4c
    )
    # if you intend to compile memvfs.c source file as a part of your project, and that project
    # is a DLL which needs to export `sqlite3_memvfs_init()`, then set `SQLITE_MEMVFS_API=__declspec(dllexport)`
    # compile definition. It cannot use `SQLITE_API` for that, because for consumers of SQLite DLL
    # that one is `__declspec(dllimport)`, and defining a dllimport function is an error (C2491)

    # in general, this is needed for being able to serialize an SQLite database file
    # and then load it from VFS (virtual file system), which might be needed in cases
    # when database file cannot be loaded from local file system, such as in web-applications
    # with WebAssembly
    #
    # might need to come up with a better(?) way of compiling this source file in the consuming project,
    # perhaps it should be built together with SQLite sources? But then consuming library would need
    # to link to SQLite, which might not be desirable
    #
    # or perhaps there should be an INTERFACE target with this source file? Or add it to the main
    # target with INTERFACE_SOURCES?
    # https://discourse.cmake.org/t/best-way-to-have-a-library-package-install-a-main-cpp-and-run-add-executable-in-context-of-user-project-when-it-calls-my-cmake-function/11200/4
    file(
        INSTALL "${MEMVFS_FILE_DOWNLOADED}"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${INSTALLED_CMAKE_PACKAGE_NAME}/etc"
    )
    # applying with Git instead of `patch` tool, because the latter usually isn't available on Windows.
    # The `--work-tree`/`--git-dir` arguments are the same as vcpkg's own patching uses, so Git doesn't
    # pick up the enclosing vcpkg repository, and `-p3` is because the patch is made against
    # SQLite's source tree (`ext/misc/memvfs.c`)
    vcpkg_find_acquire_program(GIT)
    vcpkg_execute_required_process(
        COMMAND "${GIT}" -c core.longpaths=true -c core.autocrlf=false --work-tree=. --git-dir=.git
            apply -p3 --ignore-whitespace --whitespace=nowarn --verbose
            "${CMAKE_CURRENT_LIST_DIR}/001-dll-definitions.patch"
        WORKING_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${INSTALLED_CMAKE_PACKAGE_NAME}/etc"
        LOGNAME git-patching-memvfs
    )
endif()

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/license.md")
