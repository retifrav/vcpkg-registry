cmake_minimum_required(VERSION 3.22)

project(
    "some-tool"
    DESCRIPTION "Some tool that does something"
    VERSION ${CMAKE_PROJECT_VERSION}
)

add_executable(${PROJECT_NAME})

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX}
)

target_sources(${PROJECT_NAME}
    PRIVATE
        main.cpp
)

find_package(nlohmann_json CONFIG REQUIRED)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        SomeLibrary
        nlohmann_json::nlohmann_json
)

# for CMAKE_INSTALL_LIBDIR, CMAKE_INSTALL_BINDIR, CMAKE_INSTALL_INCLUDEDIR and others
include(GNUInstallDirs)

# install the target
install(TARGETS ${PROJECT_NAME})
