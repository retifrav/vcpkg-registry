cmake_minimum_required(VERSION 3.22)

project("wtl"
    VERSION 10.0.10320
)

add_library(${PROJECT_NAME} INTERFACE)

set(public_headers
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlapp.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlcrack.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlctrls.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlctrlw.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlctrlx.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlddx.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atldlgs.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atldwm.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlfind.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlframe.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlgdi.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlmisc.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlprint.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlres.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlribbon.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlscrl.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlsplit.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atltheme.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atluser.h
    ${CMAKE_CURRENT_SOURCE_DIR}/Include/atlwinx.h
)

target_include_directories(${PROJECT_NAME}
    INTERFACE
        # where top-level project will look for the library's public headers
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        # where external projects will look for the library's public headers
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${public_headers}")

include("${CMAKE_CURRENT_SOURCE_DIR}/Installing.cmake")
