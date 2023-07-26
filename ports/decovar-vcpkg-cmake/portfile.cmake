if(VCPKG_CROSSCOMPILING)
    # make FATAL_ERROR in CI when issue #16773 fixed
    message(WARNING "decovar-vcpkg-cmake is a host-only port, mark it as a host port in your ports dependencies")
endif()

# functions
file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_ololo.cmake"
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

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/license.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)

set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
