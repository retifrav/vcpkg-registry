cmake_minimum_required(VERSION 3.22)

set(DIRECTX_SHADER_COMPILER_HEXOPS_VERSION "0.0.0" CACHE STRING "DirectXShaderCompiler version")

project("MachSiegbertVogtDXCSA"
    VERSION "${DIRECTX_SHADER_COMPILER_HEXOPS_VERSION}"
)

add_library(${PROJECT_NAME})

set(sources
    tools/clang/tools/dxcompiler/MachSiegbertVogtDXCSA.cpp
)
set(public_headers
    tools/clang/tools/dxcompiler/MachSiegbertVogtDXCSA.h
)

target_sources(${PROJECT_NAME}
    PRIVATE
        ${sources}
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        # where the library itself will look for its internal headers
        ${CMAKE_CURRENT_SOURCE_DIR}/tools/clang/tools/dxcompiler
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tools/clang/tools/dxcompiler>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

set(PROJECT_INCLUDES_NAME_FOR_PACKAGE "DirectXShaderCompilerHexops")
set(PROJECT_NAMESPACE_FOR_PACKAGE "DirectXShaderCompilerHexops")
include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
