set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

if(VCPKG_CROSSCOMPILING)
    # should be FATAL_ERROR
    message(WARNING "${PORT} is a host-only port, mark it as a host dependency in your ports")
endif()

# functions
file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_ololo.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_messages.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_helpers.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
# common files
file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/common/Installing.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/common/Config.cmake.in"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}/common"
)

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/license.txt")
