vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/SPIRV-Cross.git
    REF 2c32b6bf86f3c4a5539aa1f0bacbd59fe61759cf
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DSPIRV_CROSS_ENABLE_CPP=0
        -DSPIRV_CROSS_ENABLE_REFLECT=0
        -DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS=1
        -DSPIRV_CROSS_ENABLE_TESTS=0
        -DSPIRV_CROSS_CLI=0
)

vcpkg_cmake_install()

foreach(COMPONENT core c glsl hlsl msl util) # cpp reflect
    # fixing possible problems with imported targets, such as "Policy CMP0111
    # is not set: An imported target missing its location property fails during generation" and so on
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "spirv_cross_${COMPONENT}"
        CONFIG_PATH "share/spirv_cross_${COMPONENT}/cmake"
    )
endforeach()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
