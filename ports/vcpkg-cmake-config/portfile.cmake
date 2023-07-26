if(VCPKG_CROSSCOMPILING)
    # should be FATAL_ERROR
    message(WARNING "${PORT} is a host-only port, mark it as a host dependency in your ports")
endif()

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg_cmake_config_fixup.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(INSTALL
    "${VCPKG_ROOT_DIR}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)

set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
