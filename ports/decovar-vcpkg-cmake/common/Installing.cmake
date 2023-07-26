include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# install the target and create export-set
install(TARGETS ${PROJECT_NAME}
    EXPORT "${PROJECT_NAME}Targets"
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} # bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} # lib
    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}" # include/SomeLibrary
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} # include
)
# generate and install export file
install(EXPORT "${PROJECT_NAME}Targets"
    FILE "${PROJECT_NAME}Targets.cmake"
    DESTINATION "share/${PROJECT_NAME}"
)

set(PROJECT_HAS_VERSION 0)
if(DEFINED PROJECT_VERSION AND NOT ${PROJECT_VERSION} STREQUAL "")
    set(PROJECT_HAS_VERSION 1)
endif()
if(PROJECT_HAS_VERSION)
    # generate the version file for the config file
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        COMPATIBILITY AnyNewerVersion
    )
endif()

# create config file
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "share/${PROJECT_NAME}"
)
# install config files
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "$<$<BOOL:${PROJECT_HAS_VERSION}>:${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake>"
    DESTINATION "share/${PROJECT_NAME}"
)
