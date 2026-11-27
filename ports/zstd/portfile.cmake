vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:facebook/zstd.git
    REF 916e8e70b33317d469a41ee837e47317807815c8
    PATCHES
        001-single-target.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/build/cmake/lib"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/build/cmake/lib"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" ZSTD_BUILD_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ZSTD_BUILD_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/build/cmake"
    OPTIONS
        -DZSTD_BUILD_SHARED=${ZSTD_BUILD_SHARED}
        -DZSTD_BUILD_STATIC=${ZSTD_BUILD_STATIC}
        -DZSTD_LEGACY_SUPPORT=0
        -DZSTD_BUILD_PROGRAMS=0
        -DZSTD_BUILD_TESTS=0
        -DZSTD_BUILD_CONTRIB=0
        -DZSTD_MULTITHREAD_SUPPORT=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    foreach(HEADER IN ITEMS zdict.h zstd.h zstd_errors.h)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/zstd/${HEADER}" "defined(ZSTD_DLL_IMPORT) && (ZSTD_DLL_IMPORT==1)" "1" )
    endforeach()
endif()

vcpkg_install_copyright(
    COMMENT "Zstandard is dual-licensed under BSD and GPLv2."
    FILE_LIST
       "${SOURCE_PATH}/LICENSE"
       "${SOURCE_PATH}/COPYING"
)
