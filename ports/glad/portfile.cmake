vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:Dav1dde/glad.git
    REF 73db193f853e2ee079bf3ca8a64aa2eaf6459043
    PATCHES
        001-installation.patch
)

file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}/cmake"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}/cmake"
)

vcpkg_find_acquire_program(PYTHON3)
# if we want this Python to be available in the PATH
# get_filename_component(PYTHON_DIR ${PYTHON3} DIRECTORY)
# vcpkg_add_to_path("${PYTHON_DIR}") # you might want to PREPEND it
#
x_vcpkg_get_python_packages(
    PYTHON_VERSION "3"
    PYTHON_EXECUTABLE ${PYTHON3}
    PACKAGES jinja2
    OUT_PYTHON_VAR "PYTHON_VENV"
)
# in case of venv we want that one to be available in the PATH
get_filename_component(PYTHON_VENV_DIR ${PYTHON_VENV} DIRECTORY)
vcpkg_add_to_path("${PYTHON_VENV_DIR}") # you might want to PREPEND it
#message(STATUS "PYTHON_VENV: ${PYTHON_VENV}")

set(GLAD_LIBRARY_TYPE "STATIC")
if("${VCPKG_LIBRARY_LINKAGE}" STREQUAL "dynamic")
    set(GLAD_LIBRARY_TYPE "SHARED")
endif()

set(GLAD_API "")
# one version per API type, as it only accepts the last occurrence anyway,
# so for example out of the string `gl:core=4.6;gl:core=4.3;gl:core=4.1;vulkan=1.4;vulkan=1.3`
# it will take `4.1` for `gl` and `1.3` for `vulkan` (so it actually ignores
# non-existent (at the moment) version `1.4`, which would otherwise fail the build),
# but then what should we do if someone wants not the latest version but one of the older ones,
# or/and maybe `compatibility` profile instead of `core`? And actually, in case of the latest versions
# it is not required to provide the version value, so for the latest OpenGL 4.6 providing `gl:core=4.6`
# is the same as providing `gl:core=`
if(
    "egl" IN_LIST FEATURES # this one seems to be required for the OpenGL ones too, so they belong together
    OR
    "gl" IN_LIST FEATURES
    OR
    "gles1" IN_LIST FEATURES
    OR
    "gles2" IN_LIST FEATURES
    OR
    "glsc2" IN_LIST FEATURES
    OR
    "glx" IN_LIST FEATURES
    OR
    "wgl" IN_LIST FEATURES
)
    file(
        COPY
            "${CURRENT_INSTALLED_DIR}/share/opengl/gl.xml"
            "${CURRENT_INSTALLED_DIR}/share/opengl/glx.xml"
            "${CURRENT_INSTALLED_DIR}/share/opengl/wgl.xml"
            "${CURRENT_INSTALLED_DIR}/include/EGL/eglplatform.h"
            "${CURRENT_INSTALLED_DIR}/include/KHR/khrplatform.h"
            "${CURRENT_INSTALLED_DIR}/share/opengl/egl.xml"
        DESTINATION
            "${SOURCE_PATH}/glad/files"
    )

    if("egl" IN_LIST FEATURES)
        list(APPEND GLAD_API "egl=") # egl=1.5
    endif()
    if("gl" IN_LIST FEATURES)
        list(APPEND GLAD_API "gl:core=") # gl:core=4.6
    endif()
    if("gles1" IN_LIST FEATURES)
        list(APPEND GLAD_API "gles1=") # gles1=1.0
    endif()
    if("gles2" IN_LIST FEATURES)
        list(APPEND GLAD_API "gles2=") # gles2=3.2
    endif()
    if("glsc2" IN_LIST FEATURES)
        list(APPEND GLAD_API "glsc2=") # glsc2=2.0
    endif()
    if("glx" IN_LIST FEATURES)
        list(APPEND GLAD_API "glx=") # glx=1.4
    endif()
    if("wgl" IN_LIST FEATURES)
        list(APPEND GLAD_API "wgl=") # wgl=1.0
    endif()
endif()

if("vulkan" IN_LIST FEATURES)
    file(
        COPY
            "${CURRENT_INSTALLED_DIR}/include/vulkan/vk_platform.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_av1std.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_av1std_decode.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h264std.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h264std_decode.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h264std_encode.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h265std.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h265std_decode.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codec_h265std_encode.h"
            "${CURRENT_INSTALLED_DIR}/include/vk_video/vulkan_video_codecs_common.h"
        DESTINATION
            "${SOURCE_PATH}/glad/files"
    )

    list(APPEND GLAD_API "vulkan=1.3")
endif()

list(JOIN GLAD_API "," GLAD_API_STRING)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/cmake"
    OPTIONS
        -DGLAD_VERSION="${VERSION}"
        -DGLAD_LIBRARY_TYPE="${GLAD_LIBRARY_TYPE}"
        -DGLAD_API="${GLAD_API_STRING}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
