cmake_minimum_required(VERSION 3.22)

project(tl
    LANGUAGES CXX
    VERSION "1.0.0"
)

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_executable(${CMAKE_PROJECT_NAME})

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        src/main.cpp
)

find_package(some CONFIG REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE some::some)

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX}
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME})
