vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:hobuinc/laz-perf.git
    REF 07d925e6d530879adb5299a9c85627e216145b96
    PATCHES
        001-single-target-and-installation.patch
)

file(REMOVE
    "${SOURCE_PATH}/cmake/install"
    "${SOURCE_PATH}/cpp/lazperf/lazperf_user_base.hpp"
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/cpp/"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/cpp/"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DLAZPERF_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "lazperf"
    CONFIG_PATH "share/lazperf"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
