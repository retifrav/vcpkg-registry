# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_download_distfile(
    ARCHIVE
    URLS "https://gitlab.com/libeigen/eigen/-/archive/${VERSION}/eigen-${VERSION}.tar.gz"
    FILENAME "eigen-${VERSION}.tar.gz"
    SHA512 ba75ecb760e32acf4ceaf27115468e65d4f77c44f8d519b5a13e7940af2c03a304ad433368cb6d55431f307c5c39e2666ab41d34442db3cf441638e51f5c3b6a
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        001-installation.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=0
        -DEIGEN_BUILD_BTL=0
        -DEIGEN_BUILD_DOC=0
        -DEIGEN_BUILD_PKGCONFIG=0
        -DEIGEN_ENABLE_LAPACK_TESTS=0
        -DEIGEN_TEST_OPENMP=0
    MAYBE_UNUSED_VARIABLES
        EIGEN_ENABLE_LAPACK_TESTS
        EIGEN_TEST_OPENMP
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "Eigen3"
    CONFIG_PATH "share/eigen3/cmake"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.README")
