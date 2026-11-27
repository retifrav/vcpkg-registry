vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:lz4/lz4.git
    REF aa4647fad575d01a874aaaadcdbe8e6a40e072f5
    PATCHES
        001-single-target-and-installation.patch
)

file(
    COPY "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/build/cmake"
)
file(
    COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/build/cmake")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/build/cmake"
    OPTIONS
        -DLZ4_BUILD_CLI=0
        -DLZ4_BUILD_LEGACY_LZ4C=0
        -DLZ4_SHARED_MULTITHREAD=1
        -DLZ4_STATIC_MULTITHREAD=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(LZ4_DLL_IMPORT "1 && defined(_MSC_VER)")
else()
    set(LZ4_DLL_IMPORT "0")
endif()
foreach(HEADER IN ITEMS lz4.h lz4frame.h)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/lz4/${HEADER}"
        "defined(LZ4_DLL_IMPORT) && (LZ4_DLL_IMPORT==1)"
        "${LZ4_DLL_IMPORT}"
    )
endforeach()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/lib/LICENSE")
