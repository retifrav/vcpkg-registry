#[=======================================================================[.rst:
FindBoost
--------

Finds Boost.

Imported Targets
^^^^^^^^^^^^^^^^

If Boost is found, the following imported target will be provided:

``Boost::?``
  The are a lot of Boost libraries, need to have a target for every one of them?

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``Boost_FOUND``
  True if the system has the Boost library.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables will also be set:

``Boost_INCLUDE_DIR``
  The directory containing Boost public headers.
``Boost_LIBRARIES_DEBUG``
  The directory containing Debug Boost libraries.
``Boost_LIBRARIES_Release``
  The directory containing Release Boost libraries.

#]=======================================================================]

set(PATH_TO_Boost "${CMAKE_PREFIX_PATH}")
if(DEFINED VCPKG_INSTALLED_DIR)
    set(PATH_TO_Boost "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
elseif(DEFINED Boost_DIR)
    set(PATH_TO_Boost "${Boost_DIR}")
elseif(DEFINED Boost_ROOT)
    set(PATH_TO_Boost "${Boost_ROOT}")
endif()

find_path(Boost_INCLUDE_DIR
    version.hpp
    "${PATH_TO_Boost}"
    PATH_SUFFIXES "include/boost"
    NO_CMAKE_FIND_ROOT_PATH
)

# but we need to find all the libraries?
find_library(Boost_atomic_LIBRARY_DEBUG
    NAMES
        "libboost_atomic-vc143-mt-gd-x64-1_87" # STATIC
        "libboost_atomic-vc143-mt-sgd-x64-1_87" # STATIC
        "boost_atomic-vc143-mt-gd-x64-1_87" # SHARED
    PATHS "${PATH_TO_Boost}"
    PATH_SUFFIXES "debug/lib"
    NO_CMAKE_FIND_ROOT_PATH
)
find_library(Boost_atomic_LIBRARY_RELEASE
    NAMES
        "libboost_atomic-vc143-mt-x64-1_87" # STATIC
        "libboost_atomic-vc143-mt-s-x64-1_87" # STATIC
        "boost_atomic-vc143-mt-x64-1_87" # SHARED
    PATHS "${PATH_TO_Boost}"
    PATH_SUFFIXES "lib"
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Boost
    FOUND_VAR Boost_FOUND
    REQUIRED_VARS
        Boost_INCLUDE_DIR
        Boost_atomic_LIBRARY_DEBUG
        Boost_atomic_LIBRARY_RELEASE
)

if(Boost_FOUND)
    #cmake_path(GET Boost_INCLUDE_DIR PARENT_PATH Boost_INCLUDE_DIRS) # set(Boost_INCLUDE_DIRS ${Boost_INCLUDE_DIR}/..)
    cmake_path(GET Boost_atomic_LIBRARY_DEBUG PARENT_PATH Boost_LIBRARIES_DEBUG)
    cmake_path(GET Boost_atomic_LIBRARY_RELEASE PARENT_PATH Boost_LIBRARIES_RELEASE)

    # if(NOT TARGET Boost::atomic)
    #     add_library(Boost::atomic STATIC IMPORTED)
    #     set_target_properties(Boost::atomic PROPERTIES
    #         IMPORTED_LOCATION "${Boost_atomic_LIBRARY}"
    #         #IMPORTED_IMPLIB "${Boost_atomic_LIBRARY}" # should not be needed, as this is a STATIC library
    #         INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
    #     )
    #     # or?
    #     # # Release configuration properties
    #     # set_property(TARGET Boost::atomic
    #     #     APPEND PROPERTY
    #     #         IMPORTED_CONFIGURATIONS RELEASE
    #     # )
    #     # set_target_properties(Boost::atomic PROPERTIES
    #     #     IMPORTED_LOCATION_RELEASE "${Boost_?_LIBRARY}"
    #     #     #IMPORTED_IMPLIB_RELEASE "${Boost_?_LIBRARY}" # should not be needed, as this is a STATIC library
    #     # )
    #     # # Debug configuration properties
    #     # set_property(TARGET Boost::atomic
    #     #     APPEND PROPERTY
    #     #         IMPORTED_CONFIGURATIONS DEBUG
    #     # )
    #     # set_target_properties(Boost::atomic PROPERTIES
    #     #     IMPORTED_LOCATION_DEBUG "${Boost_?_LIBRARY}"
    #     #     #IMPORTED_IMPLIB_DEBUG "${Boost_?_LIBRARY}" # should not be needed, as this is a STATIC library
    #     # )
    #     # # common properties
    #     # set_target_properties(Boost::atomic PROPERTIES
    #     #     INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}"
    #     # )
    #     # # configuration mappings
    #     # set_target_properties(Boost::atomic
    #     #     PROPERTIES
    #     #         MAP_IMPORTED_CONFIG_MINSIZEREL Release
    #     #         MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
    #     # )
    # endif()
endif()

mark_as_advanced(
    Boost_INCLUDE_DIR
    Boost_atomic_LIBRARY_DEBUG
    Boost_atomic_LIBRARY_RELEASE
)
