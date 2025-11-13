cmake_minimum_required(VERSION 3.22)

set(STB_VERSION "0.0.0" CACHE STRING "stb version")

project("stb"
    DESCRIPTION "Single-file libraries for C/C++"
    VERSION ${STB_VERSION}
)

add_library(${PROJECT_NAME} INTERFACE)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/stb_image.h
    ${CMAKE_CURRENT_SOURCE_DIR}/stb_image_resize2.h
    ${CMAKE_CURRENT_SOURCE_DIR}/stb_image_write.h
    ${CMAKE_CURRENT_SOURCE_DIR}/stb_truetype.h
    # more to be added if needed
)

target_include_directories(${PROJECT_NAME}
    INTERFACE
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
