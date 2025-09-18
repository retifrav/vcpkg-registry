# does not export symbols for making a DLL
if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

# carefully check the commit hashes every time you are updating the version
set(GIT_COMMIT_HASH "bf75bfec48fc00f532af8926130b70c0e26eb099") # version tag commit from `master` branch
if("docking" IN_LIST FEATURES)
    set(GIT_COMMIT_HASH "62275e877a691bd2e51d1ca86bdfed49fa5cb297") # version tag commit from `docking` branch
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:ocornut/imgui.git
    REF ${GIT_COMMIT_HASH}
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"  DESTINATION "${SOURCE_PATH}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        backend-glfw-opengl BACKEND_OPENGL3
        backend-glfw-vulkan BACKEND_VULKAN
        platform-win32 PLATFORM_WIN32
        with-internal WITH_INTERNAL
        with-stb-textedit WITH_STB_TEXTEDIT
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DDEARIMGUI_VERSION="${VERSION}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

if("math-operators" IN_LIST FEATURES)
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/${PORT}/imconfig.h"
        "//#define IMGUI_DEFINE_MATH_OPERATORS"
        "#define IMGUI_DEFINE_MATH_OPERATORS"
    )
endif()

if("indices-x32" IN_LIST FEATURES)
    vcpkg_replace_string(
        "${CURRENT_PACKAGES_DIR}/include/${PORT}/imconfig.h"
        "//#define ImDrawIdx unsigned int"
        "#define ImDrawIdx unsigned int"
    )
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
