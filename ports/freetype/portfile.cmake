vcpkg_download_distfile(ARCHIVE
    URLS
        "https://download.savannah.gnu.org/releases/${PORT}/${PORT}-${VERSION}.tar.xz" # 2.12.1
        "https://files.decovar.dev/public/packages/${PORT}/v${VERSION}/src/${PORT}-${VERSION}.tar.xz"
    FILENAME "${PORT}-${VERSION}.tar.xz" # 2.12.1
    # don't forget that the hash is for 2.12.1 (so actually there is no point in using ${VERSION})
    SHA512 6482de1748dc2cc01e033d21a3b492dadb1f039d13d9179685fdcf985e24d7f587cbca4c27ed8a7fdb7d9ad59612642ac5f4db062443154753295363f45c052f
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    PATCHES
        001-dependencies-and-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        zlib          FT_REQUIRE_ZLIB
        bzip2         FT_REQUIRE_BZIP2
        png           FT_REQUIRE_PNG
        brotli        FT_REQUIRE_BROTLI
    INVERTED_FEATURES
        zlib          FT_DISABLE_ZLIB
        bzip2         FT_DISABLE_BZIP2
        png           FT_DISABLE_PNG
        brotli        FT_DISABLE_BROTLI
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DFT_DISABLE_HARFBUZZ=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.TXT")
