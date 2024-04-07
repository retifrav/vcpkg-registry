vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:asmaloney/libE57Format.git
    REF 1914b8ea972251d3bb49a33828497dde683205d9
    PATCHES
        optional-rapidxml-instead-of-xerces-c.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)

if("using-rapidxml" IN_LIST FEATURES)
    set(XML_LIBRARY "RapidXml")
else()
    set(XML_LIBRARY "XercesC")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DXML_LIBRARY=${XML_LIBRARY}
        -DE57_BUILD_TEST=0
        #-DE57_GIT_SUBMODULE_UPDATE=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME "E57Format"
)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
