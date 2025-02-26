set(VCPKG_POLICY_EMPTY_PACKAGE enabled)

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/x_vcpkg_get_python_packages.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

# not sure if this is needed, nothing fails without it
#include("${CMAKE_CURRENT_LIST_DIR}/x_vcpkg_get_python_packages.cmake")

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/copyright")
