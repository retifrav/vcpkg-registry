vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/brotli.git
    REF 028fb5a23661f123017c060daa546b55cf4bde29
    PATCHES
        001-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

if("tools" IN_LIST FEATURES AND VCPKG_TARGET_IS_EMSCRIPTEN)
    message(
        FATAL_ERROR
            "Building tools is not supported for WebAssembly, "
            "you'll need to remove the `tools` feature"
    )
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools BROTLI_BUILD_TOOLS
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBROTLI_BUNDLED_MODE=0
        -DBROTLI_DISABLE_TESTS=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

if("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES brotli AUTO_CLEAN)
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
