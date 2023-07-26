vcpkg_download_distfile(ARCHIVE
    URLS "https://netix.dl.sourceforge.net/project/libpng/libpng16/${VERSION}/libpng-${VERSION}.tar.xz" # 1.6.38
    FILENAME "libpng-${VERSION}.tar.xz" # 1.6.38
    # don't forget that the hash is for 1.6.38 (so actually there is no point in using ${VERSION})
    SHA512 4e450636062fcc75ecc65715e0b23ddc1097b73b4c95ffd31bef627144c576f58660b2130105f5f5781212cf54f00c7b6dd3facefd7e9de70c76b981d499f81e
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    PATCHES
        options-targets-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

# by default it builds both
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" PNG_SHARED)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" PNG_STATIC)

vcpkg_list(SET PNG_HARDWARE_OPTIMIZATIONS_OPTION)
if(VCPKG_TARGET_IS_IOS)
    vcpkg_list(APPEND PNG_HARDWARE_OPTIMIZATIONS_OPTION "-DPNG_HARDWARE_OPTIMIZATIONS=0")
endif()

vcpkg_list(SET LD_VERSION_SCRIPT_OPTION)
if(VCPKG_TARGET_IS_ANDROID)
    vcpkg_list(APPEND LD_VERSION_SCRIPT_OPTION "-Dld-version-script=0")
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
        # for armeabi-v7a, check whether NEON is available
        vcpkg_list(APPEND PNG_HARDWARE_OPTIMIZATIONS_OPTION "-DPNG_ARM_NEON=check")
    endif()
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DPNG_STATIC=${PNG_STATIC}
        -DPNG_SHARED=${PNG_SHARED}
        ${PNG_HARDWARE_OPTIMIZATIONS_OPTION}
        ${LD_VERSION_SCRIPT_OPTION}
        -DPNG_TESTS=0
        -DPNG_EXECUTABLES=0
    MAYBE_UNUSED_VARIABLES
        PNG_ARM_NEON
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
