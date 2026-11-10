# not sure if this needs to be enforced, maybe the rest of Mesa doesn't support that,
# but so far we only needed SpirvToDxil, and that one seems to build (and work?) fine
#vcpkg_check_linkage(ONLY_DYNAMIC_CRT)

if(VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled) # some parts of this port can only build as a shared library
endif()

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://gitlab.freedesktop.org/mesa/mesa.git
    REF 97341aa7d7c340c9a4dbec192795dadd733b5846
    PATCHES
        001-dependencies.patch
        002-single-library-type-spirv-to-dxil.patch
        003-disable-we4189.patch # fails `src/compiler/nir/nir_lower_non_uniform_access.c:75`, should be fixed properly instead if disabling
)

x_vcpkg_get_python_packages(
    PYTHON_VERSION "3"
    OUT_PYTHON_VAR "PYTHON3"
    PACKAGES
        packaging
        mako
        pyyaml # doesn't seem to be needed on Windows, but is needed on other platforms
)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path(PREPEND "${PYTHON3_DIR}")

# flex and bison are required only for the GLSL compiler and the like, which Mesa builds
# with OpenGL / OpenGL ES (or with Gallium drivers and some of the tools) - all that
# originates in Mesa's `meson.build` at `needs_flex_bison`
if("opengl" IN_LIST FEATURES OR "gles1" IN_LIST FEATURES OR "gles2" IN_LIST FEATURES)
    vcpkg_find_acquire_program(FLEX)
    get_filename_component(FLEX_DIR "${FLEX}" DIRECTORY)
    vcpkg_add_to_path(PREPEND "${FLEX_DIR}")
    vcpkg_find_acquire_program(BISON)
    get_filename_component(BISON_DIR "${BISON}" DIRECTORY)
    vcpkg_add_to_path(PREPEND "${BISON_DIR}")

    if(CMAKE_HOST_WIN32) # Windows hosts might already have win_flex and win_bison
        if(NOT EXISTS "${FLEX_DIR}/flex${VCPKG_HOST_EXECUTABLE_SUFFIX}")
            if(FLEX_DIR MATCHES "${DOWNLOADS}")
                file(CREATE_LINK "${FLEX}" "${FLEX_DIR}/flex${VCPKG_HOST_EXECUTABLE_SUFFIX}")
            else()
                message(FATAL_ERROR "${PORT} requires flex being named flex on windows and not win_flex!\nThat can be solved by creating a simple link from win_flex to flex")
            endif()
        endif()
        if(NOT EXISTS "${BISON_DIR}/BISON${VCPKG_HOST_EXECUTABLE_SUFFIX}")
            if(BISON_DIR MATCHES "${DOWNLOADS}")
                file(CREATE_LINK "${BISON}" "${BISON_DIR}/bison${VCPKG_HOST_EXECUTABLE_SUFFIX}")
            else()
                message(FATAL_ERROR "${PORT} requires bison being named bison on windows and not win_bison!\nThat can be solved by creating a simple link from win_bison to bison")
            endif()
        endif()
    endif()
endif()

# https://github.com/pal1000/mesa-dist-win
# Mesa enables every `auto` feature whose dependency it finds in the installed tree,
# so the result would depend on whatever other ports happen to be installed
list(APPEND MESA_OPTIONS -Dauto_features=disabled)
# SPIRV-Tools is only used for disassembling shaders with `MESA_SPIRV_DEBUG=asm`,
# but when found, it makes spirv_to_dxil reference spv* symbols, which consumers
# then have to resolve
list(APPEND MESA_OPTIONS -Dspirv-tools=disabled)
list(APPEND MESA_OPTIONS -Dvalgrind=disabled)
list(APPEND MESA_OPTIONS -Dshared-llvm=disabled)
list(APPEND MESA_OPTIONS -Dcpp_rtti=true)
# this port only builds spirv-to-dxil at the moment, so it does not need gallium
# or vulkan drivers. Mesa's default `gallium-drivers=['auto']` pulls in llvmpipe
# on Windows, which requires LLVM and conflicts with `-Dllvm=disabled`
list(APPEND MESA_OPTIONS -Dgallium-drivers=[])
list(APPEND MESA_OPTIONS -Dvulkan-drivers=[])

if("opengl" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dopengl=true)
else()
    list(APPEND MESA_OPTIONS -Dopengl=false)
endif()

# seems to be deprecated?
#if("offscreen" IN_LIST FEATURES)
#    list(APPEND MESA_OPTIONS -Dosmesa=true)
#else()
#    list(APPEND MESA_OPTIONS -Dosmesa=false)
#endif()

if("llvm" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dllvm=enabled)
else()
    list(APPEND MESA_OPTIONS -Dllvm=disabled)
endif()

set(MESA_USE_GLES NO)
if("gles1" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dgles1=enabled)
    set(MESA_USE_GLES YES)
else()
    list(APPEND MESA_OPTIONS -Dgles1=disabled)
