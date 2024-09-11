vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:wolfpld/tracy.git
    REF 5d542dc09f3d9378d005092a4ad446bd405f819a
    PATCHES
        001-threads-linking-headers-installation.patch
        002-optional-building-tools.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        on-demand TRACY_ON_DEMAND
        fibers    TRACY_FIBERS
        verbose   TRACY_VERBOSE
    INVERTED_FEATURES
        crash-handler TRACY_NO_CRASH_HANDLER
)

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDOWNLOAD_CAPSTONE=0
        -DLEGACY=1
    MAYBE_UNUSED_VARIABLES
        DOWNLOAD_CAPSTONE
        LEGACY
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME "Tracy")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# fixing retarded include paths
file(GLOB_RECURSE TRACY_HEADERS
    "${CURRENT_PACKAGES_DIR}/include/tracy/*.h*"
)
foreach(TRACY_HEADER IN ITEMS ${TRACY_HEADERS})
    vcpkg_replace_string(
        ${TRACY_HEADER}
            [=[#[ ]*include[ ]+("\.\.\/([^"]+)")]=]
            [=[#include <tracy/\2>]=]
        REGEX
        IGNORE_UNCHANGED
    )
endforeach()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
