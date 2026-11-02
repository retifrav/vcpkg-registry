string(REGEX MATCH "^[0-9]*" ICU_VERSION_MAJOR "${VERSION}")
set(VERSION2 "78.3")

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://github.com/unicode-org/icu/releases/download/release-${VERSION2}/icu4c-${VERSION2}-sources.tgz"
        "https://files.decovar.dev/public/packages/icu/v${VERSION2}/src/icu4c-${VERSION2}-sources.tgz"
    FILENAME "icu4c-${VERSION2}-sources.tgz"
    SHA512 04a49455e1489030c520a4bfd2664fa2171e7938d08f2acdbbcb1fda976639fd8b1f0704f2eec89ba59a7b6d118ceaab6ec5a096e40d9085a0895d91ce225245
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        disable-static-prefix.patch # https://gitlab.kitware.com/cmake/cmake/-/issues/16617; also mingw.
        fix_bsd_and_solaris.patch
        fix_parallel_build_on_windows.patch
        fix-python-path-with-spaces.patch
        fix-using-install-sh.diff
        mh-darwin.patch
        mh-mingw.patch
        mh-msys-msvc.patch
        subdirs.patch
        vcpkg-cross-data.patch
)

vcpkg_find_acquire_program(PYTHON3)
set(ENV{PYTHON} "${PYTHON3}")

vcpkg_list(SET CONFIGURE_OPTIONS)
vcpkg_list(SET BUILD_OPTIONS)

if(VCPKG_TARGET_IS_EMSCRIPTEN)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --disable-extras icu_cv_host_frag=mh-linux)
    vcpkg_list(APPEND BUILD_OPTIONS "\"PKGDATA_OPTS=--without-assembly -O ../data/icupkg.inc\"")
elseif(VCPKG_TARGET_IS_UWP)
    vcpkg_list(APPEND CONFIGURE_OPTIONS --disable-extras ac_cv_func_tzset=no ac_cv_func__tzset=no)
    string(APPEND VCPKG_C_FLAGS " -DU_PLATFORM_HAS_WINUWP_API=1")
    string(APPEND VCPKG_CXX_FLAGS " -DU_PLATFORM_HAS_WINUWP_API=1")
    vcpkg_list(APPEND BUILD_OPTIONS "\"PKGDATA_OPTS=--windows-uwp-build -O ../data/icupkg.inc\"")
elseif(VCPKG_TARGET_IS_IOS)
    # vcpkg-make passes --host=<arch>-apple-ios, which ICU's configure does not recognize
    vcpkg_list(APPEND CONFIGURE_OPTIONS icu_cv_host_frag=mh-darwin)
