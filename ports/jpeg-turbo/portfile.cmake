# even though it can build a shared library and seems to export symbols for DLL,
# apparently not all the symbols are exported, as projects fail to find some
# when linking dynamically
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

if(EXISTS "${CURRENT_INSTALLED_DIR}/share/jpeg/copyright") # and perhaps the same for mozjpeg
    message(FATAL_ERROR "[ERROR] ${PORT} port overlaps with jpeg port, you need to chose one of them and remove the other")
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:libjpeg-turbo/libjpeg-turbo.git
    REF 6c610333497302c52ff36046f9ff72f0c3a6dc2e
    PATCHES
        disable-tools-docs-fix-installation.patch
        boolean-typedef.patch
)

if(
   VCPKG_TARGET_ARCHITECTURE STREQUAL "arm"
   OR VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64"
   OR (
        VCPKG_CMAKE_SYSTEM_NAME
        AND NOT VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore"
    )
)
    set(JPEGTURBO_SIMD -DWITH_SIMD=ON -DNEON_INTRINSICS=ON)
else()
    set(JPEGTURBO_SIMD -DWITH_SIMD=ON)
    vcpkg_find_acquire_program(NASM)
    get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
    set(ENV{PATH} "$ENV{PATH};${NASM_EXE_PATH}")
endif()

if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    set(ENV{_CL_} "-DNO_GETENV -DNO_PUTENV")
endif()

if(NOT VCPKG_TARGET_IS_WINDOWS)
    string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)
endif()
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" ENABLE_STATIC)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "dynamic" WITH_CRT_DLL)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        jpeg7 WITH_JPEG7
        jpeg8 WITH_JPEG8
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        ${JPEGTURBO_SIMD}
        -DENABLE_STATIC=${ENABLE_STATIC}
        -DENABLE_SHARED=${ENABLE_SHARED}
        -DENABLE_EXECUTABLES=0
        -DINSTALL_DOCS=0
        -DWITH_CRT_DLL=${WITH_CRT_DLL}
    MAYBE_UNUSED_VARIABLES
        WITH_CRT_DLL
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    CONFIG_PATH "lib/cmake/jpeg-turbo"
)

# rename libraries for static builds
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    if(EXISTS "${CURRENT_PACKAGES_DIR}/lib/jpeg-static.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/lib/jpeg-static.lib" "${CURRENT_PACKAGES_DIR}/lib/jpeg.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/lib/turbojpeg-static.lib" "${CURRENT_PACKAGES_DIR}/lib/turbojpeg.lib")
    endif()
    if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg-static.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg-static.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/lib/turbojpeg-static.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/turbojpeg.lib")
    endif()
    
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
    
    if (EXISTS "${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-debug.cmake")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-debug.cmake"
            "jpeg-static${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "jpeg${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-debug.cmake"
            "turbojpeg-static${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "turbojpeg${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}")
    endif()
    if (EXISTS "${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-release.cmake")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-release.cmake"
            "jpeg-static${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "jpeg${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}")
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/jpeg-turboTargets-release.cmake"
            "turbojpeg-static${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "turbojpeg${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}")
    endif()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/share/man"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE.md"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
