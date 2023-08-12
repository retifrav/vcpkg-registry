set(ICONV_VERSION "1.16")

if(NOT VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_ANDROID)
    set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/iconv")
    file(COPY "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/iconv")
    return()
endif()

vcpkg_download_distfile(
    ARCHIVE
    URLS "https://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz"
         "https://www.mirrorservice.org/sites/ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz"
    FILENAME "libiconv-${ICONV_VERSION}.tar.gz"
    # don't forget that the hash is for 1.16.0 (so actually there is no point in using ${ICONV_VERSION})
    SHA512 365dac0b34b4255a0066e8033a8b3db4bdb94b9b57a9dca17ebf2d779139fe935caf51a465d17fd8ae229ec4b926f3f7025264f37243432075e5583925bb77b7
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        mbrtowc-msvc.patch
        dll-export.patch
        module-file-name.patch
)

if(NOT VCPKG_TARGET_IS_ANDROID)
    list(APPEND OPTIONS --enable-relocatable)
endif()

if(VCPKG_HOST_IS_LINUX) # OR VCPKG_HOST_IS_OSX
    # on GNU/Linux (and Mac OS?) the configure script might(?) be not an executable
    vcpkg_execute_build_process(
        COMMAND chmod +x ./configure
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME config-${PORT}-${TARGET_TRIPLET}-chmod
    )
endif()

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    DETERMINE_BUILD_TRIPLET
    USE_WRAPPERS
    OPTIONS
        --enable-extra-encodings
        --without-libiconv-prefix
        --without-libintl-prefix
        ${OPTIONS}
)

# public headers (iconv.h, libcharset.h, localcharset.h) are installed without subfolder
# find a way to install those properly using Makefile
vcpkg_install_make()

vcpkg_copy_tools(
    TOOL_NAMES ${PORT}
    SEARCH_DIR "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin"
    AUTO_CLEAN
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/iconv"
)

set(VCPKG_POLICY_ALLOW_RESTRICTED_HEADERS enabled)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(
    FILE_LIST
        "${SOURCE_PATH}/COPYING.LIB"
        "${SOURCE_PATH}/COPYING"
    COMMENT "The libiconv and libcharset libraries and their header files
are licensed under LGPL terms in COPYING.LIB. The iconv program
and the documentation are licensed under GPL terms in COPYING."
)
