# other SSL implementations need to have this check too
#if(EXISTS "${CURRENT_INSTALLED_DIR}/include/openssl/ssl.h")
if(
    EXISTS "${CURRENT_INSTALLED_DIR}/share/libressl/copyright"
    OR
    EXISTS "${CURRENT_INSTALLED_DIR}/share/openssl/copyright"
)
    message(
        FATAL_ERROR
            "Can't build BoringSSL when LibreSSL or OpenSSL is already installed. "
            "You can have only one SSL/TLS implementation."
    )
endif()

# or maybe BoringSSL targets should add `target_link_libraries(...(?) INTERFACE "stdc++")`
# (and `list(APPEND CMAKE_REQUIRED_LIBRARIES "stdc++")`?), that is of course(?) if `USE_CUSTOM_LIBCXX` is not set?
if("${VCPKG_LIBRARY_LINKAGE}" STREQUAL "static")
    # https://mailman.nginx.org/pipermail/nginx/2024-February/5N5IXG7BI66D5AIKORCYPVVVJTZYMUR6.html
    message(
        WARNING
            "BoringSSL expects C++ runtime environment, and since it is being built as a static library, "
            "you will need to add linking to stdc++ in your project(s), similar to how cURL does it: "
            "https://github.com/curl/curl/blob/2eebc58c4b8d68c98c8344381a9f6df4cca838fd/CMakeLists.txt#L778-L779"
    )
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/boringssl.git
    REF 617634bc015344093f5ea0b0a5b653c924cfa20d
    PATCHES
        001-optional-tool.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tool BUILD_TOOLS
)

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    # MSVC armasm64 expects MASM syntax, but BoringSSL uses GNU asm on arm64, so force the C fallback
    list(APPEND FEATURE_OPTIONS "-DOPENSSL_NO_ASM=1")
endif()

vcpkg_find_acquire_program(NASM)
get_filename_component(NASM_EXE_PATH "${NASM}" DIRECTORY)
vcpkg_add_to_path("${NASM_EXE_PATH}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_TESTING=0
        # https://everything.curl.dev/build/boringssl.html
        # cURL documentation says to set this, but is it needed otherwise (or at all)? And should it not depend on `BUILD_SHARED_LIBS`?
        #-DCMAKE_POSITION_INDEPENDENT_CODE=1
)

vcpkg_cmake_install()

if("tool" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES bssl AUTO_CLEAN)
endif()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "OpenSSL"
    CONFIG_PATH "lib/cmake/OpenSSL"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
