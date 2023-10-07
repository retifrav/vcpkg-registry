cmake_minimum_required(VERSION 3.22)

set(namespace "prjct")
project(
    ${namespace}
    DESCRIPTION "Some project"
    VERSION 0.9.2
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED 1)

# global debug postfix for libraries (executables still need to set it)
set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_subdirectory(src)
