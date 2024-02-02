if(VCPKG_CROSSCOMPILING)
    # should be FATAL_ERROR
    message(WARNING "${PORT} is a host-only port, mark it as a host dependency in your ports")
endif()

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/x_vcpkg_get_python_packages.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

#include("${CMAKE_CURRENT_LIST_DIR}/x_vcpkg_get_python_packages.cmake")

file(INSTALL
    "${VCPKG_ROOT_DIR}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)

set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
