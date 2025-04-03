# doesn't do anything, if you are not using find_package(), which you cannot use
# when all the CMake helpers have the same file name (vcpkg-port-config.cmake)
#set(DECOVAR_VCPKG_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

include("${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_ololo.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_helpers.cmake")
