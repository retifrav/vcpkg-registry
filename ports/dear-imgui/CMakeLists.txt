cmake_minimum_required(VERSION 3.15)

project("DearImGui"
    VERSION 1.88.0
)

option(BACKEND_OPENGL2 "OpenGL 2 graphics backend" 0)
option(BACKEND_OPENGL3 "OpenGL 3 graphics backend" 1)
option(BACKEND_GLFW    "GLFW backend"              1)
option(BACKEND_SDL     "SDL backend"               0)
# ...and so on

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(${PROJECT_NAME})

set(sources
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui_draw.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui_tables.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui_widgets.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/misc/cpp/imgui_stdlib.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui_demo.cpp
)
set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/imgui.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imconfig.h
    ${CMAKE_CURRENT_SOURCE_DIR}/misc/cpp/imgui_stdlib.h
)

if(BACKEND_OPENGL2)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_opengl2.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_opengl2.h
    )
endif()

if(BACKEND_OPENGL3)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_opengl3.h
    )
endif()

if(BACKEND_GLFW)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_glfw.h
    )
endif()

if(BACKEND_SDL)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_sdl.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_sdl.h
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
        ${CMAKE_CURRENT_SOURCE_DIR}/misc/cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/backends
        ${CMAKE_CURRENT_SOURCE_DIR}/examples/libs/glfw/include
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

decovar_vcpkg_cmake_install()
