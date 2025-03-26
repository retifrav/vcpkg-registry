vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:libsdl-org/SDL_image
    REF c1bf2245b0ba63a25afe2f8574d305feca25af77
    PATCHES
        001-dependencies-single-target-installation.patch
)

# why not include the entire OS
file(REMOVE_RECURSE
    "${SOURCE_PATH}/VisualC"
    "${SOURCE_PATH}/Xcode"
)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        jpeg SDL2IMAGE_JPG
        tiff SDL2IMAGE_TIF
        webp SDL2IMAGE_WEBP
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DSDL2IMAGE_AVIF=0
        -DSDL2IMAGE_BACKEND_IMAGEIO=0
        -DSDL2IMAGE_BACKEND_STB=0
        -DSDL2IMAGE_DEPS_SHARED=0
        -DSDL2IMAGE_SAMPLES=0
        -DSDL2IMAGE_VENDORED=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "SDL2_image"
    CONFIG_PATH "lib/cmake/SDL2_image"
)

file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/SDL2_image.framework"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/SDL2_image.framework"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
