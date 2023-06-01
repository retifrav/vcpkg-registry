vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:ocornut/imgui.git
    REF 9aae45eb4a05a5a1f96be1ef37eb503a12ceb889
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"   DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Installing.cmake" DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"  DESTINATION "${SOURCE_PATH}")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        backend-glfw BACKEND_GLFW
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(
    INSTALL "${SOURCE_PATH}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)

decovar_vcpkg_cmake_ololo()
