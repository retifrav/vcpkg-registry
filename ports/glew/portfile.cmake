if(VCPKG_TARGET_IS_LINUX)
    message(STATUS "[INFO] ${PORT} requires the following packages to be available in the system:
- libxmu-dev
- libxi-dev
- libgl-dev
- libglu1-mesa-dev (GL/glew.h includes GL/glu.h)"
    )
endif()

# not from Git, because their repository https://github.com/nigels-com/glew/tree/285c35d395979771f9409710b2d401db8026e15a
# does not contain shit and is fucked beyond reconciliation
vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://github.com/nigels-com/glew/releases/download/glew-${VERSION}/glew-${VERSION}.tgz"
        "https://files.decovar.dev/public/packages/glew/v${VERSION}/src/glew-${VERSION}.tgz"
    FILENAME "glew-${VERSION}.tgz"
    SHA512 cb4caecf32ec0f180c2691dc7769ffc99571c64f259a2663a2b80e788f1c2fd5362c59e0caaeefed6fb78a4070366d244666a657358049b09071b59fae2377e0
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE glew
    PATCHES
        001-single-target-and-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/build/cmake"
)
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/build/cmake"
)

set(GLEW_OPTIONS "")
if(VCPKG_TARGET_IS_EMSCRIPTEN)
    list(APPEND GLEW_OPTIONS -DGLEW_X11=0)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/build/cmake"
    OPTIONS
        -DBUILD_UTILS=0
        ${GLEW_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    foreach(HEADER_NAME glew wglew)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/GL/${HEADER_NAME}.h"
            "#ifdef GLEW_STATIC"
            "#if 1"
        )
    endforeach()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/usage"
        "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
