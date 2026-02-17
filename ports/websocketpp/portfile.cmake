# it's a header-only library
set(VCPKG_BUILD_TYPE release)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:zaphoyd/websocketpp.git
    REF 56123c87598f8b1dd471be83ca841ceae07f95ba
    PATCHES
        001-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DWEBSOCKETPP_USING_ASIO_STANDALONE=1 # probably should be a feature
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME "websocketpp")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
