vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:capstone-engine/capstone.git
    REF 5cca00533dadfe53181f1de3525f859769f69b65
)

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" STATIC_CRT)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        "arm"        CAPSTONE_ARM_SUPPORT
        "arm64"      CAPSTONE_ARM64_SUPPORT
        "bpf"        CAPSTONE_BPF_SUPPORT
        "evm"        CAPSTONE_EVM_SUPPORT
        "m680x"      CAPSTONE_M680X_SUPPORT
        "m68k"       CAPSTONE_M68K_SUPPORT
        "mips"       CAPSTONE_MIPS_SUPPORT
        "mos65xx"    CAPSTONE_MOS65XX_SUPPORT
        "ppc"        CAPSTONE_PPC_SUPPORT
        "riscv"      CAPSTONE_RISCV_SUPPORT
        "sparc"      CAPSTONE_SPARC_SUPPORT
        "sysz"       CAPSTONE_SYSZ_SUPPORT
        "tms320c64x" CAPSTONE_TMS320C64X_SUPPORT
        "tricore"    CAPSTONE_TRICORE_SUPPORT
        "wasm"       CAPSTONE_WASM_SUPPORT
        "x86"        CAPSTONE_X86_SUPPORT
        "xcore"      CAPSTONE_XCORE_SUPPORT
        "diet"       CAPSTONE_BUILD_DIET
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DCAPSTONE_ARCHITECTURE_DEFAULT=0
        -DCAPSTONE_BUILD_TESTS=0
        -DCAPSTONE_BUILD_CSTOOL=0
        -DCAPSTONE_BUILD_STATIC_RUNTIME=${STATIC_CRT}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.TXT")
