cmake_minimum_required(VERSION 3.22)

project("sha"
    VERSION 2011.5.1
    DESCRIPTION "RFC 6234: US Secure Hash Algorithms (SHA and SHA-based HMAC and HKDF)"
    LANGUAGES C
)

add_library(${PROJECT_NAME})

target_sources(${PROJECT_NAME}
    PRIVATE
        src/hkdf.c
        src/hmac.c
        src/sha1.c
        src/sha224-256.c
        src/sha384-512.c
        src/usha.c

)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        # where the library itself will look for its internal headers
        ${CMAKE_CURRENT_SOURCE_DIR}/src
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set(public_headers
    include/sha.h
)

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX "d"
        PUBLIC_HEADER "${public_headers}"
)

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
