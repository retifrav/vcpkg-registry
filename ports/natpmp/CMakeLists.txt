cmake_minimum_required(VERSION 3.22)

project(natpmp
    DESCRIPTION "A portable and fully compliant implementation of the NAT-PMP protocol"
    VERSION 2023.6.18
    LANGUAGES C
)

option(ENABLE_TOOLS "Build tools" 0)

add_library(${PROJECT_NAME})

set(sources
    natpmp.c
    getgateway.c
)
if(WIN32)
    list(APPEND sources
        wingettimeofday.c
    )
endif()

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

target_include_directories(${PROJECT_NAME}
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set(public_headers
    getgateway.h
    natpmp.h
    natpmp_declspec.h
)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
        "ENABLE_STRNATPMPERR"
)

if(WIN32)
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
            WS2_32
            iphlpapi
    )
    if(BUILD_SHARED_LIBS)
        target_compile_definitions(${PROJECT_NAME}
            PUBLIC
                "NATPMP_EXPORTS"
        )
    else()
        target_compile_definitions(${PROJECT_NAME}
            PUBLIC
                "NATPMP_STATICLIB"
        )
    endif()
endif()

if(ENABLE_TOOLS)
    add_executable(natpmpc
        natpmpc.c
    )
    target_link_libraries(natpmpc
        PRIVATE
            ${PROJECT_NAME}
    )

    add_executable(testgetgateway
        testgetgateway.c
        getgateway.c
    )
    target_link_libraries(testgetgateway
        PRIVATE
            ${PROJECT_NAME}
    )

    install(TARGETS natpmpc testgetgateway
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        PUBLIC_HEADER "${public_headers}"
)

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