elseif(VCPKG_TARGET_IS_OSX AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_list(APPEND CONFIGURE_OPTIONS --enable-rpath)
    if(DEFINED CMAKE_INSTALL_NAME_DIR)
        vcpkg_list(APPEND BUILD_OPTIONS "ID_PREFIX=${CMAKE_INSTALL_NAME_DIR}")
    endif()
endif()

if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    list(APPEND CONFIGURE_OPTIONS ac_cv_lib_m_floor=no)
endif()

if("tools" IN_LIST FEATURES)
  list(APPEND CONFIGURE_OPTIONS --enable-tools)
else()
  list(APPEND CONFIGURE_OPTIONS --disable-tools)
endif()

if("data" IN_LIST FEATURES)
    # the data is packaged by the host's pkgdata, and a pkgdata built with MSVC ignores
    # both `--without-assembly` and the icupkg.inc with the target's compiler and archiver,
    # so it can only produce COFF objects archived with LIB.exe, which is no use for WebAssembly
    if(VCPKG_TARGET_IS_EMSCRIPTEN AND CMAKE_HOST_WIN32)
        message(FATAL_ERROR
            "ICU data cannot be packaged for Emscripten on a Windows host, "
            "build ${PORT}[data] for Emscripten on a Linux or Mac OS host instead"
        )
    endif()
else()
    # skip the data subfolder, so the installed data library is the one from `stubdata/`,
    # which has the same name as the actual data library would have. The stub contains no data,
    # but the functions with compiled-in data (such as character properties and case mapping)
    # do not need it, and applications can still provide the data at runtime
    # with `udata_setCommonData()` or `u_setDataDirectory()`
    vcpkg_list(APPEND BUILD_OPTIONS "DATASUBDIR=")
endif()

if(CMAKE_HOST_WIN32 AND VCPKG_TARGET_IS_MINGW AND NOT HOST_TRIPLET MATCHES "mingw")
    # Assuming no cross compiling because the host (windows) pkgdata tool doesn't
    # use the '/' path separator when creating compiler commands for mingw bash.
elseif(VCPKG_CROSSCOMPILING)
    set(TOOL_PATH "${CURRENT_HOST_INSTALLED_DIR}/tools/${PORT}")
    # convert to unix path
    string(REGEX REPLACE "^([a-zA-Z]):/" "/\\1/" _VCPKG_TOOL_PATH "${TOOL_PATH}")
    list(APPEND CONFIGURE_OPTIONS "--with-cross-build=${_VCPKG_TOOL_PATH}")
endif()

# configure fails for a fat iOS build, because linking a test executable for x86_64
# against the iPhoneOS SDK fails (its libSystem has no x86_64 slice), and ICU's configure
# does not support "universal" endianness anyway, so we configure only for the first
# architecture and add the rest to the generated Makefiles afterwards
if(VCPKG_TARGET_IS_IOS)
    list(LENGTH VCPKG_OSX_ARCHITECTURES OSX_ARCHITECTURES_COUNT)
    if(OSX_ARCHITECTURES_COUNT GREATER 1)
        set(ALL_OSX_ARCHITECTURES "${VCPKG_OSX_ARCHITECTURES}")
        list(GET ALL_OSX_ARCHITECTURES 0 VCPKG_OSX_ARCHITECTURES)
    endif()
endif()

vcpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    # AUTORECONF # needs Autoconf version 2.72
    OPTIONS
        ${CONFIGURE_OPTIONS}
        --disable-samples
        --disable-tests
        --disable-layoutex
    OPTIONS_RELEASE
        --disable-debug
        --enable-release
    OPTIONS_DEBUG
        --enable-debug
        --disable-release
)

if(DEFINED ALL_OSX_ARCHITECTURES)
    block()
        # the iPhoneOS SDK headers reject x86 architectures, so those have to be compiled against
        # the simulator SDK. CMake does that by itself (CMAKE_APPLE_ARCH_SYSROOTS), passing a sysroot
        # per architecture with `-Xarch_*`, but vcpkg-make gets just one sysroot for all of them
        vcpkg_cmake_get_vars(CMAKE_VARS_FILE)
        include("${CMAKE_VARS_FILE}")
        execute_process(
            COMMAND xcrun --sdk iphonesimulator --show-sdk-path
            OUTPUT_VARIABLE SIMULATOR_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY
        )
        set(ALL_ARCH_FLAGS "")
        set(ARCH_SYSROOT_FLAGS "")
        foreach(ARCH IN LISTS ALL_OSX_ARCHITECTURES)
            string(APPEND ALL_ARCH_FLAGS " -arch ${ARCH}")
            if(ARCH MATCHES "^(x86_64|i386)$")
                string(APPEND ARCH_SYSROOT_FLAGS " -Xarch_${ARCH} -isysroot${SIMULATOR_SYSROOT}")
            else()
                string(APPEND ARCH_SYSROOT_FLAGS " -Xarch_${ARCH} -isysroot${VCPKG_DETECTED_CMAKE_OSX_SYSROOT}")
            endif()
        endforeach()
        set(BUILD_DIRS "${TARGET_TRIPLET}-rel")
        if(NOT VCPKG_BUILD_TYPE)
            list(APPEND BUILD_DIRS "${TARGET_TRIPLET}-dbg")
        endif()
        # all the ICU makefiles take the compiler and flags from icudefs.mk
        foreach(BUILD_DIR IN LISTS BUILD_DIRS)
            set(ICUDEFS_FILE "${CURRENT_BUILDTREES_DIR}/${BUILD_DIR}/icudefs.mk")
            vcpkg_replace_string("${ICUDEFS_FILE}" " -isysroot ${VCPKG_DETECTED_CMAKE_OSX_SYSROOT}" "${ARCH_SYSROOT_FLAGS}")
            vcpkg_replace_string("${ICUDEFS_FILE}" " -arch ${VCPKG_OSX_ARCHITECTURES}" "${ALL_ARCH_FLAGS}")
        endforeach()
    endblock()
    set(VCPKG_OSX_ARCHITECTURES "${ALL_OSX_ARCHITECTURES}")
