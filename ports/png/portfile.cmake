vcpkg_download_distfile(ARCHIVE
    URLS
        "http://repository.timesys.com/buildsources/l/libpng/libpng-${VERSION}/libpng-${VERSION}.tar.xz"
        "https://netix.dl.sourceforge.net/project/libpng/libpng16/${VERSION}/libpng-${VERSION}.tar.xz?viasf=1"
        "https://deac-fra.dl.sourceforge.net/project/libpng/libpng16/${VERSION}/libpng-${VERSION}.tar.xz?viasf=1"
        "https://files.decovar.dev/public/packages/png/v${VERSION}/src/libpng-${VERSION}.tar.xz"
    FILENAME "libpng-${VERSION}.tar.xz" # 1.6.43
    # don't forget that the hash is for 1.6.43 (so actually there is no point in using ${VERSION})
    SHA512 c95d661fed548708ce7de5d80621a432272bdfe991f0d4db3695036e5fafb8a717b4e4314991bdd3227d7aa07f8c6afb6037c57fa0fe3349334a0b6c58268487
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    PATCHES
        001-single-unsuffixed-target-dependencies-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" PNG_STATIC)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" PNG_SHARED)

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
        -DPNG_TOOLS=0
    MAYBE_UNUSED_VARIABLES
        PNG_ARM_NEON
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
