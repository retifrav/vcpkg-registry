# looks like they don't recommend building it as a dynamic library:
# https://abseil.io/about/compatibility#c-symbols-and-files
# although, apparently, it is fine in case of Windows DLL
if(NOT VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:abseil/abseil-cpp.git
    REF 76bb24329e8bf5f39704eb10d21b9a80befa7c81
    PATCHES
        001-proper-version.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DABSEIL_VERSION="${VERSION}"
        -DCMAKE_CXX_STANDARD=17 # could be an optional feature, but probably better have it by default
        -DABSL_PROPAGATE_CXX_STD=1
        -DBUILD_TESTING=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "absl"
    CONFIG_PATH "lib/cmake/absl"
)

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/absl/base/config.h"
        "defined(ABSL_CONSUME_DLL)"
        "1"
    )
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/absl/base/internal/thread_identity.h"
        "defined(ABSL_CONSUME_DLL)"
        "1"
    )
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
