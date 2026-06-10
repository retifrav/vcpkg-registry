vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:microsoft/DirectX-Headers.git
    REF 9e393d6d8a3b30dcc6f2806ef604ec16a27b0d7e
    PATCHES
        001-installation.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDXHEADERS_BUILD_GOOGLE_TEST=0
        -DDXHEADERS_BUILD_TEST=0
        -DDXHEADERS_INSTALL=1
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "share/directx-headers/cmake")

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
