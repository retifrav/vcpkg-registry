cmake_minimum_required(VERSION 3.22)

project("SQLite.Interop"
    VERSION 1.0.111
    LANGUAGES C
)

#set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_library(${PROJECT_NAME})

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/SQLite.Interop/src/generic/interop.c
)

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

# doesn't look like there are any public headers, especially given that this is supposed to be used in .NET,
# and private headers are included with relative paths, so
# target_include_directories(${PROJECT_NAME}
#     PRIVATE
#         # where the library itself will look for its internal headers
#         ${CMAKE_CURRENT_SOURCE_DIR}
#     # PUBLIC
#     #     # where top-level project will look for the library's public headers
#     #     $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
#     #     # where external projects will look for the library's public headers
#     #     $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
# )

if(CMAKE_SYSTEM_NAME STREQUAL Linux)
    find_package(Threads REQUIRED)
    target_link_libraries(
        ${PROJECT_NAME}
            PRIVATE # INTERFACE
                ${CMAKE_THREAD_LIBS_INIT}
                ${CMAKE_DL_LIBS}
    )

    find_library(MATH_LIBRARY m)
    if(MATH_LIBRARY)
        target_link_libraries(
            ${PROJECT_NAME}
                PRIVATE # PUBLIC
                    ${MATH_LIBRARY}
    )
    endif()
endif()

# not sure if this is actually used in the case of SQLite.Interop
# if(BUILD_SHARED_LIBS)
#     if(WIN32)
#         target_compile_definitions(${PROJECT_NAME}
#            PRIVATE
#                "SQLITE_API=__declspec(dllexport)"
#         )
#     else()
#         target_compile_definitions(${PROJECT_NAME}
#            PRIVATE
#                "SQLITE_API=__attribute__((visibility(\"default\")))"
#         )
#     endif()
# endif()

target_compile_definitions(${PROJECT_NAME}
    PRIVATE # PUBLIC
        $<BUILD_INTERFACE:
            SQLITE_THREADSAFE=1
            SQLITE_USE_URI=1
            SQLITE_ENABLE_COLUMN_METADATA=1
            SQLITE_ENABLE_STAT4=1
            SQLITE_ENABLE_FTS3=1
            SQLITE_ENABLE_LOAD_EXTENSION=1
            SQLITE_ENABLE_RTREE=1
            SQLITE_SOUNDEX=1
            SQLITE_ENABLE_MEMORY_MANAGEMENT=1
            SQLITE_ENABLE_API_ARMOR=1
            SQLITE_ENABLE_DBSTAT_VTAB=1
            SQLITE_ENABLE_STMTVTAB=1
            INTEROP_TEST_EXTENSION=1
            INTEROP_EXTENSION_FUNCTIONS=1
            INTEROP_VIRTUAL_TABLE=1
            INTEROP_FTS5_EXTENSION=1
            INTEROP_PERCENTILE_EXTENSION=1
            INTEROP_TOTYPE_EXTENSION=1
            INTEROP_REGEXP_EXTENSION=1
            INTEROP_JSON1_EXTENSION=1
            INTEROP_SHA1_EXTENSION=1
            INTEROP_SESSION_EXTENSION=1
        >
)

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