endif()

vcpkg_make_install(OPTIONS ${BUILD_OPTIONS})

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/share"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/icu"
    "${CURRENT_PACKAGES_DIR}/debug/lib/icu"
    "${CURRENT_PACKAGES_DIR}/debug/lib/icud")

file(GLOB TEST_LIBS
    "${CURRENT_PACKAGES_DIR}/lib/*test*"
    "${CURRENT_PACKAGES_DIR}/debug/lib/*test*")
if(TEST_LIBS)
    file(REMOVE ${TEST_LIBS})
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    # force U_STATIC_IMPLEMENTATION macro
    foreach(HEADER utypes.h utf_old.h platform.h)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/unicode/${HEADER}" "defined(U_STATIC_IMPLEMENTATION)" "1")
    endforeach()
endif()

# Install executables from /tools/icu/sbin to /tools/icu/bin on unix (/bin because icu require this for cross compiling)
if(VCPKG_TARGET_IS_LINUX OR VCPKG_TARGET_IS_OSX AND "tools" IN_LIST FEATURES)
    vcpkg_copy_tools(
        TOOL_NAMES icupkg gennorm2 gencmn genccode gensprep
        SEARCH_DIR "${CURRENT_PACKAGES_DIR}/tools/icu/sbin"
        DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin"
    )
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/tools/icu/sbin"
    "${CURRENT_PACKAGES_DIR}/tools/icu/debug")

# To cross compile, we need some files at specific positions. So lets copy them
file(GLOB CROSS_COMPILE_DEFS "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/config/icucross.*")
file(INSTALL ${CROSS_COMPILE_DEFS} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/config")

if(VCPKG_TARGET_IS_WINDOWS)
    string(REGEX MATCH "^[0-9]*" ICU_VERSION_MAJOR "${VERSION}")
    file(GLOB RELEASE_DLLS "${CURRENT_PACKAGES_DIR}/lib/*icu*${ICU_VERSION_MAJOR}.dll")
    file(COPY ${RELEASE_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")

    # copy dlls
    file(GLOB RELEASE_DLLS "${CURRENT_PACKAGES_DIR}/lib/*icu*${ICU_VERSION_MAJOR}.dll")
    file(COPY ${RELEASE_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    if(NOT VCPKG_BUILD_TYPE)
        file(GLOB DEBUG_DLLS "${CURRENT_PACKAGES_DIR}/debug/lib/*icu*${ICU_VERSION_MAJOR}.dll")
        file(COPY ${DEBUG_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    endif()

    # remove any remaining dlls in /lib
    file(GLOB DUMMY_DLLS "${CURRENT_PACKAGES_DIR}/lib/*.dll" "${CURRENT_PACKAGES_DIR}/debug/lib/*.dll")
    if(DUMMY_DLLS)
        file(REMOVE ${DUMMY_DLLS})
    endif()

    #vcpkg_copy_pdbs()
endif()

vcpkg_fixup_pkgconfig()

set(cxx_link_libraries "")
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    block(PROPAGATE cxx_link_libraries)
        vcpkg_cmake_get_vars(cmake_vars_file)
        include("${cmake_vars_file}")
        list(REMOVE_ITEM VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES ${VCPKG_DETECTED_CMAKE_C_IMPLICIT_LINK_LIBRARIES})
        list(TRANSFORM VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES REPLACE "^([^/]+)\$" "-l\\1")
        string(JOIN " " cxx_link_libraries ${VCPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES})
    endblock()
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-uc.pc" "baselibs = " "baselibs = ${cxx_link_libraries} ")
    if(NOT VCPKG_BUILD_TYPE)
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/icu-uc.pc" "baselibs = " "baselibs = ${cxx_link_libraries} ")
    endif()
endif()

vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/icu/bin/icu-config" "${CURRENT_INSTALLED_DIR}" "`dirname $0`/../../../" IGNORE_UNCHANGED)
vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/icu/bin/icu-config" "${CURRENT_HOST_INSTALLED_DIR}" "`dirname $0`/../../../../${_HOST_TRIPLET}/" IGNORE_UNCHANGED)

configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake" @ONLY)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
