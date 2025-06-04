# they do attempt to support building as SHARED too, but it is done in a twisted way,
# which does not work when only one type of library is built at a time
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/SPIRV-Tools.git
    REF f289d047f49fb60488301ec62bafab85573668cc
    PATCHES
        001-single-target-dependencies-and-installation.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

set(SPIRV_TOOLS_BUILD_STATIC 1)
if(NOT VCPKG_TARGET_IS_WINDOWS)
    string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" SPIRV_TOOLS_BUILD_STATIC)
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        with-source-headers SPIRV_TOOLS_INSTALL_SOURCE_HEADERS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DENABLE_RTTI=0
        -DSKIP_SPIRV_TOOLS_INSTALL=0
        -DSPIRV_SKIP_EXECUTABLES=1
        -DSPIRV_SKIP_TESTS=1
        -DSPIRV_TOOLS_BUILD_STATIC=${SPIRV_TOOLS_BUILD_STATIC}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Tools"
    CONFIG_PATH "lib/cmake/SPIRV-Tools"
    DO_NOT_DELETE_PARENT_CONFIG_PATH # don't delete the parent folder yet
)
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Tools-link"
    CONFIG_PATH "lib/cmake/SPIRV-Tools-link"
    DO_NOT_DELETE_PARENT_CONFIG_PATH # don't delete the parent folder yet
)
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Tools-lint"
    CONFIG_PATH "lib/cmake/SPIRV-Tools-lint"
    DO_NOT_DELETE_PARENT_CONFIG_PATH # don't delete the parent folder yet
)
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Tools-opt"
    CONFIG_PATH "lib/cmake/SPIRV-Tools-opt"
    DO_NOT_DELETE_PARENT_CONFIG_PATH # don't delete the parent folder yet
)
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SPIRV-Tools-reduce"
    CONFIG_PATH "lib/cmake/SPIRV-Tools-reduce"
) # after fixing up the last package, the parent folder can finally be deleted

if("with-source-headers" IN_LIST FEATURES) # the include paths are fucked up
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/spirv-tools/source/extensions.h"
            [=[#include "extension_enum.inc"]=]
            [=[#include "spirv-tools/extension_enum.inc"]=]
    )
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/spirv-tools/source/opt/instruction.h"
            [=[#include "NonSemanticShaderDebugInfo100.h"]=]
            [=[#include "spirv-tools/NonSemanticShaderDebugInfo100.h"]=]
    )
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/spirv-tools/source/opt/instruction.h"
            [=[#include "OpenCLDebugInfo100.h"]=]
            [=[#include "spirv-tools/OpenCLDebugInfo100.h"]=]
    )

    file(GLOB_RECURSE spirv_headers_source "${CURRENT_PACKAGES_DIR}/include/spirv-tools/source/*.h")
    foreach(spirv_header IN ITEMS ${spirv_headers_source})
        vcpkg_replace_string(
            "${spirv_header}"
                [=[#include "source/]=]
                [=[#include "spirv-tools/source/]=]
            IGNORE_UNCHANGED
        )
    endforeach()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
