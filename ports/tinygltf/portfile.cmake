# does not export symbols for making a DLL
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:syoyo/tinygltf.git
    REF 4bfc1fc1807e2e2cf3d3111f67d6ebd957514c80
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
        -DTINYGLTF_BUILD_BUILDER_EXAMPLE=0
        -DTINYGLTF_BUILD_GL_EXAMPLES=0
        -DTINYGLTF_BUILD_LOADER_EXAMPLE=0
        -DTINYGLTF_BUILD_VALIDATOR_EXAMPLE=0
        -DTINYGLTF_HEADER_ONLY=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
