decovar_vcpkg_cmake_info_openmp()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:MIT-SPARK/TEASER-plusplus.git
    REF 9ca20d9b52fcb631e7f8c9e3cc55c5ba131cc4e6
    PATCHES
        001-dependencies-and-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}/teaser/")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_DOC=0
        -DBUILD_MATLAB_BINDINGS=0
        -DBUILD_PYTHON_BINDINGS=0
        -DBUILD_TEASER_FPFH=0
        -DBUILD_TESTS=0
        -DENABLE_DIAGNOSTIC_PRINT=0
        -DENABLE_MKL=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
