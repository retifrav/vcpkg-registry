# it might actually build as a SHARED library in newer versions
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://dawn.googlesource.com/dawn
    REF 740d2502dbbd719a76c5a8d3fb4dac1b5363f42e
    PATCHES
        001-dependencies-discovery-and-installation.patch
        002-string-view-type.patch # actually, the correct resolution here should be to build Abseil with C++17 and propagate the requirement
        003-shader-spirv-wrong-type.patch
        004-missing-includes.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/FindD3D12.cmake" DESTINATION "${SOURCE_PATH}/src/cmake")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")

# starting with Emscripten 4.0.3(?) this is no longer needed(?)
# https://github.com/emscripten-core/emscripten/commit/b31dd92a4b1b7a0cbdc1b1b3f4fb22e8a0726aea
# https://dawn.googlesource.com/dawn/+/3c60c992572f5c2c83be5f50f8ab3bd3aec959a9^!
if(VCPKG_TARGET_IS_EMSCRIPTEN AND "with-emscripten-tools" IN_LIST FEATURES)
    # get Emscripten tools, as they are not installed with regular Emscripten installation procedure
    # (https://github.com/emscripten-core/emscripten/blob/ac676d5e437525d15df5fd46bc2c208ec6d376a3/tools/install.py#L20-L30),
    # but Dawn does require some of those for generating stuff
    #
    # the version should probably match the one used in your project, but also both the Emscripten and the tools should be
    # of the same version, otherwise for instance using Emscripten 3.1.73 and scripts from 3.1.54 version will fail
    # with an error of undefined symbol `$stackRestore` or something
    set(EMSCRIPTEN_TOOLS_VERSION "3.1.54")
    if(NOT EXISTS "$ENV{EMSDK}/upstream/emscripten/tools/maint")
        message(STATUS
            "Emscripten installation is missing required `maint` tools, "
            "will fetch those from the original repository"
        )

        set(EMSCRIPTEN_VERSION_FILE "$ENV{EMSDK}/upstream/emscripten/emscripten-version.txt")
        if(NOT EXISTS "${EMSCRIPTEN_VERSION_FILE}")
            message(WARNING
                "[ERROR] The Emscripten version file [${EMSCRIPTEN_VERSION_FILE}] "
                "does not seem to exist, cannot determine the Emscripten version, "
                "will fallback to ${EMSCRIPTEN_TOOLS_VERSION}"
            )
        else()
            file(READ "${EMSCRIPTEN_VERSION_FILE}" EMSCRIPTEN_VERSION_FILE_CONTENT)
            # the file might (should) contain a empty line in the end of it
            string(STRIP "${EMSCRIPTEN_VERSION_FILE_CONTENT}" EMSCRIPTEN_VERSION_FILE_CONTENT)
            # the version value is quoted in that file (why the f)
            string(REPLACE "\"" "" EMSCRIPTEN_VERSION_FILE_CONTENT "${EMSCRIPTEN_VERSION_FILE_CONTENT}")
            set(EMSCRIPTEN_TOOLS_VERSION "${EMSCRIPTEN_VERSION_FILE_CONTENT}")
            message(STATUS "Emscripten version from ${EMSCRIPTEN_VERSION_FILE}: ${EMSCRIPTEN_TOOLS_VERSION}")
        endif()

        find_program(GIT git REQUIRED) # at least on (some) Windows hosts it will fail with a bare `git`
        message(STATUS "Got this Git: ${GIT}")
        execute_process(
            COMMAND ${GIT} --version
            OUTPUT_STRIP_TRAILING_WHITESPACE
            OUTPUT_VARIABLE GIT_VERSION_VALUE
            RESULT_VARIABLE GIT_VERSION_RETURN
        )
        string(REGEX MATCH "^git version ([0-9]+\.[0-9]+).*$" GIT_VERSION_VALUE_PARSED ${GIT_VERSION_VALUE})
        set(GIT_VERSION_VALUE_PARSED ${CMAKE_MATCH_1})
        message(STATUS "Git version: ${GIT_VERSION_VALUE_PARSED}")

        set(EMSCRIPTEN_TOOLS ${SOURCE_PATH}/emscripten-tools)
        #
        # should be redundant, because it is always a new "clean" sources directory of the port
        #if(EXISTS ${EMSCRIPTEN_TOOLS})
        #    # remove the folder first before cloning
        #endif()
        #
        if(GIT_VERSION_VALUE_PARSED VERSION_GREATER_EQUAL "2.38")
            message(STATUS "+ sparsely cloning the Emscripten repository...")
            vcpkg_execute_required_process(
                COMMAND ${GIT} clone --depth=1 --filter=blob:none --sparse --branch ${EMSCRIPTEN_TOOLS_VERSION} git@github.com:emscripten-core/emscripten.git ${EMSCRIPTEN_TOOLS}
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
                LOGNAME git-emscripten-tools-cloning
            )
            message(STATUS "+ checking out the tools...")
            vcpkg_execute_required_process(
                COMMAND ${GIT} sparse-checkout set --no-cone /tools/maint #/src/closure-externs
                WORKING_DIRECTORY ${EMSCRIPTEN_TOOLS}
                LOGNAME git-emscripten-tools-checkout
            )
        else()
            message(STATUS "+ Git version is too old for a sparse clone/checkout, cloning the entire Emscripten repository...")
            vcpkg_execute_required_process(
                COMMAND ${GIT} clone --depth=1 --branch ${EMSCRIPTEN_TOOLS_VERSION} git@github.com:emscripten-core/emscripten.git ${EMSCRIPTEN_TOOLS}
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
                LOGNAME git-emscripten-tools-cloning
            )
        endif()
        message(STATUS "+ deploying the tools to Emscripten installation...")
        file(
            INSTALL "${EMSCRIPTEN_TOOLS}/tools/maint"
            DESTINATION "$ENV{EMSDK}/upstream/emscripten/tools"
        )
    else()
        message(STATUS
            "Emscripten installation seems to already contain required `maint` tools, "
            "won't fetch them again, however you should make sure that your current Emscripten version "
            "and the tools are both of the ${EMSCRIPTEN_TOOLS_VERSION} version; if you are not sure, "
            "then delete the `$ENV{EMSDK}/upstream/emscripten/tools/maint/` folder and restart the build"
        )
    endif()
endif()

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

set(MONOLITHIC_LIBRARY 0)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(MONOLITHIC_LIBRARY 1)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDAWN_FETCH_DEPENDENCIES=0
        -DTINT_BUILD_TESTS=0
        -DTINT_BUILD_CMD_TOOLS=0
        -DTINT_BUILD_GLSL_VALIDATOR=0 # might need to be a feature
        -DDAWN_BUILD_SAMPLES=0
        -DDAWN_BUILD_MONOLITHIC_LIBRARY=${MONOLITHIC_LIBRARY}
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

# fixing retarded include paths in tint headers
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
# this one is especially retarded
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/include/tint/utils/macros/compiler.h"
        [=[#include "utils/compiler.h"]=]
        [=[#include "dawn/utils/compiler.h"]=]
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
