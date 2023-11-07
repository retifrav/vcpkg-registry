vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://gitlab.freedesktop.org/mesa/glu.git
    REF a2b96c7bba8db8fec3e02fb4227a7f7b02cabad1
    PATCHES
        opengl-header-apple.patch
        dllexport.patch
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

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        with-glu-header INSTALL_GLU_HEADER
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if("with-glu-header" IN_LIST FEATURES)
    if(EXISTS "${CURRENT_PACKAGES_DIR}/include/GL/glu.h")
        message(FATAL_ERROR
            "There is already glu.h header inside ${CURRENT_PACKAGES_DIR}include/GL/, "
            "it could be that some ports are colliding"
        )
    else()
        # this probably should be done in CMakeLists.txt
        file(
            INSTALL "${SOURCE_PATH}/include/GL/glu.h"
            DESTINATION "${CURRENT_PACKAGES_DIR}/include/GL"
        )
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/LICENSE")
