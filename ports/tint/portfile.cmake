# all its targets are explicitly STATIC
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://dawn.googlesource.com/tint
    REF d5ec9a7bdb8071a92d817206a666f480a0e23932
    PATCHES
        dependencies-discovery-and-installation.patch # if only Google developers knew how to make proper CMake packages
        no-testing-headers.patch # there are no such headers in the sources
        disabled-warnings.patch # disabled some warning/errors, mostly to prevent build failing with Emscripten
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")

vcpkg_find_acquire_program(PYTHON3)
# if we want this Python to be available in the PATH
# get_filename_component(PYTHON_DIR ${PYTHON3} DIRECTORY)
# vcpkg_add_to_path("${PYTHON_DIR}") # you might want to PREPEND it
#
x_vcpkg_get_python_packages(
    PYTHON_VERSION "3"
    PYTHON_EXECUTABLE ${PYTHON3}
    PACKAGES Jinja2 MarkupSafe
    OUT_PYTHON_VAR "PYTHON_VENV"
)
# in case of venv we want that one to be available in the PATH
get_filename_component(PYTHON_VENV_DIR ${PYTHON_VENV} DIRECTORY)
vcpkg_add_to_path("${PYTHON_VENV_DIR}") # you might want to PREPEND it
#message(STATUS "PYTHON_VENV: ${PYTHON_VENV}")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        spv-reader  TINT_BUILD_SPV_READER
        spv-writer  TINT_BUILD_SPV_WRITER
        wgsl-reader TINT_BUILD_WGSL_READER
        wgsl-writer TINT_BUILD_WGSL_WRITER
        glsl-writer TINT_BUILD_GLSL_WRITER
        hlsl-writer TINT_BUILD_HLSL_WRITER
        msl-writer  TINT_BUILD_MSL_WRITER
        fuzzers     TINT_BUILD_FUZZERS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DTINT_BUILD_BENCHMARKS=0
        -DTINT_BUILD_CMD_TOOLS=0
        -DTINT_BUILD_DOCS=0
        #-DTINT_BUILD_SAMPLES=0 # might not be available in this version yet
        -DTINT_BUILD_TESTS=0
        -DTINT_ENABLE_INSTALL=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "tint"
    CONFIG_PATH "share/tint"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

# fixing retarded include paths in tint headers
file(GLOB_RECURSE TINT_HEADERS
    "${CURRENT_PACKAGES_DIR}/include/tint/*.h"
)
foreach(TINT_HEADER IN ITEMS ${TINT_HEADERS})
    vcpkg_replace_string(
        ${TINT_HEADER}
            [=[#include "src/tint/]=]
            [=[#include "tint/]=]
    )
endforeach()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
