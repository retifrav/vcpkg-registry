if(
    EXISTS "${CURRENT_INSTALLED_DIR}/share/libressl/copyright"
    OR
    EXISTS "${CURRENT_INSTALLED_DIR}/share/boringssl/copyright"
)
    message(FATAL_ERROR "Can't build OpenSSL if LibreSSL/BoringSSL is installed. You need to remove those before installing OpenSSL")
endif()

# silly attempts which are doomed to fail, as toolchain caches(?) the architecture,
# so it was never enabled but kept here in case of possible future attempts
set(NEED_TO_PRODUCE_UNIVERSAL_BINARY_FOR_APPLE NO)
list(LENGTH VCPKG_OSX_ARCHITECTURES VCPKG_OSX_ARCHITECTURES_LENGTH)
if(VCPKG_OSX_ARCHITECTURES_LENGTH GREATER 1)
    if(VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
        set(NEED_TO_PRODUCE_UNIVERSAL_BINARY_FOR_APPLE YES)

        # could it be just a matter of VCPKG_OSX_DEPLOYMENT_TARGET having no effect for Make?
        # https://github.com/microsoft/vcpkg/issues/10038
        message(
            STATUS
                "Building combined/universal library is not supported by [${PORT}] on Apple platforms, "
                "so we will have to get creative and merge separately build arm64 and x64 with lipo tool "
                "(which might be not a very good idea)"
        )
        message(STATUS "Verifying provided architectures, just in case:")
        list(APPEND CMAKE_MESSAGE_INDENT "+ ")
        foreach(VCPKG_OSX_ARCHITECTURE ${VCPKG_OSX_ARCHITECTURES})
            message(STATUS "${VCPKG_OSX_ARCHITECTURE}")
            if(
                NOT VCPKG_OSX_ARCHITECTURE STREQUAL "arm64"
                AND
                NOT VCPKG_OSX_ARCHITECTURE STREQUAL "x86_64"
            )
                message(FATAL_ERROR "Unknown target architecture: ${VCPKG_OSX_ARCHITECTURE}")
            endif()
        endforeach()
        list(POP_BACK CMAKE_MESSAGE_INDENT)
    else()
        message(WARNING
            "The VCPKG_OSX_ARCHITECTURES for [${PORT}] contains more than one architecture, "
            "but the target platform doesn't seem to be supported, so the outcome is unknown"
        )
    endif()
endif()

if(VCPKG_TARGET_IS_EMSCRIPTEN)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:openssl/openssl.git
    REF c9a9e5b10105ad850b6e4d1122c645c67767c341 # "openssl-${VERSION}"
    PATCHES
        cmake-config.patch
        command-line-length.patch
        script-prefix.patch
        windows/install-layout.patch
        windows/install-pdbs.patch
        windows/install-programs.diff # https://github.com/openssl/openssl/issues/28744
        unix/android-cc.patch
        unix/move-openssldir.patch
        unix/no-empty-dirs.patch
        unix/no-static-libs-for-shared.patch
)

vcpkg_list(SET CONFIGURE_OPTIONS
    enable-static-engine
    enable-capieng
    no-tests
    no-docs
)

if(NOT NEED_TO_PRODUCE_UNIVERSAL_BINARY_FOR_APPLE)
    # https://github.com/openssl/openssl/blob/master/INSTALL.md#enable-ec_nistp_64_gcc_128
    vcpkg_cmake_get_vars(cmake_vars_file)
    include("${cmake_vars_file}")
    if(
        VCPKG_DETECTED_CMAKE_C_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang)$"
        AND
        VCPKG_TARGET_ARCHITECTURE MATCHES "^(x64|arm64|riscv64|ppc64le)$"
    )
        vcpkg_list(APPEND CONFIGURE_OPTIONS enable-ec_nistp_64_gcc_128)
    endif()
endif()

set(INSTALL_FIPS "")
if("fips" IN_LIST FEATURES)
    vcpkg_list(APPEND INSTALL_FIPS install_fips)
    vcpkg_list(APPEND CONFIGURE_OPTIONS enable-fips)
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_list(APPEND CONFIGURE_OPTIONS shared)
else()
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-shared no-module)
endif()

if(NOT "tools" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-apps)
endif()

if("weak-ssl-ciphers" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS enable-weak-ssl-ciphers)
endif()

