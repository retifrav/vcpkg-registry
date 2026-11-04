# Maintainer notes

## Vendored dependencies

The way they resolve dependencies is absolutely horrible: fucking self-made functions (*several variants of those*) for finding packages, separation into internal/external discovery (*which does not seem to respect what you tell it to use*), appending `find_dependency()` calls to a bitch-ass long string... Shortly saying, a god-awful abomination.

No one has time to get through all this wretched convolution of not-invented-here crutches in one go, so patching the original CMake project will be progressing gradually.

## OpenMP is disabled

The port configures GDAL with `-DGDAL_USE_OPENMP=0`. By default GDAL looks for OpenMP (*`gdal_check_package(OpenMP ... COMPONENTS "C" CAN_DISABLE)` in `cmake/helpers/CheckDependentLibraries.cmake`*), which causes two problems:

- in a static build the exported `GDAL::GDAL` target gets `OpenMP::OpenMP_C` in its link interface (*the patch links `gcore` to that target*), and `GDALConfig.cmake` gets a plain `find_dependency(OpenMP REQUIRED)`. CMake's `FindOpenMP` only creates targets for the languages that are enabled in the consuming project, so a project with `project(something CXX)` will fail at configure with "*link interface of target "GDAL::GDAL" contains: OpenMP::OpenMP_C but the target was not found*";
    + somewhat related, the same happens to static OpenCV consumers, because `OpenCVConfig.cmake` calls `find_dependency(GDAL)`;
- the resulting package depends on the build host: OpenMP gets found with GCC and MSVC, but usually not with Apple Clang (*which ships no OpenMP runtime*), and nothing in the package ABI reflects that.

Disabling OpenMP should not affect anything important. As of GDAL version `3.13.1`, only these source files are using OpenMP at all:

- `frmts/safe/safedataset.cpp` - the SAFE (*Sentinel-1*) driver, which is an optional driver and so is not built here (*`-DGDAL_BUILD_OPTIONAL_DRIVERS=0`*);
- `gcore/gdaldataset.cpp` and `gcore/gdal_matrix.hpp` - both of their `#pragma omp parallel for` loops belong to `GDALDataset::ComputeInterBandCovarianceMatrix()`. Nothing inside GDAL calls it (*no driver, not the warper, not even GDAL's own command-line tools*), only applications calling that API directly (*`GDALDatasetComputeInterBandCovarianceMatrix()`, or `GetInterBandCovarianceMatrix()` with `bForce`*). And even then it uses threads only for datasets with 100 or more bands, and only when the application sets `GDAL_NUM_THREADS`, which defaults to `1` there.

The multithreading that applications actually rely on - warping, multithreaded GeoTIFF compression, overviews, VRT, pansharpening, gridding, viewshed - is implemented with GDAL's own thread pool (*`CPLWorkerThreadPool`*), not OpenMP, and so it is not affected. The `#pragma omp simd` loops are not affected either: without OpenMP, GDAL compiles them with `-fopenmp-simd` (*`HAVE_OPENMP_SIMD` in `gdal.cmake`*), which needs no runtime library.

When updating GDAL, re-check that this still holds, as new OpenMP code might appear in what is built here:

``` sh
$ rg -l '#\s*pragma\s+omp|_Pragma\s*\(\s*"omp|\b_OPENMP\b|\bomp_[a-z_]+\s*\(|HAVE_OPENMP' --glob '*.{c,cc,cpp,cxx,h,hpp}' .
```

The two OpenMP hunks in the patch (*linking `gcore` to `OpenMP::OpenMP_C` and the `find_dependency(OpenMP REQUIRED)` line in `gdal.cmake`*) have no effect while OpenMP is disabled. Should it ever be enabled again, the consumer problem has to be solved first, for example by switching GDAL to the `CXX` component throughout: `COMPONENTS "CXX"`, `OpenMP_CXX_FLAGS` and `OpenMP_CXX_INCLUDE_DIRS`, linking to `OpenMP::OpenMP_CXX` and `find_dependency(OpenMP COMPONENTS CXX)` in the config (*a static GDAL is C++, so its consumers link as C++ anyway*).
