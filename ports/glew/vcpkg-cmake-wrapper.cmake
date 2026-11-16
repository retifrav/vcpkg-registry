# the only supported way is find_package(glew CONFIG), other spellings of the name would go
# to CMake's own FindGLEW, and so might module mode, as Findglew.cmake resolves to FindGLEW.cmake
# on case-insensitive file systems
list(GET ARGS 0 _glew_package_name)
list(FIND ARGS "CONFIG" _glew_config_index)
list(FIND ARGS "NO_MODULE" _glew_no_module_index)
if(
    NOT _glew_package_name STREQUAL "glew"
    OR
    (_glew_config_index EQUAL -1 AND _glew_no_module_index EQUAL -1)
)
    list(JOIN ARGS " " _glew_find_package_arguments)
    message(FATAL_ERROR
        "find_package(${_glew_find_package_arguments}) is not supported, "
        "use find_package(glew CONFIG REQUIRED) and link to glew::glew"
    )
endif()
unset(_glew_package_name)
unset(_glew_config_index)
unset(_glew_no_module_index)

_find_package(${ARGS})
