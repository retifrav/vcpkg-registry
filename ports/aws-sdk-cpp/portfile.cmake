vcpkg_list(SET REQUESTED_AWS_COMPONENTS ${FEATURES})
vcpkg_list(REMOVE_ITEM REQUESTED_AWS_COMPONENTS "core")
if(NOT REQUESTED_AWS_COMPONENTS)
    message(FATAL_ERROR
        "The list of features is empty, you need to specify what you want to build, "
        "or at least put the `everything` feature in there (not recommended)"
    )
endif()

find_program(GIT git REQUIRED) # at least on (some) Windows it will fail with a bare `git`

set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src-github/v${VERSION})

if(NOT EXISTS ${SOURCE_PATH}/.git)
    message(STATUS "Cloning the repository with recursive submodules")
    vcpkg_execute_required_process(
        COMMAND ${GIT} clone --depth=1 --branch ${VERSION} --recurse-submodules git@github.com:aws/aws-sdk-cpp.git ${SOURCE_PATH}
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME git-${PORT}-cloning
    )
else()
    message(STATUS "Resetting and cleaning up the repository")
    #
    message(STATUS "+ resetting the main repository")
    vcpkg_execute_required_process(
        COMMAND ${GIT} reset --hard ${VERSION}
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

list(APPEND AWS_COMPONENTS_SUBMODULES
    aws-c-auth
    aws-c-cal
    aws-c-common
    aws-c-compression
    aws-c-event-stream
    aws-c-http
    aws-c-io
    aws-c-mqtt
    aws-c-s3
    aws-c-sdkutils
    aws-checksums
)

set(PATCH_NAME "001-not-hardcoding-shared-libraries-and-crt.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME git-${PORT}-patching-001
)
set(PATCH_NAME "002-dependencies-and-installation.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME git-${PORT}-patching-002
)
set(PATCH_NAME "003-not-outputing-generated-headers-into-source-tree.patch")
message(STATUS "Applying patch ${PATCH_NAME}")
vcpkg_execute_required_process(
    COMMAND ${GIT} apply "${CMAKE_CURRENT_LIST_DIR}/${PATCH_NAME}"
    WORKING_DIRECTORY ${SOURCE_PATH}
    LOGNAME git-${PORT}-patching-003
)
unset(PATCH_NAME)

# can't patch that, because this is inside a submodule
vcpkg_replace_string(
    "${SOURCE_PATH}/crt/aws-crt-cpp/CMakeLists.txt"
        [=[# set runtime library
if(MSVC)
    if(AWS_STATIC_MSVC_RUNTIME_LIBRARY OR STATIC_CRT)
        target_compile_options(${PROJECT_NAME} PRIVATE "/MT$<$<CONFIG:Debug>:d>")
    else()
        target_compile_options(${PROJECT_NAME} PRIVATE "/MD$<$<CONFIG:Debug>:d>")
    endif()
endif()]=]
        [=[# these things should be handled with CMAKE_MSVC_RUNTIME_LIBRARY]=]
)

# can't patch that, because this is inside a submodule
vcpkg_replace_string(
    "${SOURCE_PATH}/crt/aws-crt-cpp/crt/aws-c-common/CMakeLists.txt"
        [=[DESTINATION "${LIBRARY_DIRECTORY}/cmake"]=]
        [=[DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}"]=]
)

# can't patch that, because this is inside a submodule
vcpkg_replace_string(
    "${SOURCE_PATH}/crt/aws-crt-cpp/crt/aws-c-common/cmake/AwsCFlags.cmake"
        [=[# Set MSVC runtime libary.
        # Note: there are other ways of doing this if we bump our CMake minimum to 3.14+
        # See: https://cmake.org/cmake/help/latest/policy/CMP0091.html
        if (AWS_STATIC_MSVC_RUNTIME_LIBRARY OR STATIC_CRT)
            list(APPEND AWS_C_FLAGS "/MT$<$<CONFIG:Debug>:d>")
        else()
            list(APPEND AWS_C_FLAGS "/MD$<$<CONFIG:Debug>:d>")
        endif()]=]
        [=[# these things should be handled with CMAKE_MSVC_RUNTIME_LIBRARY]=]
)

# there are more CRT-related things in ${SOURCE_PATH}/crt/aws-crt-cpp/crt/aws-c-common/cmake/AwsTestHarness.cmake
# and some other places, but those are for executables, so hopefully we don't care

vcpkg_replace_string(
    "${SOURCE_PATH}/crt/aws-crt-cpp/crt/s2n/CMakeLists.txt"
        [=[install(FILES ${API_HEADERS} DESTINATION "include/" COMPONENT Development)]=]
        [=[install(FILES ${API_HEADERS} DESTINATION "include/${PROJECT_NAME}" COMPONENT Development)]=]
)
vcpkg_replace_string(
    "${SOURCE_PATH}/crt/aws-crt-cpp/crt/s2n/CMakeLists.txt"
        [=[install(FILES ${API_UNSTABLE_HEADERS} DESTINATION "include/s2n/unstable" COMPONENT Development)]=]
        [=[install(FILES ${API_UNSTABLE_HEADERS} DESTINATION "include/${PROJECT_NAME}/unstable" COMPONENT Development)]=]
)

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "shared" FORCE_SHARED_CRT)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DANDROID_BUILD_CURL=0
        -DANDROID_BUILD_OPENSSL=0
        -DANDROID_BUILD_ZLIB=0
        -DAUTORUN_UNIT_TESTS=0
        -DAWS_SDK_WARNINGS_ARE_ERRORS=0
        -DBUILD_DEPS=1
        -DENABLE_TESTING=0
        -DFORCE_CURL=0
        -DFORCE_SHARED_CRT=${FORCE_SHARED_CRT}
        -DLEGACY_BUILD=1
        -DSIMPLE_INSTALL=1
)

if("everything" IN_LIST FEATURES)
    vcpkg_cmake_install()
else()
    message(STATUS "Building and installing requested components")
    foreach(AWS_COMPONENT_NAME ${REQUESTED_AWS_COMPONENTS})
        message(STATUS "+ ${AWS_COMPONENT_NAME}")
        # build
        vcpkg_cmake_build(TARGET ${AWS_COMPONENT_NAME})
        # install Debug
        vcpkg_execute_build_process(
            COMMAND ${CMAKE_COMMAND} --install ./generated/src/${AWS_COMPONENT_NAME} --config Debug
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
            LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-dbg
        )
        # install Release
        vcpkg_execute_build_process(
            COMMAND ${CMAKE_COMMAND} --install ./generated/src/${AWS_COMPONENT_NAME} --config Release
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
            LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-rel
        )
    endforeach()

    # install components from submodules, as those seem to be everyone's dependencies, so they are built every time anyway
    message(STATUS "Installing common dependencies (they have been already built, so only need to install)")
    # the ones the come from submodules
    foreach(AWS_COMPONENT_NAME ${AWS_COMPONENTS_SUBMODULES})
        message(STATUS "+ ${AWS_COMPONENT_NAME}")
        # install Debug
        vcpkg_execute_build_process(
            COMMAND ${CMAKE_COMMAND} --install ./crt/aws-crt-cpp/crt/${AWS_COMPONENT_NAME} --config Debug
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
            LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-dbg
        )
        # install Release
        vcpkg_execute_build_process(
            COMMAND ${CMAKE_COMMAND} --install ./crt/aws-crt-cpp/crt/${AWS_COMPONENT_NAME} --config Release
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
            LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-rel
        )
    endforeach()

    # and then their "parents"
    #
    set(AWS_COMPONENT_NAME "aws-crt-cpp")
    message(STATUS "+ ${AWS_COMPONENT_NAME}")
    # install Debug
    vcpkg_execute_build_process(
        COMMAND ${CMAKE_COMMAND} --install ./crt/${AWS_COMPONENT_NAME} --config Debug
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
        LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-dbg
    )
    # install Release
    vcpkg_execute_build_process(
        COMMAND ${CMAKE_COMMAND} --install ./crt/${AWS_COMPONENT_NAME} --config Release
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-rel
    )
    #
    set(AWS_COMPONENT_NAME "aws-cpp-sdk-core")
    message(STATUS "+ ${AWS_COMPONENT_NAME}")
    # install Debug
    vcpkg_execute_build_process(
        COMMAND ${CMAKE_COMMAND} --install ./src/${AWS_COMPONENT_NAME} --config Debug
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
        LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-dbg
    )
    # install Release
    vcpkg_execute_build_process(
        COMMAND ${CMAKE_COMMAND} --install ./src/${AWS_COMPONENT_NAME} --config Release
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME install-${AWS_COMPONENT_NAME}-${TARGET_TRIPLET}-rel
    )
endif()

# first group of components that need fixing up, there is too many of them, so globbing
#
file(GLOB AWS_COMPONENTS
    LIST_DIRECTORIES YES
    "${CURRENT_PACKAGES_DIR}/share/*"
)
foreach(AWS_COMPONENT ${AWS_COMPONENTS})
    get_filename_component(AWS_COMPONENT_NAME ${AWS_COMPONENT} NAME)
    message(STATUS "Fixing up ${AWS_COMPONENT_NAME}")
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "${AWS_COMPONENT_NAME}"
        CONFIG_PATH "share/${AWS_COMPONENT_NAME}"
    )
endforeach()
#
# second group of components that need fixing up, these are coming from submodules
# and are listed in AWS_COMPONENTS_SUBMODULES list instead of globbing
#
# but first add some more items there
list(APPEND AWS_COMPONENTS_SUBMODULES
    aws-crt-cpp
)
if(VCPKG_TARGET_IS_LINUX) # OR VCPKG_TARGET_IS_ANDROID
    list(APPEND AWS_COMPONENTS_SUBMODULES
        s2n
    )
endif()
# ...and also this thingy
if("everything" IN_LIST FEATURES)
    list(APPEND AWS_COMPONENTS_SUBMODULES
        AWSSDK
    )
endif()
foreach(AWS_COMPONENT_NAME ${AWS_COMPONENTS_SUBMODULES})
    message(STATUS "Fixing up ${AWS_COMPONENT_NAME}")
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "${AWS_COMPONENT_NAME}"
        CONFIG_PATH "lib/${AWS_COMPONENT_NAME}"
        NO_PREFIX_CORRECTION # for these particular configs the resulting paths get messed up
    )
endforeach()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
