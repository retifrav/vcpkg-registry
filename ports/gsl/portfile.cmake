set(GSL_ORIGINAL_VERSION "2.8")
vcpkg_download_distfile(ARCHIVE
    URLS
        "https://ftp.gnu.org/gnu/gsl/gsl-${GSL_ORIGINAL_VERSION}.tar.gz"
        "https://mirrorservice.org/sites/ftp.gnu.org/gnu/gsl/gsl-${GSL_ORIGINAL_VERSION}.tar.gz"
        "https://files.decovar.dev/public/packages/sqlite/v${GSL_ORIGINAL_VERSION}/src/gsl-${GSL_ORIGINAL_VERSION}.tar.gz"
    FILENAME "gsl-${GSL_ORIGINAL_VERSION}.tar.gz"
    SHA512 4427f6ce59dc14eabd6d31ef1fcac1849b4d7357faf48873aef642464ddf21cc9b500d516f08b410f02a2daa9a6ff30220f3995584b0a6ae2f73c522d1abb66b
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        001-configure.patch
        002-add-fp-control.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DGSL_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
