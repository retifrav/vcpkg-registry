set(CEF_ARCHIVE_NAME_PLATFORM "unknown")
set(CEF_ARCHIVE_CHECKSUM "unknown")

if(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        # CEF pre-built binaries are DLL
        set(VCPKG_POLICY_SKIP_CRT_LINKAGE_CHECK enabled)
    endif()
    
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(CEF_ARCHIVE_NAME_PLATFORM "windowsarm64")
        set(CEF_ARCHIVE_CHECKSUM "4048faf6a7d02dc1f653d5565112b643da82006d7e96a63d2040e63813b96b1208e7d67159635ff28f23eb01ee25a2ae1c4cb053397344547dc97211960386ba")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        message(FATAL_ERROR "Windows platform x64 isn't supported for ${PORT}")
    else()
        message(FATAL_ERROR "This platform architecture isn't supported for ${PORT}")
    endif()
elseif(VCPKG_TARGET_IS_LINUX)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(CEF_ARCHIVE_NAME_PLATFORM "linuxarm64")
        set(CEF_ARCHIVE_CHECKSUM "5c5a725f90c9c6cb402c39f3653eb83f7ae3eecb1bb185d00b8462f4f70d9636a29e40ae1928156ef1b44230681e3e70b006bfdee56e753a034ca6a654d4d23e")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(CEF_ARCHIVE_NAME_PLATFORM "linux64")
        set(CEF_ARCHIVE_CHECKSUM "7c047ea9c9dc744170f213f0766230d996906cf97cdb08193047da73d8ec25b8c65a90ccbe6d277d5a50e3b513d43343d73c182cf338ddc444f2139166338c27")
    else()
        message(FATAL_ERROR "This platform architecture isn't supported for ${PORT}")
    endif()
elseif(VCPKG_TARGET_IS_OSX)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(CEF_ARCHIVE_NAME_PLATFORM "macosarm64")
        set(CEF_ARCHIVE_CHECKSUM "4714cc3fa104cf1872a655f45e58c862cf15c27f8c7d914e559cc4f56d39b02446160e5ff2b2c99bbf335efd4016bb1dbe0c5e4de105221ad77ba038fe9f7758")
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        message(FATAL_ERROR "Mac OS platform x64 isn't supported for ${PORT}")
    else()
        message(FATAL_ERROR "This platform architecture isn't supported for ${PORT}")
    endif()
else()
    message(FATAL_ERROR "This platform isn't supported for ${PORT}")
endif()

if(CEF_ARCHIVE_NAME_PLATFORM STREQUAL "unknown" OR CEF_ARCHIVE_CHECKSUM STREQUAL "unknown")
    message(FATAL_ERROR "Either platform suffix or checksum are still unknown")
endif()

set(CEF_ARCHIVE_NAME "cef_binary_${VERSION}+g2f1bfd8+chromium-149.0.7827.156_${CEF_ARCHIVE_NAME_PLATFORM}.tar.bz2")
set(CEF_DOWNLOAD_URL "https://cef-builds.spotifycdn.com/${CEF_ARCHIVE_NAME}")
message(DEBUG "CEF download URL: ${CEF_DOWNLOAD_URL}")

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "${CEF_DOWNLOAD_URL}"
    FILENAME "${CEF_ARCHIVE_NAME}"
    SHA512 "${CEF_ARCHIVE_CHECKSUM}"
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

# this relies on the fact that CMake will try the lower-cased `cef` path too,
# otherwise it should have been hardcoded `CEF`
set(CEF_PACKAGE_NAME "${PORT}")

if(EXISTS "${SOURCE_PATH}/Resources")
    file(
        INSTALL
            "${SOURCE_PATH}/Resources"
        DESTINATION
            "${CURRENT_PACKAGES_DIR}/share/${CEF_PACKAGE_NAME}/cef-root/"
    )
endif()
file(
    INSTALL
        "${SOURCE_PATH}/cmake"
        "${SOURCE_PATH}/Debug"
        "${SOURCE_PATH}/Release"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${CEF_PACKAGE_NAME}/cef-root/"
)
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${CEF_PACKAGE_NAME}/cef-root/cmake/cef_variables.cmake"
        [=[set(CEF_INCLUDE_PATH "${_CEF_ROOT}")]=]
        [=[set(CEF_INCLUDE_PATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")]=]
)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${CEF_PACKAGE_NAME}"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