endif()
if("gles2" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dgles2=enabled)
    set(MESA_USE_GLES YES)
else()
    list(APPEND MESA_OPTIONS -Dgles2=disabled)
endif()
# seems to be deprecated?
#if(MESA_USE_GLES)
#    list(APPEND MESA_OPTIONS -Dshared-glapi=enabled) # shared GLAPI is required when building two or more of the following APIs: `gles1` and `gles2`
#else()
#    list(APPEND MESA_OPTIONS -Dshared-glapi=auto)
#endif()

if("egl" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Degl=enabled)
else()
    list(APPEND MESA_OPTIONS -Degl=disabled)
endif()

if("spirv-to-dxil" IN_LIST FEATURES)
    if(NOT VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "The spirv-to-dxil library builds only(?) on Windows")
    else()
        list(APPEND MESA_OPTIONS -Dspirv-to-dxil=true) # so the rest are `enabled`, but this one is `true`, m'kay
    endif()
# else()
#     list(APPEND MESA_OPTIONS -Dspirv-to-dxil=false)
endif()

if("zlib" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dzlib=enabled)
else()
    list(APPEND MESA_OPTIONS -Dzlib=disabled)
endif()

if("zstd" IN_LIST FEATURES)
    list(APPEND MESA_OPTIONS -Dzstd=enabled)
else()
    list(APPEND MESA_OPTIONS -Dzstd=disabled)
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND MESA_OPTIONS -Dplatforms=['windows'])
    list(APPEND MESA_OPTIONS -Dmicrosoft-clc=disabled)
    if(NOT VCPKG_TARGET_IS_MINGW)
        set(VCPKG_CXX_FLAGS "/D_CRT_DECLARE_NONSTDC_NAMES ${VCPKG_CXX_FLAGS}")
        set(VCPKG_C_FLAGS "/D_CRT_DECLARE_NONSTDC_NAMES ${VCPKG_C_FLAGS}")
    endif()
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS 
        ${MESA_OPTIONS}
        -Dgles-lib-suffix=_mesa
        -Dbuild-tests=false
    ADDITIONAL_BINARIES
        python=['${PYTHON3}','-E','-s']
        python3=['${PYTHON3}','-E','-s']
)

vcpkg_install_meson()

vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    # installed by egl-registry
    "${CURRENT_PACKAGES_DIR}/include/KHR"
    "${CURRENT_PACKAGES_DIR}/include/EGL"
    # installed by opengl-registry
    "${CURRENT_PACKAGES_DIR}/include/GL"
    "${CURRENT_PACKAGES_DIR}/include/GLES"
    "${CURRENT_PACKAGES_DIR}/include/GLES2"
    "${CURRENT_PACKAGES_DIR}/include/GLES3"
)
file(GLOB remaining "${CURRENT_PACKAGES_DIR}/include/*")
if(NOT remaining)
    # all the headers to be provided by `egl-registry` and/or `opengl-registry` ports
    set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include")
endif()

if("opengl" IN_LIST FEATURES AND VCPKG_TARGET_IS_WINDOWS)
    # `opengl32.lib` is already installed by `opengl` port,
    # and Mesa claims to provide a drop-in replacement of `opengl32.dll`
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/lib/manual-link")
    file(RENAME
        "${CURRENT_PACKAGES_DIR}/lib/opengl32.lib"
        "${CURRENT_PACKAGES_DIR}/lib/manual-link/opengl32.lib"
    )
    if(NOT VCPKG_BUILD_TYPE)
        file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/debug/lib/manual-link")
        file(RENAME
            "${CURRENT_PACKAGES_DIR}/debug/lib/opengl32.lib"
            "${CURRENT_PACKAGES_DIR}/debug/lib/manual-link/opengl32.lib"
        )
    endif()
endif()

if(FEATURES STREQUAL "core")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
endif()

if("spirv-to-dxil" IN_LIST FEATURES)
    file(
        INSTALL
            "${SOURCE_PATH}/src/microsoft/compiler/dxil_versions.h"
            "${SOURCE_PATH}/src/microsoft/spirv_to_dxil/spirv_to_dxil.h"
        DESTINATION
            "${CURRENT_PACKAGES_DIR}/include/${PORT}/spirv-to-dxil"
    )

    set(SpirvToDxil_PACKAGE_NAME "SpirvToDxil")
    file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${SpirvToDxil_PACKAGE_NAME}"
    )
    file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindSpirvToDxil.cmake"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${SpirvToDxil_PACKAGE_NAME}"
    )

    if("tools" IN_LIST FEATURES)
        vcpkg_copy_tools(TOOL_NAMES spirv2dxil AUTO_CLEAN)
    else()
        # should also patch-in an option for not building it in the first place,
        # but it's Meson, so probably better not patch it too often
        file(REMOVE_RECURSE
            "${CURRENT_PACKAGES_DIR}/bin"
            "${CURRENT_PACKAGES_DIR}/debug/bin"
        )
    endif()
endif()

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/docs/license.rst")
