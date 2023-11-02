cmake_minimum_required(VERSION 3.22)

project(minizip
    VERSION 1.2.12
    LANGUAGES C
)

option(ENABLE_BZIP2 "Compression using bzip2" 0)
option(BUILD_TOOLS "Build tools" 0)

add_library(${PROJECT_NAME})

set(sources
    ioapi.c
    unzip.c
    zip.c
    mztools.c
)
if(WIN32)
    list(APPEND sources
        iowin32.c
    )
endif()

set(public_headers
    crypt.h
    ioapi.h
    unzip.h
    zip.h
    mztools.h
)
if(WIN32)
    list(APPEND public_headers iowin32.h)
endif()

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

find_package(zlib CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        zlib
)
target_compile_definitions(${PROJECT_NAME}
    PRIVATE
        "-D_ZLIB_H"
)

# if(ANDROID)
#     target_compile_definitions(${PROJECT_NAME}
#         PRIVATE
#             "IOAPI_NO_64"
#     )
# endif()

if(ENABLE_BZIP2)
    message(STATUS "Building with bzip2 support")

    find_package(bzip2 CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
            bzip2
        )
    target_compile_definitions(${PROJECT_NAME}
        PRIVATE
            "HAVE_BZIP2"
    )
else()
    message(STATUS "Building without bzip2 support")
endif()

if(MSVC)
    target_compile_options(${PROJECT_NAME}
        PRIVATE
            "/W3"
            "/wd4005"
            "/wd4996"
            "/wd4018"
            "-D_CRT_SECURE_NO_WARNINGS"
    )
endif()

if(BUILD_TOOLS)
    add_executable(minizip_tool minizip.c)
    add_executable(miniunz_tool miniunz.c)

    target_link_libraries(minizip_tool
        PRIVATE
            ${PROJECT_NAME}
            zlib
            $<$<BOOL:${ENABLE_BZIP2}>:bzip2>
    )
    target_link_libraries(miniunz_tool
        PRIVATE
            ${PROJECT_NAME}
            zlib
            $<$<BOOL:${ENABLE_BZIP2}>:bzip2>
    )

    set_target_properties(minizip_tool
        PROPERTIES
            OUTPUT_NAME "minizip"
    )
    set_target_properties(miniunz_tool
        PROPERTIES
            OUTPUT_NAME "miniunz"
    )

    install (
        TARGETS minizip_tool miniunz_tool
        RUNTIME DESTINATION "tools/minizip"
    )
endif()

target_include_directories(${PROJECT_NAME}
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
