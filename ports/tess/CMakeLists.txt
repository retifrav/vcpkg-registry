cmake_minimum_required(VERSION 3.22)

project("tess"
    VERSION 9.0.3
)

# not used here, the header is installed in portfile at the moment
option(INSTALL_GLU_HEADER "Install GL/glu.h header" 0)

add_library(${PROJECT_NAME})

set(sources
    src/libtess/dict.c
    src/libtess/geom.c
    src/libtess/memalloc.c
    src/libtess/mesh.c
    src/libtess/normal.c
    src/libtess/priorityq.c
    src/libtess/render.c
    src/libtess/sweep.c
    src/libtess/tess.c
    src/libtess/tessmono.c
)
target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/src/libtess/tess.h
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        #${CMAKE_CURRENT_SOURCE_DIR}/src/libtess
        ${CMAKE_CURRENT_SOURCE_DIR}/src/include
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/libtess>
        #$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
        #$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(${PROJECT_NAME}
        PRIVATE
            "BUILD_GLU32"
    )
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
