if(VCPKG_TARGET_IS_LINUX)
    message(STATUS "[INFO] ${PORT} requires the following packages to be available in the system:
- libxmu-dev
- libxi-dev
- libgl-dev"
    )
endif()

# sources on GitHub do not contain required headers
# I guess, because fuck you, that's why
if(YOU_LIKE_TO_SUFFER)
    vcpkg_from_git(
        OUT_SOURCE_PATH SOURCE_PATH
        URL git@github.com:nigels-com/glew.git
        REF 9fb23c3e61cbd2d581e33ff7d8579b572b38ee26
        PATCHES
            single-target.patch
    )
else()
    vcpkg_download_distfile(
        ARCHIVE
        URLS "https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz"
        FILENAME "glew-2.2.0.tgz"
        SHA512 57453646635609d54f62fb32a080b82b601fd471fcfd26e109f479b3fef6dfbc24b83f4ba62916d07d62cd06d1409ad7aa19bc1cd7cf3639c103c815b8be31d1
    )

    vcpkg_extract_source_archive(
        SOURCE_PATH
        ARCHIVE ${ARCHIVE}
        SOURCE_BASE glew
        PATCHES
            single-target.patch
    )
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/build/cmake"
    OPTIONS
        -DBUILD_UTILS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE
        "${CURRENT_PACKAGES_DIR}/bin"
        "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
    foreach(FILE
        "${CURRENT_PACKAGES_DIR}/include/GL/glew.h"
        "${CURRENT_PACKAGES_DIR}/include/GL/wglew.h"
        "${CURRENT_PACKAGES_DIR}/include/GL/glxew.h"
    )
        file(READ ${FILE} _contents)
        string(REPLACE "#ifdef GLEW_STATIC" "#if 1" _contents "${_contents}")
        file(WRITE ${FILE} "${_contents}")
    endforeach()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
