vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://download.osgeo.org/libtiff/tiff-${VERSION}.zip"
        "https://files.decovar.dev/public/packages/tiff/v${VERSION}/src/tiff-${VERSION}.zip"
    FILENAME "tiff-${VERSION}.zip"
    SHA512 f0ebceaddf02a57994ce0981ebf017e653c714b768364e045c7c90946b43c08199c7801a1bb2dfe33be4ce944490d6c2ccdb3c091a1e65df8cbbc7c948924ce7
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
        cxx tiff-cxx
        jpeg JPEG_SUPPORT
        lzma LZMA_SUPPORT
        webp WEBP_SUPPORT
        zip LIBDEFLATE_SUPPORT
        zip ZLIB_SUPPORT
        zstandard ZSTD_SUPPORT
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -Djbig=0
        -Dlerc=0
        -Dtiff-docs=0
        -Dtiff-framework=0
        -Dtiff-tests=0
        -Dtiff-tools=0
    MAYBE_UNUSED_VARIABLES
        tiff-framework
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
