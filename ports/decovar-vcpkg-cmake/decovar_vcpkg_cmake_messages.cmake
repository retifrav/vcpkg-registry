include_guard(GLOBAL)

macro(decovar_vcpkg_cmake_warning_commercial_license)
    message(
        STATUS
            "[WARNING] The [${PORT}] source code is distributed under a 3rd-party commercial license, "
            "check for details in ${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
    )
endmacro()

macro(decovar_vcpkg_cmake_warning_problematic_license LICENSE_NAME)
    message(
        STATUS
            "[WARNING] The [${PORT}] source code is distributed under a potentially problematic license: "
            "${LICENSE_NAME} (${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright). Make sure that using "
            "this port has been approved before committing it as a dependency in your project."
    )
endmacro()

macro(decovar_vcpkg_cmake_info_openmp)
    message(
        STATUS
            "For building [${PORT}] you need to have OpenMP already installed "
            "in the system, and OpenMP_ROOT environment variable should point to its prefix."
    )
    if(VCPKG_TARGET_IS_OSX) # OR VCPKG_TARGET_IS_IOS
        message(
            STATUS
                "On Mac OS it can be installed with Homebrew:\n"
                "```\n"
                "$ brew install libomp\n"
                "$ export OpenMP_ROOT=$(brew --prefix)/opt/libomp\n"
                "```"
        )
    endif()
endmacro()
