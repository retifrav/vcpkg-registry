cmake_minimum_required(VERSION 3.22)

project("bzip2"
    LANGUAGES C
    VERSION 1.0.8
)

add_library(${PROJECT_NAME})

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    target_compile_definitions(${PROJECT_NAME}
        PRIVATE
            BZ_DEBUG
    )
endif()

if(BUILD_SHARED_LIBS)
    target_compile_definitions(${PROJECT_NAME}
        PUBLIC
            BZ_BUILD_DLL
    )
endif()

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
endif()

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/blocksort.c
    ${CMAKE_CURRENT_SOURCE_DIR}/huffman.c
    ${CMAKE_CURRENT_SOURCE_DIR}/crctable.c
    ${CMAKE_CURRENT_SOURCE_DIR}/randtable.c
    ${CMAKE_CURRENT_SOURCE_DIR}/compress.c
    ${CMAKE_CURRENT_SOURCE_DIR}/decompress.c
    ${CMAKE_CURRENT_SOURCE_DIR}/bzlib.c
)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/bzlib.h
)

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
        #${public_headers}
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

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
