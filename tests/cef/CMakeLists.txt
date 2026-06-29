# Copyright (c) 2014 The Chromium Embedded Framework Authors. All rights
# reserved. Use of this source code is governed by a BSD-style license that
# can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.28)

project(cefsimple)

# it won't actually work with non-vcpkg CEF, because this sample sources now have include paths
# as `#include <cef/something.h>` instead of default (and retarded) `#include "include/something.h"`,
# so there isn't much point to have this option, really
option(USING_PACKAGE_MANAGER "CEF is resolved with a package manager (vcpkg)" 1)

if(NOT USING_PACKAGE_MANAGER)
    if(NOT DEFINED CEF_ROOT)
        message(FATAL_ERROR "CEF_ROOT is not set")
    endif()

    if(NOT EXISTS "${CEF_ROOT}" OR NOT IS_DIRECTORY "${CEF_ROOT}")
        message(FATAL_ERROR "CEF_ROOT does not exist or is not a directory")
    endif()

    if(EXISTS "${CEF_ROOT}/cmake" AND IS_DIRECTORY "${CEF_ROOT}/cmake")
        list(APPEND CMAKE_MODULE_PATH "${CEF_ROOT}/cmake")
    else()
        message(FATAL_ERROR "CEF_ROOT does not contain a directory with CMake modules")
    endif()
endif()

find_package(CEF REQUIRED)

if(USING_PACKAGE_MANAGER)
    find_package(libcef_dll_wrapper CONFIG REQUIRED)
else()
    add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)
    add_library(cef::libcef_dll_wrapper ALIAS libcef_dll_wrapper)
endif()

set(CEFSIMPLE_SRCS
    simple_app.cc
    simple_app.h
    simple_handler.cc
    simple_handler.h
)
set(CEFSIMPLE_SRCS_LINUX
    cefsimple_linux.cc
    simple_handler_linux.cc
)
set(CEFSIMPLE_SRCS_MAC
    cefsimple_mac.mm
    simple_handler_mac.mm
)
set(CEFSIMPLE_SRCS_WINDOWS
    cefsimple_win.cc
    resource.h
    simple_handler_win.cc
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_SRCS)

set(CEFSIMPLE_WIN_SRCS_WINDOWS
    win/cefsimple.rc
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_WIN_SRCS)

set(CEFSIMPLE_SRCS
    ${CEFSIMPLE_SRCS}
    ${CEFSIMPLE_WIN_SRCS}
    #render_app.cc
)

set(CEFSIMPLE_HELPER_SRCS_MAC
    process_helper_mac.cc
    render_app.cc
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_HELPER_SRCS)

# cefsimple resources
set(CEFSIMPLE_RESOURCES_MAC_SRCS_MAC
    mac/Info.plist.in
    mac/cefsimple.icns
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_RESOURCES_MAC_SRCS)

set(CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS_MAC
    mac/English.lproj/InfoPlist.strings
    mac/English.lproj/MainMenu.xib
)
APPEND_PLATFORM_SOURCES(CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS)

set(CEFSIMPLE_RESOURCES_SRCS
    ${CEFSIMPLE_RESOURCES_MAC_SRCS}
    ${CEFSIMPLE_RESOURCES_MAC_ENGLISH_LPROJ_SRCS}
)

set(CEF_TARGET ${CMAKE_PROJECT_NAME})
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CEF_HELPER_TARGET "cefsimple_Helper")
    set(CEF_HELPER_OUTPUT_NAME "cefsimple Helper")
else()
    ADD_LOGICAL_TARGET("libcef_lib" "${CEF_LIB_DEBUG}" "${CEF_LIB_RELEASE}")
endif()

