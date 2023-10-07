cmake_minimum_required(VERSION 3.22)

project(
    "another-tool"
    DESCRIPTION "Another tool that does something"
    VERSION 0.9.2
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED 1)

# global debug postfix for libraries (executables still need to set it)
set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

# here it's a top-level project, so CMAKE_PROJECT_NAME is fine
add_executable(${CMAKE_PROJECT_NAME})

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX}
)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        src/main.cpp
)

find_package(SomeLibrary CONFIG REQUIRED)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        prjct::SomeLibrary
)

# for CMAKE_INSTALL_LIBDIR, CMAKE_INSTALL_BINDIR, CMAKE_INSTALL_INCLUDEDIR and others
include(GNUInstallDirs)

# install the target
install(TARGETS ${PROJECT_NAME})

