#[=======================================================================[.rst:
FindOculusSDK
--------

Finds Oculus SDK.

Imported Targets
^^^^^^^^^^^^^^^^

If Oculus SDK is found, the following imported target will be provided:

``OculusSDK::OVR``
  The Oculus SDK library

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``OculusSDK_FOUND``
  True if the system has the Oculus SDK library.
``OculusSDK_INCLUDE_DIRS``
  Include directories needed to use Oculus SDK.
``OculusSDK_LIBRARIES``
  Libraries needed to link to Oculus SDK.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables will also be set:

``OculusSDK_INCLUDE_DIR``
  The directory containing Oculus SDK public headers.
``OculusSDK_LIBRARY``
  The path to the Oculus SDK library.

#]=======================================================================]

set(PATH_TO_OculusSDK "${CMAKE_PREFIX_PATH}")
if(DEFINED VCPKG_INSTALLED_DIR)
    set(PATH_TO_OculusSDK "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
elseif(DEFINED OculusSDK_DIR)
    set(PATH_TO_OculusSDK "${OculusSDK_DIR}")
elseif(DEFINED OculusSDK_ROOT)
    set(PATH_TO_OculusSDK "${OculusSDK_ROOT}")
endif()

find_path(OculusSDK_INCLUDE_DIR
    OVR_CAPI.h
    "${PATH_TO_OculusSDK}"
    PATH_SUFFIXES "include/ovr"
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(OculusSDK_LIBRARY
    NAMES LibOVR
    PATHS "${PATH_TO_OculusSDK}"
    PATH_SUFFIXES "lib"
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OculusSDK
    FOUND_VAR OculusSDK_FOUND
    REQUIRED_VARS
        OculusSDK_INCLUDE_DIR
        OculusSDK_LIBRARY
)

if(OculusSDK_FOUND)
    set(OculusSDK_LIBRARIES ${OculusSDK_LIBRARY})
    cmake_path(GET OculusSDK_INCLUDE_DIR PARENT_PATH OculusSDK_INCLUDE_DIRS) # set(OculusSDK_INCLUDE_DIRS ${OculusSDK_INCLUDE_DIR}/..)

    if(NOT TARGET OculusSDK::OVR)
        add_library(OculusSDK::OVR STATIC IMPORTED)
        set_target_properties(OculusSDK::OVR PROPERTIES
            IMPORTED_LOCATION "${OculusSDK_LIBRARY}"
            #IMPORTED_IMPLIB "${OculusSDK_LIBRARY}" # should not be needed, as this is a STATIC library
            INTERFACE_INCLUDE_DIRECTORIES "${OculusSDK_INCLUDE_DIRS}"
        )
        # or?
        # # Release configuration properties
        # set_property(TARGET OculusSDK::OVR
        #     APPEND PROPERTY
        #         IMPORTED_CONFIGURATIONS RELEASE
        # )
        # set_target_properties(OculusSDK::OVR PROPERTIES
        #     IMPORTED_LOCATION_RELEASE "${OculusSDK_LIBRARY}"
        #     #IMPORTED_IMPLIB_RELEASE "${OculusSDK_LIBRARY}" # should not be needed, as this is a STATIC library
        # )
        # # Debug configuration properties
        # set_property(TARGET OculusSDK::OVR
        #     APPEND PROPERTY
        #         IMPORTED_CONFIGURATIONS DEBUG
        # )
        # set_target_properties(OculusSDK::OVR PROPERTIES
        #     IMPORTED_LOCATION_DEBUG "${OculusSDK_LIBRARY}"
        #     #IMPORTED_IMPLIB_DEBUG "${OculusSDK_LIBRARY}" # should not be needed, as this is a STATIC library
        # )
        # # common properties
        # set_target_properties(OculusSDK::OVR PROPERTIES
        #     INTERFACE_INCLUDE_DIRECTORIES "${OculusSDK_INCLUDE_DIRS}"
        # )
        # # configuration mappings
        # set_target_properties(OculusSDK::OVR
        #     PROPERTIES
        #         MAP_IMPORTED_CONFIG_MINSIZEREL Release
        #         MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
        # )
    endif()
endif()

mark_as_advanced(
  OculusSDK_INCLUDE_DIR
  OculusSDK_LIBRARY
)
