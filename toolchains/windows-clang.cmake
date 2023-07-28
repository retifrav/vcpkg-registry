# based on https://github.com/Neumann-A/my-vcpkg-triplets/blob/284e937f98f20fe1b35915f3c63c5b4550f55918/x64-win-llvm/x64-win-llvm.toolchain.cmake
# it can probably be simplified even more

if(NOT _VCPKG_WINDOWS_TOOLCHAIN)
set(_VCPKG_WINDOWS_TOOLCHAIN 1)

# option(VCPKG_USE_LTO "Enable full LTO for Release builds" 0)

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>$<$<STREQUAL:${VCPKG_CRT_LINKAGE},dynamic>:DLL>" CACHE STRING "")
set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "") # "Embedded"

set(CMAKE_SYSTEM_NAME Windows CACHE STRING "")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(CMAKE_SYSTEM_PROCESSOR x86 CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(CMAKE_SYSTEM_PROCESSOR AMD64 CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(CMAKE_SYSTEM_PROCESSOR ARM CACHE STRING "")
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(CMAKE_SYSTEM_PROCESSOR ARM64 CACHE STRING "")
endif()

if(DEFINED VCPKG_CMAKE_SYSTEM_VERSION)
    set(CMAKE_SYSTEM_VERSION "${VCPKG_CMAKE_SYSTEM_VERSION}" CACHE STRING "" FORCE)
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR)
        set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86")
        # any of the four platforms can run x86 binaries
        set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ARM64")
        # arm64 can run binaries of any of the four platforms after Windows 11
        set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    endif()

    if(NOT DEFINED CMAKE_SYSTEM_VERSION)
        set(CMAKE_SYSTEM_VERSION "${CMAKE_HOST_SYSTEM_VERSION}" CACHE STRING "")
    endif()
endif()

# C standard
set(CMAKE_C_STANDARD 11 CACHE STRING "")
set(CMAKE_C_STANDARD_REQUIRED ON CACHE STRING "")
set(CMAKE_C_EXTENSIONS ON CACHE STRING "")
set(std_c_flags "-std:c11 -D__STDC__=1 -Wno-implicit-function-declaration") #/Zc:__STDC__
# -Wno-implicit-function-declaration because a lot of libraries don't #include <io.h>
# for read/open/access and clang 16 made that an error instead of a warning

# C++ standard
# set(CMAKE_CXX_STANDARD 17 CACHE STRING "")
# set(CMAKE_CXX_STANDARD_REQUIRED ON CACHE STRING "")
# set(CMAKE_CXX_EXTENSIONS OFF CACHE STRING "")
# set(std_cxx_flags "/permissive- -std:c++20 /Zc:__cplusplus")
# set(std_cxx_flags "/permissive- -std:c++17 /Zc:__cplusplus -Wno-register")

# Windows definitions
set(windows_definitions "/DWIN32 /D_WINDOWS")
# setting all of these might be an overkill
# if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
#     string(APPEND windows_definitions " /D_WIN64")
# endif()
# string(APPEND windows_definitions " /D_WIN32_WINNT=0x0A00 /DWINVER=0x0A00") # tweak for targeted Windows
# string(APPEND windows_definitions " /D_CRT_SECURE_NO_DEPRECATE /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_DEPRECATE")
# string(APPEND windows_definitions " /D_ATL_SECURE_NO_DEPRECATE /D_SCL_SECURE_NO_WARNINGS")
#
# due to -D__STDC__=1 required for e.g. _fopen -> fopen and other not underscored functions/defines
# without it there will be errors like use of undeclared identifier O_TRUNC
string(APPEND windows_definitions " /D_CRT_INTERNAL_NONSTDC_NAMES /D_CRT_DECLARE_NONSTDC_NAMES")
#
# string(APPEND windows_definitions " /D_FORCENAMELESSUNION") # due to -D__STDC__ to access tagVARIANT members (ffmpeg)

# try to ignore /WX and -werror, a lot of ports mess up the compiler detection and add wrong flags
# set(ignore_werror "/WX-")
# cmake_language(DEFER CALL add_compile_options "/WX-") # make sure the flag is added at the end

# general architecture flags
set(arch_flags "-mcrc32 -msse4.2 -maes -mpclmul")
# -mcrc32 for libpq
# -mrtm for tbb (will break qtdeclarative since it cannot run the executables in CI)
# -msse4.2 for everything which normally cl can use (otherwise strict sse2 only)
# -maes -mpclmul mbedtls
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    string(APPEND arch_flags " -m32 --target=i686-pc-windows-msvc")
endif()
# /Za unknown

get_property( _CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE )
if(NOT _CMAKE_IN_TRY_COMPILE)
    # runtime library
    if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
        set(VCPKG_CRT_LINK_FLAG_PREFIX "/MD")
    elseif(VCPKG_CRT_LINKAGE STREQUAL "static")
        set(VCPKG_CRT_LINK_FLAG_PREFIX "/MT")
    else()
        message(FATAL_ERROR "Invalid setting for VCPKG_CRT_LINKAGE: \"${VCPKG_CRT_LINKAGE}\". It must be \"static\" or \"dynamic\"")
    endif()

    # charset flag
    set(CHARSET_FLAG "/utf-8")
    if (NOT VCPKG_SET_CHARSET_FLAG OR VCPKG_PLATFORM_TOOLSET MATCHES "v120")
        # VS 2013 does not support /utf-8
        set(CHARSET_FLAG)
    endif()

    set(CMAKE_CL_NOLOGO "/nologo" CACHE STRING "")

    # compiler
    find_program(CLANG_CL_EXECUTBALE
        NAMES
            "clang-cl"
            "clang-cl.exe"
        PATHS
            ENV
            LLVMInstallDir
        PATH_SUFFIXES
            "bin"
        #NO_DEFAULT_PATH
    )

    if(NOT CLANG_CL_EXECUTBALE)
        message(SEND_ERROR "clang-cl was not found") # not a FATAL_ERROR due to being a toolchain
    endif()

    get_filename_component(LLVM_BIN_DIR "${CLANG_CL_EXECUTBALE}" DIRECTORY)
    list(INSERT CMAKE_PROGRAM_PATH 0 "${LLVM_BIN_DIR}")

    set(CMAKE_C_COMPILER "${CLANG_CL_EXECUTBALE}" CACHE STRING "")
    set(CMAKE_CXX_COMPILER "${CLANG_CL_EXECUTBALE}" CACHE STRING "")
    set(CMAKE_AR "${LLVM_BIN_DIR}/llvm-lib.exe" CACHE STRING "")
    #set(CMAKE_AR "${LLVM_BIN_DIR}/llvm-ar.exe" CACHE STRING "")
    #set(CMAKE_RANLIB "${LLVM_BIN_DIR}/llvm-ranlib.exe" CACHE STRING "")
    set(CMAKE_LINKER "${LLVM_BIN_DIR}/lld-link.exe" CACHE STRING "")
    #set(CMAKE_LINKER "${CLANG_CL_EXECUTBALE}" CACHE STRING "")
    #set(CMAKE_LINKER "link.exe" CACHE STRING "" FORCE)
    set(CMAKE_ASM_MASM_COMPILER "ml64.exe" CACHE STRING "")
    #set(CMAKE_RC_COMPILER "${LLVM_BIN_DIR}/llvm-rc.exe" CACHE STRING "" FORCE)
    set(CMAKE_RC_COMPILER "rc.exe" CACHE STRING "")
    set(CMAKE_MT "mt.exe" CACHE STRING "")

    # compiler flags
    # set(CLANG_FLAGS "/clang:-fasm -fmacro-backtrace-limit=0") #/clang:-fopenmp-simd -openmp

    set(VCPKG_DBG_FLAG "/Z7") # /Brepro

    set(CLANG_C_LTO_FLAGS "-fuse-ld=lld-link")
    set(CLANG_CXX_LTO_FLAGS "-fuse-ld=lld-link")
    # if(VCPKG_USE_LTO)
    #     set(CLANG_C_LTO_FLAGS "-flto -fuse-ld=lld-link")
    #     set(CLANG_CXX_LTO_FLAGS "-flto -fuse-ld=lld-link -fwhole-program-vtables")
    # endif()

    set(CMAKE_C_FLAGS "${CMAKE_CL_NOLOGO} ${windows_definitions} ${arch_flags} ${VCPKG_C_FLAGS} ${CLANG_FLAGS} ${CHARSET_FLAG} ${std_c_flags}" CACHE STRING "") # ${ignore_werror}
    set(CMAKE_C_FLAGS_DEBUG "/Od /Ob0 /GS /RTC1 /FC ${VCPKG_C_FLAGS_DEBUG} ${VCPKG_CRT_LINK_FLAG_PREFIX}d ${VCPKG_DBG_FLAG} /D_DEBUG" CACHE STRING "")
    set(CMAKE_C_FLAGS_RELEASE "/O2 /Oi ${CLANG_FLAGS_RELEASE} ${VCPKG_C_FLAGS_RELEASE} ${VCPKG_CRT_LINK_FLAG_PREFIX} ${CLANG_C_LTO_FLAGS} /DNDEBUG" CACHE STRING "")

    set(CMAKE_CXX_FLAGS "${CMAKE_CL_NOLOGO} /EHsc /GR ${windows_definitions} ${arch_flags} ${VCPKG_CXX_FLAGS} ${CLANG_FLAGS} ${CHARSET_FLAG} ${std_cxx_flags}" CACHE STRING "") # ${ignore_werror}
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /FC ${VCPKG_CXX_FLAGS_DEBUG} ${VCPKG_DBG_FLAG}" CACHE STRING "")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${VCPKG_CXX_FLAGS_RELEASE} ${CLANG_CXX_LTO_FLAGS}" CACHE STRING "")

    # linker flags (perhaps replace all that with what default Windows toolchain does)
    foreach(linker IN ITEMS "SHARED" "MODULE" "EXE")
        set(CMAKE_${linker}_LINKER_FLAGS_INIT "${CMAKE_CL_NOLOGO} /INCREMENTAL:NO /Brepro ${VCPKG_LINKER_FLAGS}" CACHE STRING "")
        set(CMAKE_${linker}_LINKER_FLAGS "${CMAKE_CL_NOLOGO} /INCREMENTAL:NO /Brepro ${VCPKG_LINKER_FLAGS}" CACHE STRING "")
        set(CMAKE_${linker}_LINKER_FLAGS_DEBUG "/DEBUG:FULL ${VCPKG_LINKER_FLAGS_DEBUG}" CACHE STRING "")
        set(CMAKE_${linker}_LINKER_FLAGS_RELEASE "/DEBUG /OPT:REF /OPT:ICF ${VCPKG_LINKER_FLAGS_RELEASE}" CACHE STRING "") # ${sanitizer_path} ${sanitizer_libs}
    endforeach()
    #
    foreach(lang IN ITEMS C CXX)
        foreach(linker IN ITEMS "SHARED" "MODULE" "EXE")
            set(CMAKE_${lang}_${linker}_LINKER_FLAGS "${CMAKE_${linker}_LINKER_FLAGS}" CACHE STRING "")
            set(CMAKE_${lang}_${linker}_LINKER_FLAGS_DEBUG "${CMAKE_${linker}_LINKER_FLAGS_DEBUG}" CACHE STRING "")
            set(CMAKE_${lang}_${linker}_LINKER_FLAGS_RELEASE "${CMAKE_${linker}_LINKER_FLAGS_RELEASE}" CACHE STRING "")
        endforeach()
    endforeach()

    # assembler flags
    set(CMAKE_ASM_MASM_FLAGS_INIT "${CMAKE_CL_NOLOGO}")

    # resource compiler flags
    set(CMAKE_RC_FLAGS_INIT "-c65001 ${windows_definitions}")
    set(CMAKE_RC_FLAGS_DEBUG_INIT "-D_DEBUG")
endif()

endif() # _VCPKG_WINDOWS_TOOLCHAIN
