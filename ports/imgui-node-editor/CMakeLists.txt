cmake_minimum_required(VERSION 3.28)

set(IMGUINODEEDITOR_VERSION "0.0.0" CACHE STRING "Project version")

project("ImGuiNodeEditor"
    VERSION "${IMGUINODEEDITOR_VERSION}"
)

set(REQUIRED_CPP_STANDARD 14 CACHE STRING "Required C++ standard")
if(DEFINED CMAKE_CXX_STANDARD)
    if(CMAKE_CXX_STANDARD LESS ${REQUIRED_CPP_STANDARD})
        message(FATAL_ERROR "This project requires at least C++${REQUIRED_CPP_STANDARD}")
    endif()
else()
    set(CMAKE_CXX_STANDARD ${REQUIRED_CPP_STANDARD})
endif()
set(CMAKE_CXX_STANDARD_REQUIRED YES)
if(NOT DEFINED CMAKE_CXX_EXTENSIONS)
    set(CMAKE_CXX_EXTENSIONS NO)
endif()

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_library(${PROJECT_NAME})

set(sources
    crude_json.cpp
    imgui_canvas.cpp
    imgui_node_editor.cpp
    imgui_node_editor_api.cpp
)
set(public_headers
    crude_json.h
    imgui_canvas.h
    imgui_node_editor.h
)

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

target_compile_features(${PROJECT_NAME} PUBLIC "cxx_std_${REQUIRED_CPP_STANDARD}")

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

find_package(dearimgui CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME}
    PRIVATE # PUBLIC
        dearimgui::dearimgui
)

#set(PROJECT_INCLUDES_NAME_FOR_PACKAGE "imgui-node-editor")
set(PROJECT_NAMESPACE_FOR_PACKAGE "dearimgui")
include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
