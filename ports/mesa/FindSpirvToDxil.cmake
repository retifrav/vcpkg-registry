# ---
# find_package(SpirvToDxil REQUIRED) # no CONFIG here, obviously
# target_include_directories(${PROJECT_NAME}
#     PRIVATE
#         ${SpirvToDxil_INCLUDE_DIR}
# )
# target_link_libraries(${PROJECT_NAME}
#     PRIVATE
#         MESA::SpirvToDxil
# )
# ---

set(PATH_TO_SPIRV_TO_DXIL "${CMAKE_PREFIX_PATH}")
if(DEFINED VCPKG_INSTALLED_DIR)
    set(PATH_TO_SpirvToDxil "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
elseif(DEFINED SpirvToDxil_DIR)
    set(PATH_TO_SpirvToDxil "${SpirvToDxil_DIR}")
elseif(DEFINED SpirvToDxil_ROOT)
    set(PATH_TO_SpirvToDxil "${SpirvToDxil_ROOT}")
endif()

find_path(SpirvToDxil_INCLUDE_DIR
    spirv_to_dxil.h
    "${PATH_TO_SpirvToDxil}"
    PATH_SUFFIXES "include/mesa/spirv-to-dxil"
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(SpirvToDxil_LIBRARY_RELEASE
    NAMES spirv_to_dxil
    PATHS "${PATH_TO_SpirvToDxil}"
    PATH_SUFFIXES "lib"
    NO_CMAKE_FIND_ROOT_PATH
)
find_library(SpirvToDxil_LIBRARY_DEBUG
    NAMES spirv_to_dxil
    PATHS "${PATH_TO_SpirvToDxil}"
    PATH_SUFFIXES "debug/lib"
    NO_DEFAULT_PATH # important, otherwise it will find the Release one again
    NO_CMAKE_FIND_ROOT_PATH
)

# find_file(SpirvToDxil_LIBRARY_DLL_RELEASE
#     NAMES spirv_to_dxil.dll
#     PATHS "${PATH_TO_SpirvToDxil}"
#     PATH_SUFFIXES "bin"
#     NO_CMAKE_FIND_ROOT_PATH
# )
# find_file(SpirvToDxil_LIBRARY_DLL_DEBUG
#     NAMES spirv_to_dxil.dll
#     PATHS "${PATH_TO_SpirvToDxil}"
#     PATH_SUFFIXES "debug/bin"
#     NO_CMAKE_FIND_ROOT_PATH
# )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SpirvToDxil
    FOUND_VAR SpirvToDxil_FOUND
    REQUIRED_VARS
        SpirvToDxil_INCLUDE_DIR
        SpirvToDxil_LIBRARY_RELEASE
        SpirvToDxil_LIBRARY_DEBUG
        #SpirvToDxil_LIBRARY_DLL_RELEASE
        #SpirvToDxil_LIBRARY_DLL_DEBUG
)

if(SpirvToDxil_FOUND)
    # is this actually needed for anything?
    # set(SpirvToDxil_LIBRARIES
    #     ${SpirvToDxil_LIBRARY_RELEASE}
    #     ${SpirvToDxil_LIBRARY_DEBUG}
    #     #${SpirvToDxil_LIBRARY_DLL_DEBUG}
    #     #${SpirvToDxil_LIBRARY_DLL_RELEASE}
    # )

    cmake_path(GET SpirvToDxil_INCLUDE_DIR PARENT_PATH SpirvToDxil_INCLUDE_DIRS) # set(SpirvToDxil_INCLUDE_DIRS ${SpirvToDxil_INCLUDE_DIR}/..)

    if(NOT TARGET MESA::SpirvToDxil)
        add_library(MESA::SpirvToDxil STATIC IMPORTED) # SHARED
        # Release configuration properties
        set_property(TARGET MESA::SpirvToDxil
            APPEND PROPERTY
                IMPORTED_CONFIGURATIONS RELEASE
        )
        set_target_properties(MESA::SpirvToDxil
            PROPERTIES
                # STATIC
                IMPORTED_LOCATION_RELEASE "${SpirvToDxil_LIBRARY_RELEASE}"
                # SHARED
                #IMPORTED_LOCATION_RELEASE "${SpirvToDxil_LIBRARY_DLL_RELEASE}"
                #IMPORTED_IMPLIB_RELEASE "${SpirvToDxil_LIBRARY_RELEASE}"
        )
        # Debug configuration properties
        set_property(TARGET MESA::SpirvToDxil
            APPEND PROPERTY
                IMPORTED_CONFIGURATIONS DEBUG
        )
        set_target_properties(MESA::SpirvToDxil
            PROPERTIES
                # STATIC
                IMPORTED_LOCATION_DEBUG "${SpirvToDxil_LIBRARY_DEBUG}"
                # SHARED
                #IMPORTED_LOCATION_DEBUG "${SpirvToDxil_LIBRARY_DLL_DEBUG}"
                #IMPORTED_IMPLIB_DEBUG "${SpirvToDxil_LIBRARY_DEBUG}"
        )
        # common properties
        set_target_properties(MESA::SpirvToDxil
            PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${SpirvToDxil_INCLUDE_DIRS}"
        )
    endif()
endif()

mark_as_advanced(
    SpirvToDxil_INCLUDE_DIR
    SpirvToDxil_LIBRARY_RELEASE
    SpirvToDxil_LIBRARY_DEBUG
    #SpirvToDxil_LIBRARY_DLL_RELEASE
    #SpirvToDxil_LIBRARY_DLL_DEBUG
)
