if(VCPKG_CROSSCOMPILING)
    # make FATAL_ERROR in CI when issue #16773 fixed
    message(WARNING "decovar-vcpkg-cmake is a host-only port; mark it as a host port in your dependencies")
endif()

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/Installing.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
        "${CMAKE_CURRENT_LIST_DIR}/decovar_vcpkg_cmake_ololo.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(
    INSTALL
        "${CMAKE_CURRENT_LIST_DIR}/license.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)

# what is that
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
