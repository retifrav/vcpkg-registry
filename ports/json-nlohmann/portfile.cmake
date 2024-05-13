vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:nlohmann/json.git
    REF 9cca280a4d0ccf0c08f47a99aa71d1b0e52f8d03
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DJSON_BuildTests=0
        -DJSON_Install=1
        #-DJSON_MultipleHeaders=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "nlohmann_json"
    CONFIG_PATH "share/cmake/nlohmann_json"
)

vcpkg_fixup_pkgconfig()

if(EXISTS "${CURRENT_PACKAGES_DIR}/nlohmann_json.natvis")
    file(RENAME
        "${CURRENT_PACKAGES_DIR}/nlohmann_json.natvis"
        "${CURRENT_PACKAGES_DIR}/share/nlohmann_json/nlohmann_json.natvis"
    )
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/share/nlohmann_json/nlohmann_jsonTargets.cmake"
        "{_IMPORT_PREFIX}/nlohmann_json.natvis"
        "{_IMPORT_PREFIX}/share/nlohmann_json/nlohmann_json.natvis"
    )
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.MIT")
