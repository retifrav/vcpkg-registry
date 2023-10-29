vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:madler/zlib.git
    REF 21767c654d31d2dccdde4330529775c6c5fd5389
    PATCHES
        building-and-installation.patch
        missing-header-unistd.patch
)

# this file is auto-generated on CMake configure
file(REMOVE "${SOURCE_PATH}/zconf.h")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        install-minizip-headers INSTALL_MINIZIP_HEADERS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

# if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
#     if(VCPKG_TARGET_IS_WINDOWS)
#         vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/zlib.pc" "-lz" "-lzlib")
#     endif()
#     file(COPY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/zlib.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
# endif()
# if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
#     if(VCPKG_TARGET_IS_WINDOWS)
#         vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/zlib.pc" "-lz" "-lzlibd")
#     endif()
#     file(COPY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/zlib.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
# endif()

vcpkg_cmake_config_fixup()

#vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(
        REMOVE_RECURSE
            "${CURRENT_PACKAGES_DIR}/bin"
            "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/license.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
