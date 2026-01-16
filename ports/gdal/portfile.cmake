vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:OSGeo/gdal.git
    REF 20be66345f7dd2d8e368684abb22b0f6355e8cf0
    PATCHES
        001-dependencies-and-installation.patch
)

# do not vendor 3rd-party dependencies
file(REMOVE_RECURSE
    "${SOURCE_PATH}/frmts/gtiff/libgeotiff"
    "${SOURCE_PATH}/frmts/gtiff/libtiff"
    "${SOURCE_PATH}/frmts/jpeg/libjpeg"
    "${SOURCE_PATH}/frmts/png/libpng"
    "${SOURCE_PATH}/frmts/zlib"
    "${SOURCE_PATH}/ogr/ogrsf_frmts/geojson/libjson"
)
file(REMOVE
    "${SOURCE_PATH}/cmake/modules/packages/FindCURL.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindDeflate.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindGeoTIFF.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindPROJ.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindSQLite3.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindWebP.cmake"
    "${SOURCE_PATH}/cmake/modules/packages/FindZSTD.cmake"
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" GDAL_STATIC)
#string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" GDAL_SHARED)

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
        -DENABLE_DEFLATE64=0
        -DENABLE_GNM=0
        -DENABLE_PAM=0
        -DGDAL_BUILD_OPTIONAL_DRIVERS=0
        -DGDAL_ENABLE_DRIVER_JPEG=1
        -DGDAL_ENABLE_DRIVER_PNG=1
        -DGDAL_ENABLE_DRIVER_VRT=1
        -DGDAL_ENABLE_PLUGINS=0
        -DGDAL_ENABLE_PLUGINS_NO_DEPS=0
        -DGDAL_USE_ARCHIVE=0
        -DGDAL_USE_ARMADILLO=0
        -DGDAL_USE_ARROW=0
        -DGDAL_USE_BASISU=0
        -DGDAL_USE_BLOSC=0
        -DGDAL_USE_BRUNSLI=0
        -DGDAL_USE_CFITSIO=0
        -DGDAL_USE_CRNLIB=0
        -DGDAL_USE_CRYPTOPP=0
        -DGDAL_USE_CURL=0
        -DGDAL_USE_DEFLATE=0
        -DGDAL_USE_ECW=0
        -DGDAL_USE_EXPAT=0
        -DGDAL_USE_EXTERNAL_LIBS=1
        -DGDAL_USE_FILEGDB=0
        -DGDAL_USE_FREEXL=0
        -DGDAL_USE_FYBA=0
        -DGDAL_USE_GEOS=0
        -DGDAL_USE_GEOTIFF=1
        -DGDAL_USE_GEOTIFF_INTERNAL=0
        -DGDAL_USE_GIF=0
        -DGDAL_USE_GIF_INTERNAL=0
        -DGDAL_USE_GTA=0
        -DGDAL_USE_HDF4=0
        -DGDAL_USE_HDF5=0
        -DGDAL_USE_HDFS=0
        -DGDAL_USE_HEIF=0
        -DGDAL_USE_ICONV=0
        -DGDAL_USE_IDB=0
        -DGDAL_USE_INTERNAL_LIBS="OFF" # has to be a string value, as they validate it against a list of "allowed values"
        -DGDAL_USE_JPEG12_INTERNAL=0
        -DGDAL_USE_JPEG=1
        -DGDAL_USE_JPEG_INTERNAL=0
        -DGDAL_USE_JSONC=1
        -DGDAL_USE_JSONC_INTERNAL=0
        -DGDAL_USE_JXL=0
        -DGDAL_USE_KDU=0
        -DGDAL_USE_KEA=0
        -DGDAL_USE_LERC=0
        -DGDAL_USE_LERC_INTERNAL=0
        -DGDAL_USE_LIBAEC=0
        -DGDAL_USE_LIBKML=0
        -DGDAL_USE_LIBLZMA=0
        -DGDAL_USE_LIBQB3=0
        -DGDAL_USE_LIBXML2=0
        -DGDAL_USE_LZ4=0
        -DGDAL_USE_MONGOCXX=0
        -DGDAL_USE_MRSID=0
        -DGDAL_USE_MSSQL_NCLI=0
        -DGDAL_USE_MSSQL_ODBC=0
        -DGDAL_USE_MYSQL=0
        -DGDAL_USE_NETCDF=0
        -DGDAL_USE_ODBC=0
        -DGDAL_USE_ODBCCPP=0
        -DGDAL_USE_OPENCAD=0
        -DGDAL_USE_OPENCAD_INTERNAL=0
        -DGDAL_USE_OPENDRIVE=0
        -DGDAL_USE_OPENEXR=0
        -DGDAL_USE_OPENJPEG=0
        -DGDAL_USE_OPENSSL=0
        -DGDAL_USE_ORACLE=0
        -DGDAL_USE_PARQUET=0
        -DGDAL_USE_PCRE2=0
        -DGDAL_USE_PDFIUM=0
        -DGDAL_USE_PNG=1
        -DGDAL_USE_PNG_INTERNAL=0
        -DGDAL_USE_POPPLER=0
        -DGDAL_USE_POSTGRESQL=0
        -DGDAL_USE_PUBLICDECOMPWT=0
        -DGDAL_USE_QHULL=0
        -DGDAL_USE_QHULL_INTERNAL=0
        -DGDAL_USE_RASTERLITE2=0
        -DGDAL_USE_SFCGAL=0
        -DGDAL_USE_SHAPELIB=0
        -DGDAL_USE_SHAPELIB_INTERNAL=0
        -DGDAL_USE_SPATIALITE=0
        -DGDAL_USE_SQLITE3=0
        -DGDAL_USE_TEIGHA=0
        -DGDAL_USE_TIFF=1
        -DGDAL_USE_TIFF_INTERNAL=0
        -DGDAL_USE_TILEDB=0
        -DGDAL_USE_WEBP=0
        -DGDAL_USE_XERCESC=0
        -DGDAL_USE_ZLIB=1
        -DGDAL_USE_ZLIB_INTERNAL=0
        -DZLIB_IS_STATIC=${GDAL_STATIC}
        -DGDAL_USE_ZSTD=0
        -DOGR_BUILD_OPTIONAL_DRIVERS=0
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    CONFIG_PATH "lib/cmake/${PORT}"
)

# they put GDAL location as an absolute path on the build host
vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/include/${PORT}/cpl_config.h"
        "#define GDAL_PREFIX \"${CURRENT_PACKAGES_DIR}\""
        "// removed, for an abomination it was (an absolute path)"
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.TXT")
