vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/EGL-Registry.git
    REF 7db3005d4c2cb439f129a0adc931f3274f9019e6
)

file(
    COPY
        "${SOURCE_PATH}/api/KHR"
        "${SOURCE_PATH}/api/EGL"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include"
)

file(
    COPY "${SOURCE_PATH}/api/egl.xml"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/opengl"
)

vcpkg_install_copyright(
    FILE_LIST
        "${SOURCE_PATH}/sdk/docs/man/copyright.xml"
)
