message(
"ALSA requires the following tools to be installed in the system:

- autoconf
- autoheader
- aclocal
- automake
- libtoolize

To install them with a system package manager:

- Debian and Ubuntu derivatives:
    + `sudo apt install autoconf libtool`
- Red Hat and Fedora derivatives:
    + `sudo dnf install autoconf libtool`
- Arch and derivatives:
    + `sudo pacman -S autoconf automake libtool`
- Alpine:
    + `apk add autoconf automake libtool`
"
)

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:alsa-project/alsa-lib.git
    REF 34422861f5549aee3e9df9fd8240d10b530d9abd
    PATCHES
        001-plugin-path.patch
        002-linking-dl.diff
)

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(ALSA_PLUGIN_DIR "/usr/lib/x86_64-linux-gnu/alsa-lib")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(ALSA_PLUGIN_DIR "/usr/lib/aarch64-linux-gnu/alsa-lib")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(ALSA_PLUGIN_DIR "/usr/lib/arm-linux-gnueabihf/alsa-lib")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "s390x")
    set(ALSA_PLUGIN_DIR "/usr/lib/s390x-linux-gnu/alsa-lib")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "ppc64le")
    set(ALSA_PLUGIN_DIR "/usr/lib/powerpc64le-linux-gnu/alsa-lib")
else()
    set(ALSA_PLUGIN_DIR "/usr/lib/alsa-lib")
endif()
set(ALSA_CONFIG_DIR "/usr/share/alsa")

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
    OPTIONS
        ${BUILD_OPTS}
        --disable-python
        "--with-configdir=${ALSA_CONFIG_DIR}"
        "--with-plugindir=${ALSA_PLUGIN_DIR}"
)

vcpkg_install_make()

vcpkg_fixup_pkgconfig()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/tools/alsa/debug"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
