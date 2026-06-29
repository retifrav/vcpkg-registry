vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://cef-builds.spotifycdn.com/cef_binary_149.0.4%2Bg2f1bfd8%2Bchromium-149.0.7827.156_macosarm64.tar.bz2"
    FILENAME "cef_binary_149.0.4+g2f1bfd8+chromium-149.0.7827.156_macosarm64.tar.bz2"
    SHA512 4714cc3fa104cf1872a655f45e58c862cf15c27f8c7d914e559cc4f56d39b02446160e5ff2b2c99bbf335efd4016bb1dbe0c5e4de105221ad77ba038fe9f7758
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        001-cmake.diff
)

file(REMOVE_RECURSE
    "${SOURCE_PATH}/bazel"
    "${SOURCE_PATH}/tests"
)
file(REMOVE
    "${SOURCE_PATH}/.bazelrc"
    "${SOURCE_PATH}/.bazelversion"
    "${SOURCE_PATH}/BUILD.bazel"
    "${SOURCE_PATH}/cef_paths.gypi"
    "${SOURCE_PATH}/cef_paths2.gypi"
    "${SOURCE_PATH}/CREDITS.html"
    "${SOURCE_PATH}/Doxyfile"
    "${SOURCE_PATH}/MODULE.bazel"
    "${SOURCE_PATH}/README.md"
    "${SOURCE_PATH}/README.txt"
    "${SOURCE_PATH}/WORKSPACE"
)

file(
    COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/libcef_dll/"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "libcef_dll_wrapper"
)

file(
    INSTALL "${SOURCE_PATH}/include/"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include/cef"
)
file(GLOB_RECURSE CEF_HEADERS
   "${CURRENT_PACKAGES_DIR}/include/cef/*.h"
)
foreach(CEF_HEADER IN ITEMS ${CEF_HEADERS})
   vcpkg_replace_string(
       ${CEF_HEADER}
           [=[#include "include/]=]
           [=[#include "cef/]=]
       IGNORE_UNCHANGED
   )
endforeach()

file(
    INSTALL
        "${SOURCE_PATH}/cmake"
        "${SOURCE_PATH}/Debug"
        "${SOURCE_PATH}/Release"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}/cef-root/"
)
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/cef-root/cmake/cef_variables.cmake"
        [=[set(CEF_INCLUDE_PATH "${_CEF_ROOT}")]=]
        [=[set(CEF_INCLUDE_PATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")]=]
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
