vcpkg_download_distfile(
    ARCHIVE
    URLS "https://download.osgeo.org/libtiff/tiff-${VERSION}.zip"
    FILENAME "tiff-${VERSION}.zip"
    SHA512 f2aa85bcde97fdc4f2479aa380046f1e2f5245ced6b08a3c79d2fb304f4483dfe2d6b9bea233edcd52613818e01493f30d354707e05c11a2660569d6821e5be3
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        dependencies-discovery-and-installation.patch
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
        -Djpeg=0 # should be a feature
        -Djpeg12=0
        -Dlerc=0
        -Dlibdeflate=0 # should be a feature
        -Dtiff-docs=0
        -Dtiff-tests=0
        -Dtiff-tools-unsupported=0
        -Dtiff-tools=0
        -Dwebp=0 # should be a feature
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
