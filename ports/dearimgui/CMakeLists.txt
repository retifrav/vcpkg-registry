cmake_minimum_required(VERSION 3.22)

set(DEARIMGUI_VERSION "0.0.0" CACHE STRING "Dear ImGui version")

project("dearimgui"
    VERSION "${DEARIMGUI_VERSION}"
)

option(BACKEND_OPENGL2 "OpenGL 2 graphics backend"  0)
option(BACKEND_OPENGL3 "OpenGL 3 graphics backend"  1)
option(BACKEND_VULKAN  "Vulkan graphics backend"    0)
option(BACKEND_GLFW    "GLFW backend"               1)
#option(BACKEND_SDL     "SDL backend"                0)
# ...and so on
option(PLATFORM_WIN32    "Support for win32"        0)
option(WITH_INTERNAL     "Using internal header(s)" 0)
option(WITH_STB_TEXTEDIT "Using STB textedit"       0)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

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

if(BACKEND_OPENGL2 OR BACKEND_OPENGL3)
    cmake_policy(PUSH)
    if(POLICY CMP0072)
        cmake_policy(SET CMP0072 NEW) # prefer GLVND
    endif()
    find_package(OpenGL REQUIRED)
    cmake_policy(POP)

    #message(STATUS "OPENGL_FOUND: ${OPENGL_FOUND}")
    #message(STATUS "OPENGL_INCLUDE_DIR: ${OPENGL_INCLUDE_DIR}")

    target_include_directories(${PROJECT_NAME}
        PRIVATE
            ${OPENGL_INCLUDE_DIR}
    )

    target_link_libraries(${PROJECT_NAME}
        PUBLIC # PRIVATE?
            ${OPENGL_LIBRARIES}
    )
endif()

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

if(BACKEND_VULKAN)
    find_package(Vulkan REQUIRED)
    target_include_directories(${PROJECT_NAME}
        PRIVATE
            ${Vulkan_INCLUDE_DIRS}
    )
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
            ${Vulkan_LIBRARIES}
    )

    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_vulkan.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_vulkan.h
    )
endif()

if(BACKEND_GLFW)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
    )
    target_include_directories(${PROJECT_NAME}
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/examples/libs/glfw/include
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_glfw.h
    )

    find_package(glfw3 CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME} PUBLIC glfw)
endif()

# if(BACKEND_SDL)
#     list(APPEND sources
#         ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_sdl.cpp
#     )
#     list(APPEND public_headers
#         ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_sdl.h
#     )
# endif()

if(PLATFORM_WIN32)
    list(APPEND sources
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_win32.cpp
    )
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/backends/imgui_impl_win32.h
    )
endif()

if(WITH_INTERNAL)
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/imgui_internal.h
    )
endif()

if(WITH_STB_TEXTEDIT)
    list(APPEND public_headers
        ${CMAKE_CURRENT_SOURCE_DIR}/imstb_textedit.h
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
    PUBLIC
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

#set(PROJECT_INCLUDES_NAME_FOR_PACKAGE "imgui")
set(PROJECT_NAMESPACE_FOR_PACKAGE "dearimgui")
include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
