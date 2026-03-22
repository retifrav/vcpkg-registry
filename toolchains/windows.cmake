# without loading vcpkg's toolchain first, the CMAKE_CXX_FLAGS_RELEASE and CMAKE_C_FLAGS_RELEASE
# won't get populated, and to load the vcpkg's toolchain we need to know path to vcpkg registry
include(${CMAKE_CURRENT_LIST_DIR}/_set-vcpkg-registry-path.cmake)
set_vcpkg_registry_path() # should set `VCPKG_TOOL_PARENT_PATH`
include("${VCPKG_TOOL_PARENT_PATH}/scripts/toolchains/windows.cmake")
unset(VCPKG_TOOL_PARENT_PATH) # just in case

string(REPLACE "/Z7" ""
    CMAKE_C_FLAGS_RELEASE_WITHOUT_Z7
    "${CMAKE_C_FLAGS_RELEASE}"
)
set(CMAKE_C_FLAGS_RELEASE
    "${CMAKE_C_FLAGS_RELEASE_WITHOUT_Z7}"
    CACHE STRING ""
    # it's important to apply FORCE here, as this variable is CACHE and it has been already
    # set in the previous toolchain above
    FORCE
)

string(REPLACE "/Z7" ""
    CMAKE_CXX_FLAGS_RELEASE_WITHOUT_Z7
    "${CMAKE_CXX_FLAGS_RELEASE}"
)
set(CMAKE_CXX_FLAGS_RELEASE
    "${CMAKE_CXX_FLAGS_RELEASE_WITHOUT_Z7}"
    CACHE STRING ""
    # it's important to apply FORCE here, as this variable is CACHE and it has been already
    # set in the previous toolchain above
    FORCE
)
