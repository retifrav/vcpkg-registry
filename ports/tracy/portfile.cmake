vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:wolfpld/tracy.git
    REF 5d542dc09f3d9378d005092a4ad446bd405f819a
    PATCHES
        001-dependencies-and-installation.patch
        002-chrono-in-vs-1713.patch # might need to make this Windows-specific
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        on-demand TRACY_ON_DEMAND
        fibers    TRACY_FIBERS
        verbose   TRACY_VERBOSE
    INVERTED_FEATURES
        crash-handler TRACY_NO_CRASH_HANDLER
)

vcpkg_check_features(OUT_FEATURE_OPTIONS TOOLS_OPTIONS
    FEATURES
        cli-tools BUILD_CLI_TOOLS
        gui-tools BUILD_GUI_TOOLS
)

if(
    (
        "cli-tools" IN_LIST FEATURES
        OR
        "gui-tools" IN_LIST FEATURES
    )
    AND
    VCPKG_TARGET_IS_LINUX
)
    message(
"Tracy tools/applications require the following libraries to be installed in the system:

- D-Bus
- TBB

To install them with a system package manager:

- Debian and Ubuntu derivatives:
    + `sudo apt install libdbus-1-dev libtbb-dev`
"
)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        ${FEATURE_OPTIONS}
        -DLEGACY=1
    OPTIONS_RELEASE # no point in building Debug variants of the tools and applications
        ${TOOLS_OPTIONS}
    MAYBE_UNUSED_VARIABLES
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

if("cli-tools" IN_LIST FEATURES AND NOT VCPKG_TARGET_IS_EMSCRIPTEN)
    vcpkg_copy_tools(
        TOOL_NAMES
            tracy-capture
            tracy-csvexport
            tracy-import-chrome
            tracy-import-fuchsia
            tracy-update
        AUTO_CLEAN
    )
endif()

if("gui-tools" IN_LIST FEATURES AND NOT VCPKG_TARGET_IS_EMSCRIPTEN)
    vcpkg_copy_tools(
        TOOL_NAMES
            tracy-profiler
        AUTO_CLEAN
    )
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
