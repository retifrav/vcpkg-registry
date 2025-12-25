cmake_minimum_required(VERSION 3.22)

project(
    "png-zlib"
    DESCRIPTION "Something that uses png (and zlib)"
    VERSION 1.2.3
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

set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

option(CRT_LINKAGE_STATIC "Link MSVC runtime statically" 0)
option(INSTALL_DEPENDENCIES_TOO "Installing vcpkg-resolved dependencies" 0)

# global debug postfix for libraries (executables still need to set it)
set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND CRT_LINKAGE_STATIC)
    #add_compile_options("/MT")
    if(POLICY CMP0091)
        cmake_policy(SET CMP0091 NEW)
    endif()
    set_property(TARGET ${CMAKE_PROJECT_NAME}
        PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
endif()

# here it's a top-level project for an executable, so CMAKE_PROJECT_NAME is fine
add_executable(${CMAKE_PROJECT_NAME})

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        src/main.cpp
)

find_package(zlib CONFIG REQUIRED)
find_package(png CONFIG REQUIRED)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        zlib
        png
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME})
install(FILES
    resources/some.png
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)
if(INSTALL_DEPENDENCIES_TOO)
    install(DIRECTORY "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/"
        DESTINATION ${CMAKE_INSTALL_PREFIX}
    )
endif()