# determine the target output directory
SET_CEF_TARGET_OUT_DIR()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")

    add_executable(${CEF_TARGET} ${CEFSIMPLE_SRCS})
    SET_EXECUTABLE_TARGET_PROPERTIES(${CEF_TARGET})
    if(NOT USING_PACKAGE_MANAGER)
        add_dependencies(${CEF_TARGET} libcef_dll_wrapper)
    endif()
    target_link_libraries(${CEF_TARGET}
        libcef_lib
        cef::libcef_dll_wrapper
        ${CEF_STANDARD_LIBS}
    )

    # set rpath so that libraries can be placed next to the executable
    set_target_properties(${CEF_TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN")
    set_target_properties(${CEF_TARGET} PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
    set_target_properties(${CEF_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CEF_TARGET_OUT_DIR})

    COPY_FILES("${CEF_TARGET}" "${CEF_BINARY_FILES}" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}")
    COPY_FILES("${CEF_TARGET}" "${CEF_RESOURCE_FILES}" "${CEF_RESOURCE_DIR}" "${CEF_TARGET_OUT_DIR}")
    if (EXISTS "${CEF_BINARY_DIR}/libminigbm.so")
        COPY_FILES(
            "${CEF_TARGET}"
            "libminigbm.so"
            "${CEF_BINARY_DIR}"
            "${CEF_TARGET_OUT_DIR}"
        )
    endif()

  # set SUID permissions on the chrome-sandbox target
  SET_LINUX_SUID_PERMISSIONS("${CEF_TARGET}" "${CEF_TARGET_OUT_DIR}/chrome-sandbox")

elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")

    option(OPTION_USE_ARC "Build with ARC (automatic Reference Counting) on macOS" ON)
    if(OPTION_USE_ARC)
        list(APPEND CEF_COMPILER_FLAGS
            "-fobjc-arc"
        )
        set_target_properties(${target}
            PROPERTIES
                CLANG_ENABLE_OBJC_ARC "YES"
        )
    endif()

    set(CEF_APP "${CEF_TARGET_OUT_DIR}/${CEF_TARGET}.app")

    set(EXECUTABLE_NAME "${CEF_TARGET}")
    set(PRODUCT_NAME "${CEF_TARGET}")

    add_executable(${CEF_TARGET} MACOSX_BUNDLE ${CEFSIMPLE_RESOURCES_SRCS} ${CEFSIMPLE_SRCS})
    SET_EXECUTABLE_TARGET_PROPERTIES(${CEF_TARGET})
    if(NOT USING_PACKAGE_MANAGER)
        add_dependencies(${CEF_TARGET} libcef_dll_wrapper)
    endif()
    target_link_libraries(${CEF_TARGET}
        cef::libcef_dll_wrapper
        ${CEF_STANDARD_LIBS}
    )
    set_target_properties(${CEF_TARGET} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/mac/Info.plist.in
    )

    COPY_MAC_FRAMEWORK("${CEF_TARGET}" "${CEF_BINARY_DIR}" "${CEF_APP}")

    foreach(_suffix_list ${CEF_HELPER_APP_SUFFIXES})
        string(REPLACE ":" ";" _suffix_list ${_suffix_list})
        list(GET _suffix_list 0 _name_suffix)
        list(GET _suffix_list 1 _target_suffix)
        list(GET _suffix_list 2 _plist_suffix)

        set(_helper_target "${CEF_HELPER_TARGET}${_target_suffix}")
        set(_helper_output_name "${CEF_HELPER_OUTPUT_NAME}${_name_suffix}")

        # create helper-specific variants of the helper-Info.plist file
        #
        # the configure_file command (which is executed as part of MACOSX_BUNDLE_INFO_PLIST)
        # uses global environment variables and would insert the wrong values with multiple targets
        set(_helper_info_plist "${CMAKE_CURRENT_BINARY_DIR}/helper-Info${_target_suffix}.plist")
        file(READ "${CMAKE_CURRENT_SOURCE_DIR}/mac/helper-Info.plist.in" _plist_contents)
        string(REPLACE "\${EXECUTABLE_NAME}" "${_helper_output_name}" _plist_contents ${_plist_contents})
        string(REPLACE "\${PRODUCT_NAME}" "${_helper_output_name}" _plist_contents ${_plist_contents})
        string(REPLACE "\${BUNDLE_ID_SUFFIX}" "${_plist_suffix}" _plist_contents ${_plist_contents})
        file(WRITE ${_helper_info_plist} ${_plist_contents})

        add_executable(${_helper_target} MACOSX_BUNDLE ${CEFSIMPLE_HELPER_SRCS})
        SET_EXECUTABLE_TARGET_PROPERTIES(${_helper_target})
        if(NOT USING_PACKAGE_MANAGER)
            add_dependencies(${_helper_target} libcef_dll_wrapper)
        endif()
        target_link_libraries(${_helper_target}
            cef::libcef_dll_wrapper
            ${CEF_STANDARD_LIBS}
        )
        set_target_properties(${_helper_target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST ${_helper_info_plist}
            OUTPUT_NAME ${_helper_output_name}
        )

        add_dependencies(${CEF_TARGET} "${_helper_target}")

        add_custom_command(
            TARGET ${CEF_TARGET}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_TARGET_OUT_DIR}/${_helper_output_name}.app"
                    "${CEF_APP}/Contents/Frameworks/${_helper_output_name}.app"
            VERBATIM
        )
    endforeach()

    # Xcode generator can support this via the set_target_properties RESOURCE
    # directive, but that doesn't properly handle nested resource directories,
    # so remove these prefixes from input file paths
    set(PREFIXES "mac/")
    COPY_MAC_RESOURCES(
        "${CEFSIMPLE_RESOURCES_SRCS}"
        "${PREFIXES}"
        "${CEF_TARGET}"
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CEF_APP}"
    )

elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")

    if(USE_SANDBOX)
        add_library(${CEF_TARGET} SHARED ${CEFSIMPLE_SRCS})
        SET_LIBRARY_TARGET_PROPERTIES(${CEF_TARGET})

        COPY_SINGLE_FILE(
            ${CEF_TARGET}
            ${CEF_BINARY_DIR}/bootstrap.exe
            ${CEF_TARGET_OUT_DIR}/${CEF_TARGET}.exe
        )

        if (CMAKE_GENERATOR MATCHES "Visual Studio")
            # make the bootstrap binary the default command for the Visual Studio debugger
            set_target_properties(${CEF_TARGET} PROPERTIES
                VS_DEBUGGER_COMMAND "$<TARGET_FILE_DIR:${CEF_TARGET}>/${CEF_TARGET}.exe"
            )
        endif()
    else()
        add_executable(${CEF_TARGET} WIN32 ${CEFSIMPLE_SRCS})
        SET_EXECUTABLE_TARGET_PROPERTIES(${CEF_TARGET})

        ADD_WINDOWS_MANIFEST("${CMAKE_CURRENT_SOURCE_DIR}/win" "${CEF_TARGET}" "exe")
    endif()

    if(NOT USING_PACKAGE_MANAGER)
        add_dependencies(${CEF_TARGET} libcef_dll_wrapper)
    endif()
    target_link_libraries(${CEF_TARGET}
        libcef_lib
        cef::libcef_dll_wrapper
        ${CEF_STANDARD_LIBS}
    )

    COPY_FILES("${CEF_TARGET}" "${CEF_BINARY_FILES}" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}")
    COPY_FILES("${CEF_TARGET}" "${CEF_RESOURCE_FILES}" "${CEF_RESOURCE_DIR}" "${CEF_TARGET_OUT_DIR}")

    if(USE_SANDBOX)
        # LPAC ACLs are required for Windows sandbox support
        SET_LPAC_ACLS("${CEF_TARGET}")
    endif()

else()

    message(FATAL_ERROR "Unsupported target platform")

endif()

# --- installation

include(GNUInstallDirs)

set(EXECUTABLE_INSTALLATION_PATH ${CMAKE_INSTALL_BINDIR}/${CEF_TARGET})

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    install(TARGETS ${CEF_TARGET}
        BUNDLE DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
else()
    install(TARGETS ${CEF_TARGET}
        RUNTIME DESTINATION ${EXECUTABLE_INSTALLATION_PATH}
    )
endif()
