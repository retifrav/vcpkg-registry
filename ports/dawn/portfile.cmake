# it might actually build as a SHARED library in newer versions
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://dawn.googlesource.com/dawn
    REF afd3d886e5dca11c148021ea7ccf0f221c3abb2e # chromium/7802
    PATCHES
        001-dependencies-discovery-and-installation.patch
        002-string-view-type.patch # actually, the correct resolution here should be to build Abseil with C++17 and propagate the requirement
        003-missing-includes.patch
)

# do not vendor 3rd-party dependencies
file(RENAME
    "${SOURCE_PATH}/third_party"
    "${SOURCE_PATH}/third_party_will_be_deleted"
)
file(MAKE_DIRECTORY "${SOURCE_PATH}/third_party")
file(RENAME
    "${SOURCE_PATH}/third_party_will_be_deleted/emdawnwebgpu"
    "${SOURCE_PATH}/third_party/emdawnwebgpu"
)
file(COPY_FILE
    "${SOURCE_PATH}/third_party_will_be_deleted/CopyWindowsSDKDLL.cmake"
    "${SOURCE_PATH}/third_party/CopyWindowsSDKDLL.cmake"
)
file(REMOVE_RECURSE
    "${SOURCE_PATH}/third_party_will_be_deleted"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/FindD3D12.cmake" DESTINATION "${SOURCE_PATH}/src/cmake")

vcpkg_find_acquire_program(PYTHON3)
#message(STATUS "PYTHON3: ${PYTHON3}")
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

# can only be "SHARED", "STATIC" or "OFF"
set(DAWN_MONOLITHIC_LIBRARY "OFF")
if("monolithic" IN_LIST FEATURES)
    set(DAWN_MONOLITHIC_LIBRARY "STATIC")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        # by their original design any non-"OFF" value should result in FATAL_ERROR with BUILD_SHARED_LIBS,
        # which we patched out, but it is not clear how this was supposed to work at all
        set(DAWN_MONOLITHIC_LIBRARY "SHARED")
    endif()
endif()

# does not actually export targets and also installs headers into clearly incorrect path,
# so we are not using it (and probably no one does, as it simply does not produce a working package),
# and it is actually patched out in the project too
set(USING_DEFAULT_TINT_INSTALLATION 0)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDAWN_VERSION=${VERSION}
        -DDAWN_BUILD_MONOLITHIC_LIBRARY=${DAWN_MONOLITHIC_LIBRARY}
        -DDAWN_BUILD_SAMPLES=0
        -DDAWN_BUILD_TESTS=0
        -DDAWN_ENABLE_DESKTOP_GL=0 # should be set via `FEATURE_OPTIONS` from `opengl` feature
        -DDAWN_ENABLE_OPENGLES=0 # should be set via `FEATURE_OPTIONS` from `opengl` feature
        -DDAWN_FETCH_DEPENDENCIES=0
        #-DEMSCRIPTEN=${VCPKG_TARGET_IS_EMSCRIPTEN}
        -DTINT_BUILD_CMD_TOOLS=0
        -DTINT_BUILD_GLSL_VALIDATOR=0 # might need to be a feature
        -DTINT_BUILD_IR_BINARY=0 # do we need this one? Because apparently now it absolutely requires protobuf, which we didn't(?) need before
        -DTINT_BUILD_TESTS=0
        -DTINT_ENABLE_INSTALL=${USING_DEFAULT_TINT_INSTALLATION}
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
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

if(VCPKG_TARGET_IS_EMSCRIPTEN)
    # Emscripten already contains the `webgpu` folder with the same public headers,
    # and so if we keep this one from Dawn too, it will cause a conflict
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/include/webgpu"
    )
endif()

# isn't used now, but we might need it in future (when Google will fix their project),
# and then we should not forget to remove our own installation of these headers
#if(USING_DEFAULT_TINT_INSTALLATION)
#   file(RENAME
#       "${CURRENT_PACKAGES_DIR}/include/tint"
#       "${CURRENT_PACKAGES_DIR}/include/tint-tmp"
#   )
#   file(RENAME
#       "${CURRENT_PACKAGES_DIR}/include/src/tint"
#       "${CURRENT_PACKAGES_DIR}/include/tint"
#   )
#   file(COPY_FILE
#       "${CURRENT_PACKAGES_DIR}/include/tint-tmp/tint.h"
#       "${CURRENT_PACKAGES_DIR}/include/tint/tint.h"
#   )
#   file(REMOVE_RECURSE
#       "${CURRENT_PACKAGES_DIR}/include/src"
#       "${CURRENT_PACKAGES_DIR}/include/tint-tmp"
#   )
#endif()

# fixing include paths in the tint headers from our installation
if(NOT DAWN_MONOLITHIC_LIBRARY) # `STREQUAL "OFF"`
    file(GLOB_RECURSE TINT_HEADERS
        "${CURRENT_PACKAGES_DIR}/include/tint/*.h"
    )
    foreach(TINT_HEADER IN ITEMS ${TINT_HEADERS})
        vcpkg_replace_string(
            ${TINT_HEADER}
                [=[#include "src/tint/]=]
                [=[#include "tint/]=]
            IGNORE_UNCHANGED
        )
    endforeach()
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/tint/utils/macros/compiler.h"
            [=[#include "utils/compiler.h"]=]
            [=[#include "dawn/utils/compiler.h"]=]
    )
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/tint/utils/result.h"
            [=[#include "src/utils/compiler.h"]=]
            [=[#include "dawn/utils/compiler.h"]=]
    )
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
