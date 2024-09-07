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

# how the fuck were people surviving in those ancient times with cursed Makefiles
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_copy_tools(
    TOOL_NAMES
        dos2unix
        unix2dos
    AUTO_CLEAN
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.txt")
