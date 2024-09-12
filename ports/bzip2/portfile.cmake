vcpkg_download_distfile(ARCHIVE
    URLS "https://sourceware.org/pub/bzip2/bzip2-${VERSION}.tar.gz" # 1.0.8
    FILENAME "bzip2-${VERSION}.tar.gz" # 1.0.8
    # don't forget that the hash is for 1.0.8 (so actually there is no point in using ${VERSION})
    SHA512 083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    PATCHES
        001-dll-import-export-macros.patch
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

file(READ "${CURRENT_PACKAGES_DIR}/include/${PORT}/bzlib.h" BZLIB_H)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    string(REPLACE "defined(BZ_IMPORT)" "0" BZLIB_H "${BZLIB_H}")
else()
    string(REPLACE "defined(BZ_IMPORT)" "1" BZLIB_H "${BZLIB_H}")
endif()
file(WRITE "${CURRENT_PACKAGES_DIR}/include/${PORT}/bzlib.h" "${BZLIB_H}")

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    #"${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
