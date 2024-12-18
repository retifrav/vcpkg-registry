vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:yoctopuce/yoctolib_cpp.git
    REF 2f6d067ce757db86779cf435aa3172859529982e
    PATCHES
        001-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/Sources"
)
# CMake config template for yoctopuce
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/Sources"
)
# CMake config template for yapi
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/Sources/yapi"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/Sources"
    OPTIONS
        -DUSE_YSSL=0
)

vcpkg_cmake_install()

foreach(yoctopuceComponent "yoctopuce" "yapi")
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME "${yoctopuceComponent}"
    )
endforeach()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/LICENSE")
