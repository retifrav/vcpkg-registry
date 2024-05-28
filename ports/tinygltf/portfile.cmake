# it's a header-only library (in this version)
set(VCPKG_BUILD_TYPE release)

# does not export symbols for making a DLL
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:syoyo/tinygltf.git
    REF 91da29972987bb4d715a09d94ecd2cefd3a487d4
    PATCHES
        dependencies-and-installation.patch
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DTINYGLTF_BUILD_GL_EXAMPLES=0
        -DTINYGLTF_BUILD_LOADER_EXAMPLE=0
        -DTINYGLTF_BUILD_VALIDATOR_EXAMPLE=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
