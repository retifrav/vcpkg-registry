vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:assimp/assimp.git
    REF 9519a62dd20799c5493c638d1ef5a6f484e5faf1
    PATCHES
        cmake-config-paths.patch
        do-not-override-flags.patch
        do-not-vendor-zlib-ffs.patch
        disable-pkgconfig.patch
        winapi-uwp.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        double-precision ASSIMP_DOUBLE_PRECISION
        # importers
        all-importers     ASSIMP_BUILD_ALL_IMPORTERS_BY_DEFAULT
        importer-3ds      ASSIMP_BUILD_3DS_IMPORTER
        importer-3mf      ASSIMP_BUILD_3MF_IMPORTER
        importer-collada  ASSIMP_BUILD_COLLADA_IMPORTER
        importer-dxf      ASSIMP_BUILD_DXF_IMPORTER
        importer-fbx      ASSIMP_BUILD_FBX_IMPORTER
        importer-gltf     ASSIMP_BUILD_GLTF_IMPORTER
        importer-ifc      ASSIMP_BUILD_IFC_IMPORTER
        importer-obj      ASSIMP_BUILD_OBJ_IMPORTER
        importer-ply      ASSIMP_BUILD_PLY_IMPORTER
        importer-stl      ASSIMP_BUILD_STL_IMPORTER
        # exporters
        no-export        ASSIMP_NO_EXPORT # if the feature is not set, then -DASSIMP_NO_EXPORT=0
        exporter-obj     ASSIMP_BUILD_OBJ_EXPORTER
        exporter-opengex ASSIMP_BUILD_OPENGEX_EXPORTER
        exporter-ply     ASSIMP_BUILD_PLY_EXPORTER
        exporter-3ds     ASSIMP_BUILD_3DS_EXPORTER
        exporter-assbin  ASSIMP_BUILD_ASSBIN_EXPORTER
        exporter-assxml  ASSIMP_BUILD_ASSXML_EXPORTER
        exporter-m3d     ASSIMP_BUILD_M3D_EXPORTER
        exporter-collada ASSIMP_BUILD_COLLADA_EXPORTER
        exporter-fbx     ASSIMP_BUILD_FBX_EXPORTER
        exporter-stl     ASSIMP_BUILD_STL_EXPORTER
        exporter-x       ASSIMP_BUILD_X_EXPORTER
        exporter-x3d     ASSIMP_BUILD_X3D_EXPORTER
        exporter-gltf    ASSIMP_BUILD_GLTF_EXPORTER
        exporter-3mf     ASSIMP_BUILD_3MF_EXPORTER
        exporter-pbrt    ASSIMP_BUILD_PBRT_EXPORTER
        exporter-assjson ASSIMP_BUILD_ASSJSON_EXPORTER
        exporter-step    ASSIMP_BUILD_STEP_EXPORTER
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DASSIMP_BUILD_ASSIMP_TOOLS=0
        -DASSIMP_BUILD_SAMPLES=0
        -DASSIMP_BUILD_TESTS=0
        -DASSIMP_INSTALL_PDB=0
        -DASSIMP_BUILD_ZLIB=0
        -DASSIMP_WARNINGS_AS_ERRORS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
