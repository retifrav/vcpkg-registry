cmake_minimum_required(VERSION 3.22)

set(IMPLOT_VERSION "0.0.0" CACHE STRING "ImPlot version")

project("implot"
    VERSION "${IMPLOT_VERSION}"
)

option(WITH_INTERNAL "Using internal header(s)" 0)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

add_library(${PROJECT_NAME})

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/implot.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/implot_items.cpp
)
set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/implot.h
)

if(WITH_INTERNAL)
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/implot_internal.h
    )
endif()

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

find_package(dearimgui CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME}
    PRIVATE # PUBLIC
        dearimgui::dearimgui
)

set(PROJECT_NAMESPACE_FOR_PACKAGE "dearimgui")
include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
