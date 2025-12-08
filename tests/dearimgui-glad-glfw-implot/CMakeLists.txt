cmake_minimum_required(VERSION 3.22)

project("dearimgui-glad-glfw-implot"
    DESCRIPTION "Testing vcpkg ports for Dear ImGui, glad, GLFW and ImPlot"
    LANGUAGES CXX
)

set(REQUIRED_CPP_STANDARD 17 CACHE STRING "Required C++ standard")
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

set(CMAKE_EXPORT_COMPILE_COMMANDS YES)

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

option(CRT_LINKAGE_STATIC "Link MSVC runtime statically" 0)

if(WIN32 AND CRT_LINKAGE_STATIC)
    #add_compile_options("/MT")
    if(POLICY CMP0091)
        cmake_policy(SET CMP0091 NEW)
    endif()
    set_property(TARGET ${CMAKE_PROJECT_NAME}
        PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
endif()

add_executable(${CMAKE_PROJECT_NAME})

set(sources
    src/main.cpp
    src/functions.cpp
)

set(resource_files
    JetBrainsMono-ExtraLight.ttf
)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${sources}
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        src
)

find_package(OpenGL REQUIRED)
find_package(dearimgui CONFIG REQUIRED)
find_package(glad CONFIG REQUIRED)
find_package(glfw3 CONFIG REQUIRED)
find_package(implot CONFIG REQUIRED)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${OPENGL_gl_LIBRARY}
        dearimgui::dearimgui
        dearimgui::implot
        glad::glad
        glfw
)


if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            "-framework Cocoa"
            "-framework IOKit"
            "-framework CoreVideo"
    )
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(Threads REQUIRED)
    find_package(X11 REQUIRED)

    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            ${CMAKE_DL_LIBS}
            ${CMAKE_THREAD_LIBS_INIT}
            ${X11_LIBRARIES}
    )
endif()

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME}
    COMPONENT ${CMAKE_PROJECT_NAME}
)
install(FILES
    ${resource_files}
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT ${CMAKE_PROJECT_NAME}
)