if("ssl3" IN_LIST FEATURES)
    vcpkg_list(APPEND CONFIGURE_OPTIONS enable-ssl3)
    vcpkg_list(APPEND CONFIGURE_OPTIONS enable-ssl3-method)
endif()

if(DEFINED OPENSSL_USE_NOPINSHARED)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-pinshared)
endif()

if(OPENSSL_NO_AUTOLOAD_CONFIG)
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-autoload-config)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    include("${CMAKE_CURRENT_LIST_DIR}/windows/portfile.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/install-pc-files.cmake")
else()
    if(NEED_TO_PRODUCE_UNIVERSAL_BINARY_FOR_APPLE)
        # since it does not(?) support building a universal binary,
        # we'll build every architecture separately
        #
        # x64 (without installation)
        message(STATUS "Building x64:")
        list(APPEND CMAKE_MESSAGE_INDENT "+ ")
        #
        set(VCPKG_TARGET_ARCHITECTURE "x64")
        set(VCPKG_OSX_ARCHITECTURES "x86_64")
        set(CMAKE_SYSTEM_PROCESSOR "x86_64")
        set(CMAKE_HOST_SYSTEM_PROCESSOR "x86_64")
        # or CACHE?
        #set(VCPKG_TARGET_ARCHITECTURE "x64" CACHE STRING "" FORCE)
        #set(VCPKG_OSX_ARCHITECTURES "x86_64" CACHE STRING "" FORCE)
        #set(CMAKE_SYSTEM_PROCESSOR "x86_64" CACHE STRING "" FORCE)
        #set(CMAKE_HOST_SYSTEM_PROCESSOR "x86_64" CACHE STRING "" FORCE)
        #
        include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
        if(IS_DIRECTORY "${CURRENT_PACKAGES_DIR}-x64")
            message(
                WARNING
                    "The ${CURRENT_PACKAGES_DIR}-x64 already exists, perhaps this is a leftover "
                    "from the previous build, will remove it"
            )
            file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}-x64")
        endif()
        # saving the x64 build results into a different path
        file(RENAME "${CURRENT_PACKAGES_DIR}" "${CURRENT_PACKAGES_DIR}-x64")
        list(POP_BACK CMAKE_MESSAGE_INDENT)
        # arm64
        message(STATUS "Building arm64:")
        list(APPEND CMAKE_MESSAGE_INDENT "+ ")
        message(STATUS "Deleting build folders to re-configure with a different architecture")
        list(APPEND CMAKE_MESSAGE_INDENT "- ")
        #
        message(STATUS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
        #vcpkg_execute_build_process(
        #    COMMAND make clean
        #    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
        #    LOGNAME make-clean-${TARGET_TRIPLET}-dbg
        #)
        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
        #
        message(STATUS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
        #vcpkg_execute_build_process(
        #    COMMAND make clean
        #    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        #    LOGNAME make-clean-${TARGET_TRIPLET}-rel
        #)
        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
        #
        list(POP_BACK CMAKE_MESSAGE_INDENT)
        #
        set(VCPKG_TARGET_ARCHITECTURE "arm64")
        set(VCPKG_OSX_ARCHITECTURES "arm64")
        set(CMAKE_SYSTEM_PROCESSOR "arm64")
        set(CMAKE_HOST_SYSTEM_PROCESSOR "arm64")
        # or CACHE?
        #set(VCPKG_TARGET_ARCHITECTURE "arm64" CACHE STRING "" FORCE)
        #set(VCPKG_OSX_ARCHITECTURES "arm64" CACHE STRING "" FORCE)
        #set(CMAKE_SYSTEM_PROCESSOR "arm64" CACHE STRING "" FORCE)
        #set(CMAKE_HOST_SYSTEM_PROCESSOR "arm64" CACHE STRING "" FORCE)
        #
        include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
        list(POP_BACK CMAKE_MESSAGE_INDENT)
        # merging the results with lipo
        # ...
        #file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}-x64")
    else()
        include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
    endif()
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

if(NOT "${VERSION}" MATCHES [[^([0-9]+)\.([0-9]+)\.([0-9]+)$]])
    message(FATAL_ERROR "Version regex did not match.")
endif()
set(OPENSSL_VERSION_MAJOR "${CMAKE_MATCH_1}")
set(OPENSSL_VERSION_MINOR "${CMAKE_MATCH_2}")
set(OPENSSL_VERSION_FIX "${CMAKE_MATCH_3}")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake.in"
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake"
    @ONLY
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
