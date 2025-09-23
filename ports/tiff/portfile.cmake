vcpkg_download_distfile(
    ARCHIVE
    URLS "https://download.osgeo.org/libtiff/tiff-${VERSION}.zip"
    FILENAME "tiff-${VERSION}.zip"
    SHA512 e8a22cd152cc4b4d766c40b9f7c344a357fbc9a01d01ed1832ef39fc0f0d1264d30e815942702f4dfc83b5cb3666caf7a8e8a8350c0d01b045d51e1e5da2e111
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        001-dependencies-discovery-and-installation.patch
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/libtiff"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        cxx cxx
        lzma lzma
        zip zlib
        zstandard zstd
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -Djbig=0
        -Djpeg12=0
        -Djpeg=0 # should be a feature
        -Dlerc=0
        -Dlibdeflate=0 # should be a feature
        -Dtiff-docs=0
        -Dtiff-tests=0
        -Dtiff-tools=0
        -Dwebp=0 # should be a feature
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
