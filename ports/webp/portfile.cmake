# fails to build as fat library on Apple platforms
if(VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
    list(LENGTH VCPKG_OSX_ARCHITECTURES VCPKG_OSX_ARCHITECTURES_LENGTH)
    if(VCPKG_OSX_ARCHITECTURES_LENGTH GREATER 1)
        message(STATUS "VCPKG_OSX_ARCHITECTURES: ${VCPKG_OSX_ARCHITECTURES}")
        message(WARNING
            "Building ${PORT} as fat/universal library is likely to fail, "
            "Google closed the bugreport from 2015 about that - "
            "https://issues.webmproject.org/issues/42331778 - "
            "as \"won't fix\""
        )
    endif()
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:webmproject/libwebp.git
    REF a4d7a715337ded4451fec90ff8ce79728e04126c
    PATCHES
        001-installation.patch
        #002-simd.patch # not sure if this is needed
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        enable-simd WEBP_ENABLE_SIMD
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DWEBP_BUILD_ANIM_UTILS=0
        -DWEBP_BUILD_CWEBP=0
        -DWEBP_BUILD_DWEBP=0
        -DWEBP_BUILD_EXTRAS=0
        -DWEBP_BUILD_FUZZTEST=0
        -DWEBP_BUILD_GIF2WEBP=0
        -DWEBP_BUILD_IMG2WEBP=0
        -DWEBP_BUILD_LIBWEBPMUX=0
        -DWEBP_BUILD_VWEBP=0
        -DWEBP_BUILD_WEBP_JS=0
        -DWEBP_BUILD_WEBPINFO=0
        -DWEBP_BUILD_WEBPMUX=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "WebP"
    CONFIG_PATH "share/WebP/cmake"
)

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
