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
