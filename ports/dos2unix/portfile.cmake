# it is a tool
set(VCPKG_BUILD_TYPE release)
set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_download_distfile(
    ARCHIVE
    URLS "https://waterlan.home.xs4all.nl/dos2unix/dos2unix-${VERSION}.tar.gz"
    FILENAME "dos2unix-${VERSION}.tar.gz"
    SHA512 d76d799435dd248850f72cc50af2144a51e99f04ea83a1447c4edd828625c83f0afba367da51aa83defced4cbf34f3b75387a0821010f7b212225571036efbb2
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

# well, this is fucking retarded, isn't it
# vcpkg_build_make(
#     SUBPATH ../src/dos2unix-7-0d8d69daf2.clean
#     OPTIONS
#         ENABLE_NLS=
# )
# so instead it will be a direct command execution
vcpkg_execute_build_process(
    COMMAND make ENABLE_NLS=
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME build-${PORT}-${TARGET_TRIPLET}-rel
)

vcpkg_copy_tools(
    TOOL_NAMES
        dos2unix
        unix2dos
    SEARCH_DIR ${SOURCE_PATH}
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
