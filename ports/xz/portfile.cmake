vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:tukaani-project/xz.git
    REF a522a226545730551f7e7c2685fab27cf567746c
    PATCHES
        001-targets-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools BUILD_TOOLS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_TESTING=0
        -DCREATE_LZMA_SYMLINKS=0
        -DCREATE_XZ_SYMLINKS=0
        -DENABLE_NLS=0
        -DXZ_DOC=0
        -DXZ_NLS=0
        -DXZ_TOOL_SYMLINKS=0
        -DXZ_TOOL_SYMLINKS_LZMA=0
    MAYBE_UNUSED_VARIABLES
        CREATE_LZMA_SYMLINKS
        CREATE_XZ_SYMLINKS
        ENABLE_NLS
        XZ_TOOL_SYMLINKS
        XZ_TOOL_SYMLINKS_LZMA
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/xz/lzma.h" "defined(LZMA_API_STATIC)" "1")
else()
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/xz/lzma.h" "defined(LZMA_API_STATIC)" "0")
endif()

if("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(
        TOOL_NAMES
            lzmadec
            lzmainfo
            xz
            xzdec
        AUTO_CLEAN
    )
    if(NOT VCPKG_TARGET_IS_WINDOWS)
        vcpkg_copy_tools(
            TOOL_NAMES
                xzdiff
                xzgrep
                xzless
                xzmore
            AUTO_CLEAN
        )
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
# what fucking shit still creates these symlinks when all the related options are disabled?
file(REMOVE
    "${CURRENT_PACKAGES_DIR}/bin/xzcmp"
    "${CURRENT_PACKAGES_DIR}/bin/xzegrep"
    "${CURRENT_PACKAGES_DIR}/bin/xzfgrep"
    "${CURRENT_PACKAGES_DIR}/debug/bin/xzcmp"
    "${CURRENT_PACKAGES_DIR}/debug/bin/xzegrep"
    "${CURRENT_PACKAGES_DIR}/debug/bin/xzfgrep"
)
if(
    VCPKG_LIBRARY_LINKAGE STREQUAL "static"
    OR
    (
        "tools" IN_LIST FEATURES
        AND
        VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic"
        AND
        NOT VCPKG_TARGET_IS_WINDOWS
    )
)
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/bin"
        "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
