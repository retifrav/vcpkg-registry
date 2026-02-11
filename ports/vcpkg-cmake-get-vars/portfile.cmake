if(VCPKG_CROSSCOMPILING)
    # should be FATAL_ERROR
    # https://github.com/microsoft/vcpkg/issues/16773
    message(WARNING "The [${PORT}] port is a host-only port, mark it as a host dependency in your ports")
endif()

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/cmake_get_vars" # folder
        "${CMAKE_CURRENT_LIST_DIR}/cmake-get-vars.cmake.in"
        "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/vcpkg_cmake_get_vars.cmake"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${VCPKG_ROOT_DIR}/LICENSE.txt")

set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
