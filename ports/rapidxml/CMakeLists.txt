cmake_minimum_required(VERSION 3.22)

project(rapidxml
    VERSION 1.13.0
)

add_library(${PROJECT_NAME} INTERFACE)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/rapidxml.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rapidxml_iterators.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rapidxml_print.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rapidxml_utils.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rapidxml_utils_more.hpp
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
