# for $ENV{VCPKG_ROOT} to work the triplet should contain `set(VCPKG_ENV_PASSTHROUGH_UNTRACKED VCPKG_ROOT)`
include("$ENV{VCPKG_ROOT}/scripts/toolchains/windows.cmake")

# remove /Z7 from the default set of C flags
string(REPLACE "/Z7" ""
    CMAKE_C_FLAGS_RELEASE_WITHOUT_Z7
    "${CMAKE_C_FLAGS_RELEASE}"
)
# override Release flags variable with the new value
set(CMAKE_C_FLAGS_RELEASE
    "${CMAKE_C_FLAGS_RELEASE_WITHOUT_Z7}"
    CACHE STRING ""
    # it's important to apply FORCE here, as this variable is CACHE
    # and it has been already set in the default toolchain above
    FORCE
)

# and the same for CXX flags
string(REPLACE "/Z7" ""
    CMAKE_CXX_FLAGS_RELEASE_WITHOUT_Z7
    "${CMAKE_CXX_FLAGS_RELEASE}"
)
set(CMAKE_CXX_FLAGS_RELEASE
    "${CMAKE_CXX_FLAGS_RELEASE_WITHOUT_Z7}"
    CACHE STRING ""
    FORCE
)
