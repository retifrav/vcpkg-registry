# it's a miracle that it builds at least as STATIC
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://dawn.googlesource.com/dawn
    REF ad853f80af9b236fa3aa6be6dcd2facb26430565
    PATCHES
        dependencies-discovery-and-installation.patch # if only Google developers knew how to make proper CMake packages
        missing-includes.patch                        # and had all the includes correct
        typos.patch                                   # or least were careful
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")

vcpkg_find_acquire_program(PYTHON3)
#message(STATUS "PYTHON3: ${PYTHON3}")
# if you want this Python to be available in the PATH
# get_filename_component(PYTHON_DIR ${PYTHON3} DIRECTORY)
# vcpkg_add_to_path("${PYTHON_DIR}") # you might want to PREPEND it
#
x_vcpkg_get_python_packages(
    PYTHON_VERSION "3"
    PYTHON_EXECUTABLE ${PYTHON3}
    PACKAGES Jinja2 MarkupSafe
    OUT_PYTHON_VAR "PYTHON_VENV"
)
# in case of venv you'd want that one to be available in the PATH
get_filename_component(PYTHON_VENV_DIR ${PYTHON_VENV} DIRECTORY)
#message(STATUS "PYTHON_VENV: ${PYTHON_VENV}")
vcpkg_add_to_path("${PYTHON_VENV_DIR}") # you might want to PREPEND it

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        glfw DAWN_USE_GLFW
        #
        # OpenGL-related options are enabled depending on the platform in the project's CMakeLists.txt,
        # so it isn't clear how to deal with them here
        # opengl DAWN_ENABLE_DESKTOP_GL
        # opengl DAWN_ENABLE_OPENGLES
        #
        vulkan DAWN_ENABLE_VULKAN
        #
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
        -DDAWN_FETCH_DEPENDENCIES=0
        -DTINT_BUILD_TESTS=0
        -DTINT_BUILD_DOCS=0
        -DTINT_BUILD_CMD_TOOLS=0
        -DTINT_BUILD_GLSL_VALIDATOR=0 # might need to be a feature
        -DDAWN_BUILD_SAMPLES=0
        -DDAWN_ENABLE_INSTALL=1
    MAYBE_UNUSED_VARIABLES
        DAWN_FETCH_DEPENDENCIES
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "Dawn"
    CONFIG_PATH "share/Dawn"
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

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
