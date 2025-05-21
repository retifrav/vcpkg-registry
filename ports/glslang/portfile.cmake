vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/glslang.git
    REF 99ee11b0106b48f06fb9e2a324ba928b8316cc33
    PATCHES
        001-threads-and-installation.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path("${PYTHON_PATH}")

# this is not in vcpkg_check_features() because on iOS executables will require BUNDLE DESTINATION,
# so that will fail, and on WASM tools are not built(?), so they will fail to copy with vcpkg_copy_tools()
set(BUILD_BINARIES 0)
if("tools" IN_LIST FEATURES AND NOT VCPKG_TARGET_IS_IOS AND NOT VCPKG_TARGET_IS_EMSCRIPTEN)
    set(BUILD_BINARIES 1)
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        opt ENABLE_OPT
        opt ALLOW_EXTERNAL_SPIRV_TOOLS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_EXTERNAL=0
        -DENABLE_GLSLANG_BINARIES=${BUILD_BINARIES}
        -DGLSLANG_ENABLE_INSTALL=1
        -DGLSLANG_TESTS=0
        -DGLSLANG_TESTS_DEFAULT=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if(NOT BUILD_BINARIES)
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/bin"
    )
else()
    vcpkg_copy_tools(
        TOOL_NAMES
            glslang
            glslangValidator
            spirv-remap
        AUTO_CLEAN
    )
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
