vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:OSGeo/libgeotiff.git
    REF 96024f677642486f97cac43659bef57f4ed0590b
    PATCHES
        001-dependencies-and-installation.patch
)

# what is this "project" file even for, the library is never used anywhere and it's missing linking to TIFF anyway
file(REMOVE
    "${SOURCE_PATH}/libgeotiff/libxtiff/CMakeLists.txt"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}/libgeotiff")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        with-jpeg WITH_JPEG
        with-zlib WITH_ZLIB
        tools WITH_UTILITIES
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/libgeotiff"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DBUILD_DOC=0
        -DBUILD_MAN=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(
        TOOL_NAMES
            applygeo
            geotifcp
            listgeo
            makegeo
        AUTO_CLEAN
    )
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/libgeotiff/LICENSE")
