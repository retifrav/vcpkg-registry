cmake_minimum_required(VERSION 3.22)

project("lzma")

add_library(${PROJECT_NAME})

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/C/Alloc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/CpuArch.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzFind.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzFindOpt.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzmaEnc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzmaDec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzmaLib.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzFindMt.c
    ${CMAKE_CURRENT_SOURCE_DIR}/C/Threads.c
    # probably other sources will also be required at some point
)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/C/7zTypes.h
    ${CMAKE_CURRENT_SOURCE_DIR}/C/LzmaLib.h
    # probably other headers will also need to be published at some point
)

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        # where the library itself will look for its internal headers
        ${CMAKE_CURRENT_SOURCE_DIR}/C
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# install the target and create export-set
install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} # bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME} # include/lzma
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} # include
)
# generate and install export file
install(EXPORT "${PROJECT_NAME}Targets"
    FILE "${PROJECT_NAME}Targets.cmake"
    DESTINATION "share/${PROJECT_NAME}"
)
# create config file
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "share/${PROJECT_NAME}"
)
# install config files
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    DESTINATION "share/${PROJECT_NAME}"
)
