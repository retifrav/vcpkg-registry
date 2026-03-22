macro(set_vcpkg_registry_path)
    if(NOT DEFINED ENV{VCPKG_COMMAND})
        message(
            FATAL_ERROR
                "For some reason, VCPKG_COMMAND environment variable is not defined, "
                "which should not be possible. This environment variable should have been "
                "set by vcpkg itself, you should not set it on your own. Perhaps, there is "
                "something wrong with your vcpkg installation? Less likely, but it could "
                "also be that something has changed in newer versions of vcpkg (either "
                "the tool or the registry scripts), so check their release notes just in case."
        )
    endif()

    # read the environment variable into a "normal" variable, otherwise `cmake_path()` won't be able to work with it
    set(VCPKG_COMMAND "$ENV{VCPKG_COMMAND}")
    message(DEBUG "VCPKG_COMMAND: ${VCPKG_COMMAND}")
    
    cmake_path(HAS_PARENT_PATH
        VCPKG_COMMAND
        VCPKG_COMMAND_HAS_PARENT_PATH
    )
    if(NOT VCPKG_COMMAND_HAS_PARENT_PATH)
        message(
            FATAL_ERROR
                "Somehow, the path to vcpkg tool has no parent folder, which should be path "
                "to vcpkg registry. Maybe there is something wrong with the VCPKG_COMMAND "
                "environment variable (but don't set it yourself, as it should be "
                "set by the vcpkg tool)."
        )
    endif()
    unset(VCPKG_COMMAND_HAS_PARENT_PATH) # just in case
    
    cmake_path(GET
        VCPKG_COMMAND
        PARENT_PATH
        VCPKG_TOOL_PARENT_PATH
    )
    unset(VCPKG_COMMAND) # just in case
    message(DEBUG "VCPKG_TOOL_PARENT_PATH: ${VCPKG_TOOL_PARENT_PATH}")
endmacro()
