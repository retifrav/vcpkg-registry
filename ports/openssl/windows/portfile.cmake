# need cmd to pass quoted CC from nmake to mkbuildinf.pl
# https://github.com/microsoft/vcpkg/issues/37134
find_program(CMD_EXECUTABLE cmd HINTS ENV PATH NO_DEFAULT_PATH REQUIRED)
cmake_path(NATIVE_PATH CMD_EXECUTABLE cmd)
set(ENV{COMSPEC} "${cmd}")

vcpkg_find_acquire_program(PERL)
get_filename_component(PERL_EXE_PATH "${PERL}" DIRECTORY)
vcpkg_add_to_path("${PERL_EXE_PATH}")

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(OPENSSL_ARCH VC-WIN32)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(OPENSSL_ARCH VC-WIN64A)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(OPENSSL_ARCH VC-WIN32-ARM)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    if(VCPKG_TARGET_IS_UWP)
        set(OPENSSL_ARCH VC-WIN64-ARM)
    elseif(VCPKG_DETECTED_CMAKE_C_COMPILER_ID MATCHES "Clang")
        set(OPENSSL_ARCH VC-CLANG-WIN64-CLANGASM-ARM)
    else()
        set(OPENSSL_ARCH VC-WIN64-CLANGASM-ARM)
    endif()
