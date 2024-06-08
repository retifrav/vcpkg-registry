cmake_minimum_required(VERSION 3.22)

project("tinyxml"
    VERSION 2.6.2
)

set(CMAKE_CXX_STANDARD 11)

add_library(${PROJECT_NAME})

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/tinystr.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tinyxml.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tinyxmlerror.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tinyxmlparser.cpp
)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/tinystr.h
    ${CMAKE_CURRENT_SOURCE_DIR}/tinyxml.h
)

target_sources(${PROJECT_NAME} PRIVATE ${sources})

target_include_directories(${PROJECT_NAME}
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_compile_definitions(${PROJECT_NAME}
    PUBLIC
        TIXML_USE_STL
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
