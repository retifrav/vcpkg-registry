include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# install the target and create export-set
install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} # bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME} # include/SomeLibrary
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} # include
)
# generate and install export file
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    DESTINATION share/${PROJECT_NAME}
)
# create config file
configure_package_config_file(
    #${DECOVAR_VCPKG_CMAKE_DIR}/Config.cmake.in
    ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/share/decovar-vcpkg-cmake/Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    INSTALL_DESTINATION share/${PROJECT_NAME}
)
# install config files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    DESTINATION share/${PROJECT_NAME}
)
# generate the export targets for the build tree
export(EXPORT ${PROJECT_NAME}Targets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/cmake/${PROJECT_NAME}Targets.cmake
)
