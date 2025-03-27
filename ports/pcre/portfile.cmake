vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:PCRE2Project/pcre2.git
    REF 2dce7761b1831fd3f82a9c2bd5476259d945da4d
    PATCHES
        001-single-targets-and-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")

if("sljit" IN_LIST FEATURES)
    # that should be its own port, shouldn't it
    vcpkg_from_git(
        OUT_SOURCE_PATH SOURCE_PATH_SLJIT
        URL git@github.com:zherczeg/sljit.git
        REF 8481dde366d0346ac5475aa03ae48ee44fa74ca4
    )
    file(REMOVE_RECURSE "${SOURCE_PATH}/deps/sljit")
    file(MAKE_DIRECTORY "${SOURCE_PATH}/deps")
    file(RENAME "${SOURCE_PATH_SLJIT}" "${SOURCE_PATH}/deps/sljit")
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        sljit PCRE2_SUPPORT_JIT
        sljit PCRE2GREP_SUPPORT_JIT # should depend on PCRE2_BUILD_PCRE2GREP (and PCRE2_SUPPORT_JIT)
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" BUILD_STATIC)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" BUILD_STATIC_CRT)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_STATIC_LIBS=${BUILD_STATIC}
        -DPCRE2_STATIC_RUNTIME=${BUILD_STATIC_CRT}
        -DPCRE2_BUILD_PCRE2_8=1
        -DPCRE2_BUILD_PCRE2_16=1
        -DPCRE2_BUILD_PCRE2_32=1
        -DPCRE2_BUILD_PCRE2GREP=0
        -DPCRE2_BUILD_TESTS=0
        -DPCRE2_SUPPORT_UNICODE=1
        -DINSTALL_MSVC_PDB=0
)

vcpkg_cmake_install()

# is that really the way
if(BUILD_STATIC)
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/pcre/pcre2.h"
            "defined(PCRE2_STATIC)"
            "1"
    )
else()
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/pcre/pcre2.h"
            "defined(PCRE2_STATIC)"
            "0"
    )
endif()

vcpkg_cmake_config_fixup()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENCE.md")
