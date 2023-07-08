vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/draco.git
    REF 1af95a20b81624f64c4b19794cb3ca991e6d0a76
    PATCHES
        installation-tools-pkg.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        wasm DRACO_WASM
        tools DRACO_WITH_TOOLS
)

# for some reasons it isn't good enough for them to just use the EMSDK variable
if(NOT DEFINED ENV{EMSCRIPTEN})
    set(ENV{EMSCRIPTEN} "$ENV{EMSDK}/upstream/emscripten")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDRACO_FAST=0
        -DDRACO_MESH_COMPRESSION=1
        -DDRACO_POINT_CLOUD_COMPRESSION=1
        -DDRACO_PREDICTIVE_EDGEBREAKER=1
        -DDRACO_STANDARD_EDGEBREAKER=1
        -DDRACO_BACKWARDS_COMPATIBILITY=1
        -DDRACO_DECODER_ATTRIBUTE_DEDUPLICATION=0
        -DDRACO_TESTS=0
        -DDRACO_JS_GLUE=0
        -DDRACO_UNITY_PLUGIN=0
        -DDRACO_ANIMATION_ENCODING=0
        -DDRACO_GLTF_BITSTREAM=0
        -DDRACO_MAYA_PLUGIN=0
        -DDRACO_TRANSCODER_SUPPORTED=0
)

vcpkg_cmake_install()

if("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(
        TOOL_NAMES
            draco_encoder
            draco_decoder
        AUTO_CLEAN
    )
endif()

vcpkg_cmake_config_fixup(CONFIG_PATH "share/cmake/${PORT}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
