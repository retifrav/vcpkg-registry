cmake_minimum_required(VERSION 3.22)

project("sqlite3"
    VERSION 3.45.1
    DESCRIPTION "Small, fast, self-contained, high-reliability, full-featured SQL database engine"
    LANGUAGES C
)

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

option(SQLITE_RECOMMENDED_OPTIONS    "Build with SQLite3 recommended options"          1)
option(SQLITE_ENABLE_COLUMN_METADATA "Enables column metadata"                         0)
option(SQLITE_ENABLE_DBSTAT_VTAB     "Enables dbstat virtual table"                    0)
option(SQLITE_ENABLE_FTS3            "Enables full text searches version 3"            0)
option(SQLITE_ENABLE_FTS4            "Enables full text searches version 3 and 4"      0)
option(SQLITE_ENABLE_FTS5            "Enables full text searches version 5"            0)
option(SQLITE_ENABLE_GEOPOLY         "Enables Geopoly extention"                       0)
option(SQLITE_ENABLE_ICU             "Enables international components for Unicode"    0)
option(SQLITE_ENABLE_MATH_FUNCTIONS  "Enables built-in SQL math functions"             1)
option(SQLITE_ENABLE_RBU             "Enables resumable bulk update extension"         0)
option(SQLITE_ENABLE_RTREE           "Enables R*TRee index extension"                  0)
option(SQLITE_ENABLE_STAT4           "Enhances query planner under certain situations" 0)
option(SQLITE_OMIT_DECLTYPE          "Disable declared type of columns"                1)
option(SQLITE_OMIT_JSON              "Disable JSON SQL functions"                      0)
option(SQLITE_USE_URI                "Enables default URI filename processing"         0)
option(BUILD_SQLITE_TOOL             "Build the sqlite CLI tool"                       0)

if(SQLITE_ENABLE_COLUMN_METADATA AND SQLITE_OMIT_DECLTYPE)
    message(FATAL_ERROR
"Unset the SQLITE_OMIT_DECLTYPE if you want to \
compile with SQLITE_ENABLE_COLUMN_METADATA. \
Compiling with both options enabled is not recommended"
)
endif()

add_library(${PROJECT_NAME})
if(BUILD_SHARED_LIBS)
    if(WIN32)
        target_compile_definitions(${PROJECT_NAME}
           PRIVATE
               "SQLITE_API=__declspec(dllexport)"
        )
    else()
        target_compile_definitions(${PROJECT_NAME}
           PRIVATE
               "SQLITE_API=__attribute__((visibility(\"default\")))"
        )
    endif()
endif()

if(WIN32)
    target_compile_definitions(${PROJECT_NAME}
       PRIVATE
           "SQLITE_OS_WIN"
    )
    if(CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
        target_compile_definitions(${PROJECT_NAME}
           PRIVATE
               "SQLITE_OS_WINRT"
        )
    endif()
else()
    target_compile_definitions(${PROJECT_NAME}
       PRIVATE
           "SQLITE_OS_UNIX"
    )
endif()

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/sqlite3.c
)
set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/sqlite3.h
    ${CMAKE_CURRENT_SOURCE_DIR}/sqlite3ext.h
)

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
        ${public_headers}
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        # where the library itself will look for its internal headers
        ${CMAKE_CURRENT_SOURCE_DIR}
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

