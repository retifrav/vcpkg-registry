cmake_minimum_required(VERSION 3.28)

project(gsl C)

# function to extract parameters from makefile, space-separated values are returned as lists
function(extract_from_makefile PATTERN RETURN FILEPATH)
    file(READ ${FILEPATH} MAKEFILE_CONTENT)
    string(REGEX MATCH "${PATTERN}" CONTENTS "${MAKEFILE_CONTENT}")
    set(CONTENTS ${CMAKE_MATCH_1})
    # split string into list
    string(REGEX REPLACE "([\t ]+(\\\\\n)?)+" ";" CONTENTS "${CONTENTS}")
    string(REGEX REPLACE "[\t ]*\\\\\n[\t ]*;" "" CONTENTS "${CONTENTS}")
    if("${CONTENTS}" STREQUAL "")
        message(AUTHOR_WARNING "No match for \"${PATTERN}\" found in file ${FILEPATH}")
    endif()
    # return
    set(${RETURN} ${CONTENTS} PARENT_SCOPE)
endfunction(extract_from_makefile)

# function to extract C sources from makefile
function(extract_sources SUBFOLDER ALLSOURCES)
    extract_from_makefile(
        "lib[a-zA-Z1-9_]*_la_SOURCES[ \t]*=[ \t]*(((\\\\\n)?[^\n])*)"
        SOURCEFILES "${SUBFOLDER}/Makefile.am"
    )
    # add the folder in front of the file names
    string(REGEX REPLACE "([^;]+)" "${SUBFOLDER}/\\1" SOURCEFILES "${SOURCEFILES}")
    # return
    set(${ALLSOURCES} ${${ALLSOURCES}} ${SOURCEFILES} PARENT_SCOPE)
endfunction(extract_sources)

set(SOURCES)
set(CBLAS_SOURCES)
extract_from_makefile("SUBDIRS = (((\\\\\n)?[^\n])*)" FOLDERS "./Makefile.am")
extract_sources("." SOURCES)
foreach(DIR IN LISTS FOLDERS)
    if("${DIR}" STREQUAL "cblas")
        extract_sources("${DIR}" CBLAS_SOURCES)
    else()
        extract_sources("${DIR}" SOURCES)
    endif()
endforeach()

file(READ gsl_types.h GSLTYPES_H)
string(REPLACE "#ifdef WIN32" "#ifdef _WIN32" GSLTYPES_H "${GSLTYPES_H}")
if(BUILD_SHARED_LIBS)
    string(REPLACE "#  ifdef GSL_DLL" "#  if 1 /*GSL_DLL*/" GSLTYPES_H "${GSLTYPES_H}")
endif()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/gsl_types.h "${GSLTYPES_H}")

file(GLOB_RECURSE PUBLIC_HEADERS gsl*.h)
list(APPEND PUBLIC_HEADERS ${CMAKE_CURRENT_BINARY_DIR}/gsl_types.h)

# FindGSL.cmake module needs to be able to distinguish between Release and Debug libraries
set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

add_library(gslcblas ${CBLAS_SOURCES})
set_target_properties(gslcblas
    PROPERTIES
        # not a good idea to export all the symbols
        WINDOWS_EXPORT_ALL_SYMBOLS YES
)

add_library(gsl ${SOURCES})
set_target_properties(gsl
    PROPERTIES
        DEFINE_SYMBOL DLL_EXPORT
        WINDOWS_EXPORT_ALL_SYMBOLS YES
)
target_link_libraries(gsl PUBLIC gslcblas)

set_target_properties(gsl
    PROPERTIES
        PUBLIC_HEADER "${PUBLIC_HEADERS}"
)

target_include_directories(gslcblas
    PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}
)
target_include_directories(gsl
    PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# need to copy all headers to the gsl directory for the build
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/gsl)
file(
    COPY ${PUBLIC_HEADERS}
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/gsl"
)

include(GNUInstallDirs)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/gsl.pc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/gsl.pc" @ONLY
)
install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/gsl.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
)

install(TARGETS gsl gslcblas
    #RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} # bin
    #LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    #ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    PUBLIC_HEADER DESTINATION include/gsl
)
