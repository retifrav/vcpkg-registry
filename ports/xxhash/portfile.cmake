vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:Cyan4973/xxHash.git
    REF bbb27a5efb85b92a0486cf361a8635715a53f6ba
    PATCHES
        installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/cmake_unofficial"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/cmake_unofficial"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tool XXHASH_BUILD_XXHSUM
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/cmake_unofficial"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "xxHash"
)

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES xxhsum AUTO_CLEAN)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
