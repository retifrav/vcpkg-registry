include_guard(GLOBAL)

macro(decovar_vcpkg_cmake_parse_version_to_semver_components)
    if(
        NOT DEFINED VERSION
        OR
        VERSION STREQUAL ""
    )
        message(FATAL_ERROR "The VERSION variable doesn't seem to be defined/set")
    endif()

    set(PORT_VERSION_MAJOR 0)
    set(PORT_VERSION_MINOR 0)
    set(PORT_VERSION_PATCH 0)

    string(REGEX MATCH "^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$" PORT_VERSION_SEMVER ${VERSION})
    message(DEBUG "PORT_VERSION_SEMVER: ${PORT_VERSION_SEMVER}")
    if(PORT_VERSION_SEMVER STREQUAL "") # a very unlikely event
        message(FATAL_ERROR "Could not parse the port version from ${VERSION}")
    else()
        if(NOT CMAKE_MATCH_COUNT EQUAL 3) # also an unlikely event
            message(FATAL_ERROR "Parsed port version doesn't seem to be a correct SemVer value, as it contains ${CMAKE_MATCH_COUNT} matches")
        endif()
        set(PORT_VERSION_MAJOR ${CMAKE_MATCH_1})
        message(DEBUG "PORT_VERSION_MAJOR: ${PORT_VERSION_MAJOR}")
        set(PORT_VERSION_MINOR ${CMAKE_MATCH_2})
        message(DEBUG "PORT_VERSION_MINOR: ${PORT_VERSION_MINOR}")
        set(PORT_VERSION_PATCH ${CMAKE_MATCH_3})
        message(DEBUG "PORT_VERSION_PATCH: ${PORT_VERSION_PATCH}")
    endif()
endmacro()

macro(decovar_vcpkg_cmake_git_clone_sparse_checkout
    SPARSE_CLONE_REPOSITORY_URL
    SPARSE_CLONE_BRANCH_NAME
    SPARSE_CLONE_CHECKOUT_PATHS
)
    message(DEBUG "PORT: ${PORT}")
    message(DEBUG "SOURCE_PATH: ${SOURCE_PATH}")
    #
    message(DEBUG "SPARSE_CLONE_REPOSITORY_URL: ${SPARSE_CLONE_REPOSITORY_URL}")
    message(DEBUG "SPARSE_CLONE_BRANCH_NAME: ${SPARSE_CLONE_BRANCH_NAME}")
    message(DEBUG "SPARSE_CLONE_CHECKOUT_PATHS: ${SPARSE_CLONE_CHECKOUT_PATHS}")

    find_program(GIT git REQUIRED) # on some platforms it will fail with a bare `git`
    message(DEBUG "Got this Git: ${GIT}")

    execute_process(
        COMMAND ${GIT} --version
        OUTPUT_STRIP_TRAILING_WHITESPACE
        OUTPUT_VARIABLE GIT_VERSION_VALUE
        RESULT_VARIABLE GIT_VERSION_RETURN
    )
    string(REGEX MATCH "^git version ([0-9]+\.[0-9]+).*$" GIT_VERSION_VALUE_PARSED ${GIT_VERSION_VALUE})
    set(GIT_VERSION_VALUE_PARSED ${CMAKE_MATCH_1})
    message(DEBUG "Git version: ${GIT_VERSION_VALUE_PARSED}")

    if(NOT EXISTS ${SOURCE_PATH}/.git)
        message(STATUS "There is no local clone for the repository yet")
        if(GIT_VERSION_VALUE_PARSED VERSION_GREATER_EQUAL "2.38")
            message(STATUS "+ sparsely cloning the repository")
            vcpkg_execute_required_process(
                COMMAND ${GIT} clone --depth 1 --filter=blob:none --branch ${SPARSE_CLONE_BRANCH_NAME} --sparse ${SPARSE_CLONE_REPOSITORY_URL} ${SOURCE_PATH}
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
                LOGNAME git-${PORT}-cloning
            )
            message(STATUS "+ checking-out paths")
            vcpkg_execute_required_process(
                COMMAND ${GIT} sparse-checkout set --no-cone ${SPARSE_CLONE_CHECKOUT_PATHS}
                WORKING_DIRECTORY ${SOURCE_PATH}
                LOGNAME git-${PORT}-checking-out
            )
        else()
            message(STATUS "+ Git version is too old for a sparse clone/checkout, cloning the entire repository")
            vcpkg_execute_required_process(
                COMMAND ${GIT} clone --depth=1 --branch ${SPARSE_CLONE_BRANCH_NAME} ${SPARSE_CLONE_REPOSITORY_URL} ${SOURCE_PATH}
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
                LOGNAME git-${PORT}-cloning
            )
        endif()
    else()
        message(STATUS "There is already a local clone of the repository, will reset and clean it up")
        #
        message(STATUS "+ resetting")
        vcpkg_execute_required_process(
            COMMAND ${GIT} reset --hard ${SPARSE_CLONE_BRANCH_NAME}
            WORKING_DIRECTORY ${SOURCE_PATH}
            LOGNAME git-${PORT}-resetting
        )
        message(STATUS "+ cleaning up")
        vcpkg_execute_required_process(
            COMMAND ${GIT} clean -x -f -d
            WORKING_DIRECTORY ${SOURCE_PATH}
            LOGNAME git-${PORT}-cleaning
        )
    endif()
endmacro()
