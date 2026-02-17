cmake_minimum_required(VERSION 3.28)

set(ASIO_VERSION "0.0.0" CACHE STRING "Asio version")

project(asio VERSION ${ASIO_VERSION})

option(ASIO_COROUTINE "Enable launching coroutines with spawn() (requires Boost)" 0)
option(ASIO_SSL "Enabled SSL support (requires OpenSSL)" 0)
option(ASIO_REGEX "Enable using read_until() or async_read_until() overloads with regular expressions (requires Boost)" 0)

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_library(${PROJECT_NAME} INTERFACE)
add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS ${PROJECT_NAME})

find_package(Threads)
if(Threads_FOUND)
    target_link_libraries(asio INTERFACE Threads::Threads)
endif()

if(ASIO_COROUTINE)
    find_package(boost_coroutine CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME} INTERFACE Boost::coroutine)
    #target_compile_definitions(${CMAKE_PROJECT_NAME} INTERFACE "HAS_BOOST_COROUTINE_OR_SOMETHING?")
endif()

if(ASIO_SSL)
    find_package(OpenSSL CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME}
        INTERFACE
            OpenSSL::SSL
            OpenSSL::Crypto
    )
    #target_compile_definitions(${CMAKE_PROJECT_NAME} INTERFACE "HAS_OPENSSL_OR_SOMETHING?")
endif()

if(ASIO_REGEX)
    find_package(boost_regex CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME} INTERFACE Boost::regex)
    #target_compile_definitions(${CMAKE_PROJECT_NAME} INTERFACE "HAS_BOOST_REGEX_OR_SOMETHING?")
endif()

# is that how this was supposed to work about their "standalone" thing?
if(
    NOT ASIO_COROUTINE
    AND
    NOT ASIO_REGEX
    #AND
    #NOT ASIO_SSL
)
    target_compile_definitions(${PROJECT_NAME} INTERFACE "ASIO_STANDALONE")
endif()

target_include_directories(${PROJECT_NAME}
    INTERFACE
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/asio/include>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set(PROJECT_NAMESPACE_FOR_PACKAGE "${PROJECT_NAME}")
include("Installing.cmake")

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/asio/include/asio
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
# wtf is this headers structure
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/asio/include/asio.hpp
    DESTINATION include/asio/
)
