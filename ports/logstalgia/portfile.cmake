# it's an application, so we don't need a Debug build, and there are no libraries or public headers
set(VCPKG_BUILD_TYPE release)
# set(VCPKG_POLICY_ALLOW_EXES_IN_BIN enabled)
# set(VCPKG_POLICY_DLLS_WITHOUT_LIBS enabled)
# set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
# set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
# set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)
set(VCPKG_POLICY_EMPTY_PACKAGE enabled) # does all of the above

find_program(GIT git REQUIRED) # at least on (some) Windows it will fail with a bare `git`

set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src-github/v${VERSION})

if(NOT EXISTS ${SOURCE_PATH}/.git)
    message(STATUS "Cloning the repository with recursive submodules")
    vcpkg_execute_required_process(
        COMMAND ${GIT} clone --depth=1 --branch logstalgia-${VERSION} --recurse-submodules git@github.com:acaudwell/Logstalgia.git ${SOURCE_PATH}
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME git-${PORT}-cloning
    )
else()
    message(STATUS "Resetting and cleaning up the repository")
    #
    message(STATUS "+ resetting the main repository")
    vcpkg_execute_required_process(
        COMMAND ${GIT} reset --hard logstalgia-${VERSION}
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME git-${PORT}-main-resetting
    )
    message(STATUS "+ cleaning up the main repository")
    vcpkg_execute_required_process(
        COMMAND ${GIT} clean -x -f -d
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME git-${PORT}-main-cleaning
    )
    message(STATUS "+ resetting the submodules")
    vcpkg_execute_required_process(
        COMMAND ${GIT} submodule foreach --recursive git reset --hard
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME git-${PORT}-submodules-resetting
    )
    message(STATUS "+ cleaning up the submodules")
    vcpkg_execute_required_process(
        COMMAND ${GIT} submodule foreach --recursive git clean -x -f -d
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME git-${PORT}-submodules-cleaning
    )
endif()

set(PATCH_NAME "001-using-filesystem.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME git-${PORT}-patching-001
)

set(PATCH_NAME "002-io-isatty.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME git-${PORT}-patching-002
)

set(PATCH_NAME "003-png-headers.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}/src/core
    LOGNAME git-${PORT}-patching-003
)

set(PATCH_NAME "004-sdl-headers.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}/src/core
    LOGNAME git-${PORT}-patching-004
)

set(PATCH_NAME "005-pcre-headers.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}/src/core
    LOGNAME git-${PORT}-patching-005
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"  DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/logstalgia.ico" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/resources.rc" DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