else()
    message(FATAL_ERROR "Unsupported target architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

if(VCPKG_TARGET_IS_UWP)
    vcpkg_list(APPEND CONFIGURE_OPTIONS
        no-unit-test
        no-asm
        no-uplink
    )
    string(APPEND OPENSSL_ARCH "-UWP")
endif()

if(VCPKG_CONCURRENCY GREATER "1")
    vcpkg_list(APPEND CONFIGURE_OPTIONS no-makedepend)
endif()

cmake_path(NATIVE_PATH CURRENT_PACKAGES_DIR NORMALIZE install_dir_native)

# Clang always uses `/Z7`
# patching `/Zi /Fd<Name>` out of OpenSSL requires more work
set(OPENSSL_BUILD_MAKES_PDBS ON)
if (VCPKG_DETECTED_CMAKE_C_COMPILER_ID MATCHES "Clang" OR VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(OPENSSL_BUILD_MAKES_PDBS OFF)
endif()

cmake_path(NATIVE_PATH VCPKG_DETECTED_CMAKE_C_COMPILER NORMALIZE cc)
if(OPENSSL_ARCH MATCHES "CLANG")
    vcpkg_find_acquire_program(CLANG)
    cmake_path(GET CLANG PARENT_PATH clang_path)
    vcpkg_add_to_path("${clang_path}")
    if(VCPKG_DETECTED_CMAKE_C_COMPILER_ID MATCHES "Clang")
        string(APPEND VCPKG_COMBINED_C_FLAGS_DEBUG " --target=aarch64-win32-msvc")
        string(APPEND VCPKG_COMBINED_C_FLAGS_RELEASE " --target=aarch64-win32-msvc")
    endif()
endif()
if(OPENSSL_ARCH MATCHES "CLANGASM")
    vcpkg_list(APPEND CONFIGURE_OPTIONS "ASFLAGS=--target=aarch64-win32-msvc")
else()
    vcpkg_find_acquire_program(NASM)
    cmake_path(NATIVE_PATH NASM NORMALIZE as)
    cmake_path(GET NASM PARENT_PATH nasm_path)
    vcpkg_add_to_path("${nasm_path}") # Needed by Configure
endif()

cmake_path(NATIVE_PATH VCPKG_DETECTED_CMAKE_AR NORMALIZE ar)
cmake_path(NATIVE_PATH VCPKG_DETECTED_CMAKE_LINKER NORMALIZE ld)

# `--prefix` and `--openssldir` are not set here, because OpenSSL compiles them into the libraries
# as the default locations of its configuration file, engines and modules, and the packages folder
# on the build machine is a path that an unprivileged user on another machine might be able to create
# and plant something there to be loaded into a privileged process (CVE-2026-34054, see
# https://github.com/microsoft/vcpkg/pull/50518), so OpenSSL keeps its default `Program Files` paths,
# which require administrative permissions, and the results are installed with `DESTDIR` instead
# and then moved to where they should be
vcpkg_build_nmake(
    SOURCE_PATH "${SOURCE_PATH}"
    PREFER_JOM
    CL_LANGUAGE NONE
    PRERUN_SHELL_RELEASE "${PERL}" Configure
        ${CONFIGURE_OPTIONS}
        ${OPENSSL_ARCH}
        "AS=${as}"
        "CC=${cc}"
        "CFLAGS=${VCPKG_COMBINED_C_FLAGS_RELEASE}"
        "AR=${ar}"
        "ARFLAGS=${VCPKG_COMBINED_STATIC_LINKER_FLAGS_RELEASE}"
        "LD=${ld}"
        "LDFLAGS=${VCPKG_COMBINED_SHARED_LINKER_FLAGS_RELEASE}"
    PRERUN_SHELL_DEBUG "${PERL}" Configure
        ${CONFIGURE_OPTIONS}
        ${OPENSSL_ARCH}
        --debug
        "AS=${as}"
        "CC=${cc}"
        "CFLAGS=${VCPKG_COMBINED_C_FLAGS_DEBUG}"
        "AR=${ar}"
        "ARFLAGS=${VCPKG_COMBINED_STATIC_LINKER_FLAGS_DEBUG}"
        "LD=${ld}"
        "LDFLAGS=${VCPKG_COMBINED_SHARED_LINKER_FLAGS_DEBUG}"
    PROJECT_NAME "makefile"
    TARGET install_dev install_modules ${INSTALL_FIPS}
    LOGFILE_ROOT install
    OPTIONS
        "INSTALL_PDBS=${OPENSSL_BUILD_MAKES_PDBS}" # install-pdbs.patch
    OPTIONS_RELEASE
        "DESTDIR=${install_dir_native}"
        install_runtime install_ssldirs # extra targets
    OPTIONS_DEBUG
        "DESTDIR=${install_dir_native}\\debug"
)

# moves what was installed into `Program Files/OpenSSL/` under `DESTDIR` up into `DESTDIR` itself,
# and returns the `Program Files` folder, in which `Common Files/SSL/` (OPENSSLDIR) is left
function(z_rearrange_openssl_dirs)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "FLAVOR_PREFIX;OUT_PROGRAM_FILES_DIR" "")
    if(DEFINED ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "z_rearrange_openssl_dirs() was passed extra arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    set(PREFIX_DIR "${CURRENT_PACKAGES_DIR}${ARG_FLAVOR_PREFIX}")
    # `Program Files` or `Program Files (x86)`, depending on the target architecture
    file(GLOB PROGRAM_FILES_DIR LIST_DIRECTORIES true "${PREFIX_DIR}/Program*")
    list(LENGTH PROGRAM_FILES_DIR PROGRAM_FILES_DIR_COUNT)
    if(NOT PROGRAM_FILES_DIR_COUNT EQUAL 1)
        message(FATAL_ERROR "Expected exactly one Program Files folder in ${PREFIX_DIR}, found: ${PROGRAM_FILES_DIR}")
    endif()
    set(OPENSSL_INSTALL_DIR "${PROGRAM_FILES_DIR}/OpenSSL")
    if(NOT EXISTS "${OPENSSL_INSTALL_DIR}")
        message(FATAL_ERROR "${OPENSSL_INSTALL_DIR} does not exist")
    endif()

    # there is no `file()` command that would move folders and merge them with the existing ones
    file(GLOB OPENSSL_INSTALL_ITEMS LIST_DIRECTORIES true "${OPENSSL_INSTALL_DIR}/*")
    file(COPY ${OPENSSL_INSTALL_ITEMS} DESTINATION "${PREFIX_DIR}")
    file(REMOVE_RECURSE "${OPENSSL_INSTALL_DIR}")

    set("${ARG_OUT_PROGRAM_FILES_DIR}" "${PROGRAM_FILES_DIR}" PARENT_SCOPE)
endfunction()

z_rearrange_openssl_dirs(OUT_PROGRAM_FILES_DIR RELEASE_PROGRAM_FILES_DIR)
set(RELEASE_OPENSSLDIR "${RELEASE_PROGRAM_FILES_DIR}/Common Files/SSL")
if(NOT VCPKG_BUILD_TYPE)
    z_rearrange_openssl_dirs(
        FLAVOR_PREFIX "/debug"
        OUT_PROGRAM_FILES_DIR DEBUG_PROGRAM_FILES_DIR
    )
    file(REMOVE_RECURSE "${DEBUG_PROGRAM_FILES_DIR}")
endif()

if("tools" IN_LIST FEATURES)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    file(COPY_FILE "${RELEASE_OPENSSLDIR}/openssl.cnf" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/openssl.cnf")
    if("fips" IN_LIST FEATURES)
        file(COPY_FILE "${RELEASE_OPENSSLDIR}/fipsmodule.cnf" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/fipsmodule.cnf")
    endif()
    file(RENAME "${CURRENT_PACKAGES_DIR}/bin/c_rehash.pl" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/c_rehash.pl")
    file(COPY_FILE "${RELEASE_OPENSSLDIR}/misc/CA.pl" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/CA.pl")
    file(COPY_FILE "${RELEASE_OPENSSLDIR}/misc/tsget.pl" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/tsget.pl")
    vcpkg_copy_tools(TOOL_NAMES openssl AUTO_CLEAN)
else()
    file(REMOVE "${CURRENT_PACKAGES_DIR}/bin/c_rehash.pl")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
    endif()
endif()
file(REMOVE "${CURRENT_PACKAGES_DIR}/debug/bin/c_rehash.pl")

# unlike upstream, not leaving the rest of `Program Files` (OPENSSLDIR with the configuration files
# and the empty `certs/` and `private/`) in the package, as nothing would read it from there
file(REMOVE_RECURSE
    "${RELEASE_PROGRAM_FILES_DIR}"
    "${CURRENT_PACKAGES_DIR}/lib/engines-3"
    "${CURRENT_PACKAGES_DIR}/debug/lib/engines-3"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
