cmake_minimum_required(VERSION 3.22)

project(dos2unix
    DESCRIPTION "Text file format converters"
    LANGUAGES C
)

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/version.mk VERSION_INFO)
foreach(VAR_LINE ${VERSION_INFO})
  # strip leading spaces
  string(REGEX REPLACE "^[ ]+" "" VAR_LINE ${VAR_LINE})
  # strip the quotes
  string(REPLACE "'" "" VAR_LINE ${VAR_LINE})
  # find variable name
  string(REGEX MATCH "^[^ = ]+" VAR_NAME ${VAR_LINE})
  # find the value
  string(REPLACE "${VAR_NAME} = " "" VAR_VALUE ${VAR_LINE})
  # set the variable
  set(${VAR_NAME} "${VAR_VALUE}")
endforeach()

message(DEBUG "DOS2UNIX_VERSION: ${DOS2UNIX_VERSION}")
message(DEBUG "DOS2UNIX_DATE: ${DOS2UNIX_DATE}")
message(DEBUG "DOS2UNIX_AUTHOR: ${DOS2UNIX_AUTHOR}")

set(CMAKE_PROJECT_VERSION ${DOS2UNIX_VERSION} CACHE STATIC "Project version") # FORCE

set(TOOLS dos2unix unix2dos)

foreach(TOOL_NAME ${TOOLS})
    add_executable(${TOOL_NAME})

    set(sources
        ${CMAKE_CURRENT_SOURCE_DIR}/common.c
        ${CMAKE_CURRENT_SOURCE_DIR}/querycp.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${TOOL_NAME}.c
    )
    target_sources(${TOOL_NAME} PRIVATE ${sources})
    unset(sources)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        target_compile_definitions(${TOOL_NAME}
            PRIVATE
                #_WIN32
                D2U_UNIFILE
        )
    endif()
    target_compile_definitions(${TOOL_NAME}
        PRIVATE
            VER_REVISION="${DOS2UNIX_VERSION}"
            VER_DATE="${DOS2UNIX_DATE}"
            VER_AUTHOR="${DOS2UNIX_AUTHOR}"
    )

    set_target_properties(${TOOL_NAME}
        PROPERTIES
            DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
    )
endforeach()

include(GNUInstallDirs)

install(TARGETS ${TOOLS})
