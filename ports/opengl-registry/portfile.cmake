vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:KhronosGroup/OpenGL-Registry.git
    REF ca491a0576d5c026f06ebe29bfac7cbbcf1e8332
)

file(
    COPY
        "${SOURCE_PATH}/api/GL"
        "${SOURCE_PATH}/api/GLES"
        "${SOURCE_PATH}/api/GLES2"
        "${SOURCE_PATH}/api/GLES3"
        "${SOURCE_PATH}/api/GLSC"
        "${SOURCE_PATH}/api/GLSC2"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include"
)

file(GLOB reg_files
    "${SOURCE_PATH}/xml/*.xml"
    "${SOURCE_PATH}/xml/*.rnc"
    "${SOURCE_PATH}/xml/reg.py"
)
file(
    COPY ${reg_files}
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/opengl"
)

vcpkg_install_copyright(
    FILE_LIST
        "${CMAKE_CURRENT_LIST_DIR}/LICENSE"
)