# taken from https://github.com/azadkuh/sqlite-amalgamation/blob/master/CMakeLists.txt
target_compile_definitions(${PROJECT_NAME} PUBLIC
    $<BUILD_INTERFACE:
        $<$<BOOL:${SQLITE_ENABLE_COLUMN_METADATA}>:SQLITE_ENABLE_COLUMN_METADATA>
        $<$<BOOL:${SQLITE_ENABLE_DBSTAT_VTAB}>:SQLITE_ENABLE_DBSTAT_VTAB>
        $<$<BOOL:${SQLITE_ENABLE_FTS3}>:SQLITE_ENABLE_FTS3>
        $<$<BOOL:${SQLITE_ENABLE_FTS4}>:SQLITE_ENABLE_FTS4>
        $<$<BOOL:${SQLITE_ENABLE_FTS5}>:SQLITE_ENABLE_FTS5>
        $<$<BOOL:${SQLITE_ENABLE_GEOPOLY}>:SQLITE_ENABLE_GEOPOLY>
        $<$<BOOL:${SQLITE_ENABLE_ICU}>:SQLITE_ENABLE_ICU>
        $<$<BOOL:${SQLITE_ENABLE_MATH_FUNCTIONS}>:SQLITE_ENABLE_MATH_FUNCTIONS>
        $<$<BOOL:${SQLITE_ENABLE_RBU}>:SQLITE_ENABLE_RBU>
        $<$<BOOL:${SQLITE_ENABLE_RTREE}>:SQLITE_ENABLE_RTREE>
        $<$<BOOL:${SQLITE_ENABLE_STAT4}>:SQLITE_ENABLE_STAT4>
        $<$<BOOL:${SQLITE_OMIT_DECLTYPE}>:SQLITE_OMIT_DECLTYPE>
        $<$<BOOL:${SQLITE_OMIT_JSON}>:SQLITE_OMIT_JSON>
        $<$<BOOL:${SQLITE_USE_URI}>:SQLITE_USE_URI>
        $<$<BOOL:${SQLITE_RECOMMENDED_OPTIONS}>:
            SQLITE_DEFAULT_MEMSTATUS=0
            SQLITE_DEFAULT_WAL_SYNCHRONOUS=1
            SQLITE_DQS=0
            SQLITE_LIKE_DOESNT_MATCH_BLOBS
            SQLITE_MAX_EXPR_DEPTH=0
            SQLITE_OMIT_DEPRECATED
            SQLITE_OMIT_PROGRESS_CALLBACK
            SQLITE_OMIT_SHARED_CACHE
            SQLITE_USE_ALLOCA
        >
    >
)

if(CMAKE_SYSTEM_NAME STREQUAL Linux)
    find_package(Threads REQUIRED)
    target_link_libraries(
        ${PROJECT_NAME}
            INTERFACE
                ${CMAKE_THREAD_LIBS_INIT}
                ${CMAKE_DL_LIBS}
    )

    if(SQLITE_ENABLE_MATH_FUNCTIONS)
        find_library(MATH_LIBRARY m)
        if(MATH_LIBRARY)
            target_link_libraries(
                ${PROJECT_NAME}
                    PUBLIC
                        ${MATH_LIBRARY}
        )
        endif()
    endif()
endif()

if(BUILD_SQLITE_TOOL)
   set(SQLITE_TOOL_NAME "sqlite")
   add_executable(${SQLITE_TOOL_NAME} shell.c)
   set_target_properties(${SQLITE_TOOL_NAME}
        PROPERTIES
            OUTPUT_NAME sqlite3
            DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
    )
   target_link_libraries(${SQLITE_TOOL_NAME} PRIVATE ${PROJECT_NAME})
   # if(UNIX)
   #     if(CMAKE_BUILD_TYPE STREQUAL Release)
   #         add_custom_command(TARGET ${SQLITE_TOOL_NAME}
   #             POST_BUILD
   #                 COMMAND ${CMAKE_STRIP} sqlite3
   #         )
   #     endif()
   # elseif(MSVC)
   #     option(BUILD_SHELL_STATIC "Build shell with static C/C++ runtime" 1)
   #     foreach(flag CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_DEBUG)
   #         if(BUILD_SHELL_STATIC)
   #             string(REGEX REPLACE "/MD" "/MT" ${flag} "${${flag}}")
   #         else()
   #             string(REGEX REPLACE "/MT" "/MD" ${flag} "${${flag}}")
   #         endif()
   #         set(${flag} "${${flag}}" CACHE STRING "msvc flags" FORCE)
   #     endforeach()
   # endif()
   install(TARGETS ${SQLITE_TOOL_NAME}
       RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
       CONFIGURATIONS Release
   )
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
