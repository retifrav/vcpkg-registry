set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled) # doesn't seem to need any public headers

vcpkg_download_distfile(
    ARCHIVE
    URLS "https://system.data.sqlite.org/blobs/${VERSION}.0/sqlite-netFx-source-${VERSION}.0.zip"
    FILENAME "sqlite-netFx-source-${VERSION}.0.zip"
    SHA512 b8837395e6b3e2e11e8a26cbad1f00790af4cf8c22375ad0d1a4cb4a694abf18da47738f08beafce4ac86af12df8ab0612cf7a49c73fe8534188b6432642d44d
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    NO_REMOVE_ONE_LEVEL
)

file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in"
    DESTINATION "${SOURCE_PATH}"
)
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")

vcpkg_cmake_install()

set(INSTALLED_CMAKE_PACKAGE_NAME "SQLite.Interop")
vcpkg_cmake_config_fixup(
    PACKAGE_NAME "${INSTALLED_CMAKE_PACKAGE_NAME}"
    CONFIG_PATH "share/${INSTALLED_CMAKE_PACKAGE_NAME}"
)

# you might want to build System.Data.SQLite too, even though it might work fine with the one installed with NuGet,
# otherwise you can get a stack overflow crash at some point
if(NOT "interop-only" IN_LIST FEATURES)
    find_program(DOTNET dotnet REQUIRED)
    set(DOTNET_RUNTIME "NetStandard21") # should be 2.1 and lower-cased, to conform with the .NET schema
    #string(TOLOWER ${DOTNET_RUNTIME} DOTNET_RUNTIME_LOWER)
    set(DOTNET_RUNTIME_LOWER "netstandard2.1")
    #
    vcpkg_execute_required_process(
        COMMAND ${DOTNET} build -c Debug ./System.Data.SQLite/System.Data.SQLite.${DOTNET_RUNTIME}.csproj
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME dotnet-${PORT}-building-dbg
    )
    file(
        INSTALL "${SOURCE_PATH}/bin/${DOTNET_RUNTIME}/Debug${DOTNET_RUNTIME}/bin/${DOTNET_RUNTIME_LOWER}/System.Data.SQLite.dll"
        DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
    #
    vcpkg_execute_required_process(
        COMMAND ${DOTNET} build -c Release ./System.Data.SQLite/System.Data.SQLite.${DOTNET_RUNTIME}.csproj
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME dotnet-${PORT}-building-rel
    )
    file(
        INSTALL "${SOURCE_PATH}/bin/${DOTNET_RUNTIME}/Release${DOTNET_RUNTIME}/bin/${DOTNET_RUNTIME_LOWER}/System.Data.SQLite.dll"
        DESTINATION "${CURRENT_PACKAGES_DIR}/bin"
    )
else()
    message(STATUS "The interop-only feature is enabled, not building the System.Data.SQLite")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/license.md")
