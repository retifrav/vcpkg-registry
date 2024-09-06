# it's a game, so we don't need a Debug build, and there are no libraries or public headers
set(VCPKG_BUILD_TYPE release)
# set(VCPKG_POLICY_ALLOW_EXES_IN_BIN enabled)
# set(VCPKG_POLICY_DLLS_WITHOUT_LIBS enabled)
# set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
# set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
# set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)
set(VCPKG_POLICY_EMPTY_PACKAGE enabled) # does all of the above

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:konovalov-aleks/reSL.git
    REF 5713527ce17afa39bfa7e6b4ac34ec0f61c8837e
    PATCHES
        001-non-development-build-and-installation.patch
        002-typos-in-manual.patch
)

# fix the line endings in the manual, because Git fucks them up on patching,
# and the game can correctly render only the DOS/Windows variant of line endings
find_program(UNIX2DOS_TOOL
    NAMES "unix2dos"
    PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/dos2unix"
    NO_DEFAULT_PATH
    REQUIRED
)
vcpkg_execute_required_process(
    COMMAND ${UNIX2DOS_TOOL} RULES.TXT
    WORKING_DIRECTORY "${SOURCE_PATH}/resources"
    LOGNAME build-${PORT}-${TARGET_TRIPLET}-rel
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/www"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_FOR_DEVELOPMENT=0
)

vcpkg_cmake_install()

# also, since it is not a tool, there is no need to do vcpkg_copy_tools() or anything

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
