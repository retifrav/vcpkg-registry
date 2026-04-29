# looks like they don't recommend building it as a dynamic library:
# https://abseil.io/about/compatibility#c-symbols-and-files
# besides, they use `CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS`, which is never a good sign,
# but if you are going to allow this on Windows anyway, then don't forget about
# replacing `ABSL_CONSUME_DLL` after installation (if this is still required)
#if(NOT VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
#endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:abseil/abseil-cpp.git
    REF 255c84dadd029fd8ad25c5efb5933e47beaa00c7
    PATCHES
        001-proper-version.patch
        002-no-pkg-config.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DABSEIL_VERSION="${VERSION}"
        -DABSL_BUILD_TEST_HELPERS=0
        -DABSL_BUILD_TESTING=0
        -DABSL_ENABLE_INSTALL=1
        -DABSL_PROPAGATE_CXX_STD=1
        -DABSL_USE_EXTERNAL_GOOGLETEST=0
        -DBUILD_TESTING=0
        -DCMAKE_CXX_STANDARD=17
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "absl"
    CONFIG_PATH "lib/cmake/absl"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

# they seem to define `ABSL_CONSUME_DLL` and propagate it via INTERFACE compile definitions,
# so it might work without these replacements, but that hasn't been tested
#if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
#    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/absl/base/config.h"
#        "defined(ABSL_CONSUME_DLL)"
#        "1"
#    )
#    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/absl/base/internal/thread_identity.h"
#        "defined(ABSL_CONSUME_DLL)"
#        "1"
#    )
#endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
