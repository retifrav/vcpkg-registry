cmake_minimum_required(VERSION 3.22)

project("implot"
    VERSION 0.14.0
)

option(WITH_INTERNAL "Using internal header(s)" 0)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# it is almost never a good idea to do this
# if(WIN32 AND BUILD_SHARED_LIBS)
#     # you won't get .lib on Windows, as it doesn't export symbols out of the box,
#     # so this needs to be forced
#     set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS 1)
# endif()

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
        dearimgui
)

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
