cmake_minimum_required(VERSION 3.22)

project("XrUtility"
    VERSION 113.2309.7002
)

add_library(${PROJECT_NAME} INTERFACE)

file(GLOB public_headers_xrutility "${CMAKE_CURRENT_SOURCE_DIR}/shared/XrUtility/*")
set(public_headers_openxr_preview
    "${CMAKE_CURRENT_SOURCE_DIR}/openxr_preview/include/openxr_preview/openxr_msft_preview.h"
)

target_include_directories(${PROJECT_NAME}
    INTERFACE
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# find_package(OpenXR CONFIG REQUIRED)
# target_link_libraries(${PROJECT_NAME}
#     PRIVATE
#         OpenXR::openxr_loader
#         OpenXR::headers
# )

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        PUBLIC_HEADER "${public_headers_xrutility}"
)

include(${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake)

install(
    FILES "${public_headers_openxr_preview}"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/openxr_preview"
)
