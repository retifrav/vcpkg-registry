# seems redundant and weird to include the same toolchain that has been just used upper in the chain,
# but without it CMAKE_CXX_FLAGS_RELEASE and CMAKE_C_FLAGS_RELEASE won't get populated
# (unless there is a better way to get their values, since being cache variables
# they must have been set somewhere?)
#
# for $ENV{VCPKG_ROOT} to work the triplet should contain `set(VCPKG_ENV_PASSTHROUGH_UNTRACKED VCPKG_ROOT)`
include("$ENV{VCPKG_ROOT}/scripts/toolchains/windows.cmake")

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
