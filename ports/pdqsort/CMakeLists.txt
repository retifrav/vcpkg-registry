cmake_minimum_required(VERSION 3.22)

project("pdqsort"
    VERSION 2021.3.14
    DESCRIPTION "Pattern-defeating quicksort"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(${PROJECT_NAME} INTERFACE)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/pdqsort.h
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
