# does not export symbols for making a DLL
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

set(FILE_TO_DOWNLOAD "lzma2601.7z")
vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://7-zip.org/a/${FILE_TO_DOWNLOAD}"
        "https://files.decovar.dev/public/packages/lzma/v${VERSION}/src/${FILE_TO_DOWNLOAD}"
    FILENAME "${FILE_TO_DOWNLOAD}"
    SHA512 0dfe9182c74456ca9af4984ed7f2abe49f37b4b747db4c612c41816a4789964097fc43f3fcd6ba535bf5f96bda68306773360b6397ffcfe966c9305e2e354983
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    NO_REMOVE_ONE_LEVEL
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        enable-avx2 ENABLE_AVX2
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DLZMA_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/copyright")
