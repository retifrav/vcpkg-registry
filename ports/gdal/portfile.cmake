vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:OSGeo/gdal.git
    REF 9b7a7c8ffa7b7aff696974c432d4254a809b3efe
    PATCHES
        001-dependencies-and-installation.patch
)

# vcpkg_find_acquire_program(PYTHON3)
# # if we want this Python to be available in the PATH
# # get_filename_component(PYTHON_DIR ${PYTHON3} DIRECTORY)
# # vcpkg_add_to_path("${PYTHON_DIR}") # you might want to PREPEND it
# #
# x_vcpkg_get_python_packages(
#     PYTHON_VERSION "3"
#     PYTHON_EXECUTABLE ${PYTHON3}
#     PACKAGES numpy
#     OUT_PYTHON_VAR "PYTHON_VENV"
# )
# # in case of venv we want that one to be available in the PATH
# get_filename_component(PYTHON_VENV_DIR ${PYTHON_VENV} DIRECTORY)
# vcpkg_add_to_path("${PYTHON_VENV_DIR}") # you might want to PREPEND it
# #message(STATUS "PYTHON_VENV: ${PYTHON_VENV}")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_APPS=0
        -DBUILD_DOCS=0
        -DBUILD_PYTHON_BINDINGS=0
        -DBUILD_TESTING=0
        -DENABLE_GNM=0
        -DENABLE_PAM=0
        -DGDAL_BUILD_OPTIONAL_DRIVERS=0
        -DGDAL_ENABLE_PLUGINS=0
        -DGDAL_ENABLE_PLUGINS_NO_DEPS=0
        -DGDAL_USE_ARCHIVE=0
        -DGDAL_USE_CFITSIO=0
        -DGDAL_USE_CURL=0
        -DGDAL_USE_DEFLATE=0
        -DGDAL_USE_EXPAT=0
        -DGDAL_USE_EXTERNAL_LIBS=1
        -DGDAL_USE_FREEXL=0
        -DGDAL_USE_GEOS=0
        -DGDAL_USE_GEOTIFF=1
        -DGDAL_USE_GEOTIFF_INTERNAL=0
        -DGDAL_USE_GIF=0
        -DGDAL_USE_HDF5=0
        -DGDAL_USE_ICONV=0
        -DGDAL_USE_INTERNAL_LIBS="OFF" # has to be a string value, as they validate it against a list of "allowed values"
        -DGDAL_USE_JPEG=0
        -DGDAL_USE_JSONC=1
        -DGDAL_USE_JSONC_INTERNAL=0
        -DGDAL_USE_JXL=0
        -DGDAL_USE_KEA=0
        -DGDAL_USE_LERC=0
        -DGDAL_USE_LIBKML=0
        -DGDAL_USE_LIBLZMA=0
        -DGDAL_USE_LIBXML2=0
        -DGDAL_USE_LZ4=0
        -DGDAL_USE_MSSQL_NCLI=0
        -DGDAL_USE_MSSQL_ODBC=0
        -DGDAL_USE_MYSQL=0
        -DGDAL_USE_NETCDF=0
        -DGDAL_USE_ODBC=0
        -DGDAL_USE_OPENCL=0
        -DGDAL_USE_OPENEXR=0
        -DGDAL_USE_OPENJPEG=0
        -DGDAL_USE_OPENSSL=0
        -DGDAL_USE_PCRE2=0
        -DGDAL_USE_PNG=0
        -DGDAL_USE_POPPLER=0
        -DGDAL_USE_POSTGRESQL=0
        -DGDAL_USE_QHULL=0
        -DGDAL_USE_SHAPELIB=0
        -DGDAL_USE_SHAPELIB_INTERNAL=0
        -DGDAL_USE_SPATIALITE=0
        -DGDAL_USE_SQLITE3=0
        -DGDAL_USE_TIFF=1
        -DGDAL_USE_TIFF_INTERNAL=0
        -DGDAL_USE_WEBP=0
        -DGDAL_USE_ZLIB=1
        -DGDAL_USE_ZLIB_INTERNAL=0
        -DGDAL_USE_ZSTD=0
        -DOGR_BUILD_OPTIONAL_DRIVERS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    CONFIG_PATH "lib/cmake/${PORT}"
)

# they resolve dependencies in their own way, in which every dependency has a dedicated `Find*` module,
# and the dependencies targets names are mostly different, while `find_dependency()` calls are appended
# to a very long string that gets inserted into the resulting CMake config, and there is no clean way
# to change that behavior, so it is easier to just fix the resulting files
#
# the downside is that these replacements are fragile, and the original strings will likely
# change in the next GDAL versions
#
# GDAL-targets.cmake
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/GDAL-targets.cmake"
        [=[<LINK_ONLY:TIFF::TIFF>]=]
        [=[<LINK_ONLY:TIFF::tiff>]=]
)
# cpl_config.h (here they hardcode GDAL location as an absolute path on the build host)
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/include/${PORT}/cpl_config.h"
        "#define GDAL_PREFIX \"${CURRENT_PACKAGES_DIR}\""
        "// removed, for an abomination it was (an absolute path)"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE.TXT"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
