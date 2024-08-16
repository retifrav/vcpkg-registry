# does not(?) export symbols for making a DLL
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/glslang.git
    REF d1517d64cfca91f573af1bf7341dc3a5113349c0
    PATCHES
        install-to-datadir.patch
        no-threads-on-macos.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path("${PYTHON_PATH}")

# on iOS executables will require BUNDLE DESTINATION, so that will fail,
# and on WASM tools are not built(?), so they will fail to copy with vcpkg_copy_tools()
set(BUILD_BINARIES 0)
if("tools" IN_LIST FEATURES AND NOT VCPKG_TARGET_IS_IOS AND NOT VCPKG_TARGET_IS_EMSCRIPTEN)
    set(BUILD_BINARIES 1)
endif()

set(PLATFORM_OPTIONS "")
if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND PLATFORM_OPTIONS "-DOVERRIDE_MSVCCRT=0")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENABLE_GLSLANG_BINARIES=${BUILD_BINARIES}
        -DSKIP_GLSLANG_INSTALL=0
        -DBUILD_EXTERNAL=0
        -DBUILD_TESTING=0
        -DENABLE_CTEST=0
        ${PLATFORM_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake")

if(NOT BUILD_BINARIES)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
else()
    vcpkg_copy_tools(TOOL_NAMES glslangValidator spirv-remap AUTO_CLEAN)
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/bin"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
