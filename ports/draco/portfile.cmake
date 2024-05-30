vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:google/draco.git
    REF 8786740086a9f4d83f44aa83badfbea4dce7a1b5
    PATCHES
        installation-and-optional-tools.patch
)

vcpkg_find_acquire_program(PYTHON3)
# if we want this Python to be available in the PATH
get_filename_component(PYTHON_DIR ${PYTHON3} DIRECTORY)
vcpkg_add_to_path("${PYTHON_DIR}") # you might want to PREPEND it

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        gltf-bitstream DRACO_GLTF_BITSTREAM
        tools DRACO_WITH_TOOLS
        transcoder DRACO_TRANSCODER_SUPPORTED
        wasm DRACO_WASM
)

if("transcoder" IN_LIST FEATURES)
    message(
        WARNING
            "[WARNING] This version of Draco does not support the latest version of TinyGLTF, "
            "so you'll need to restrict it to an older one (such as `2.4.0`) in your project's "
            "vcpkg.json manifest (via `overrides`)."
    )
endif()

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
        -DDRACO_MAYA_PLUGIN=0
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

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
