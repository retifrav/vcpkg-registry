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

## Threads

In a static build the exported `GDAL::GDAL` target has `Threads::Threads` in its link interface on every platform except MSVC (*`port/CMakeLists.txt` links `cpl` to it under `NOT MSVC` and `Threads_FOUND`*), so `GDALConfig.cmake` has to call `find_dependency(Threads)` before including `GDAL-targets.cmake`. The line for that is written by `cmake/helpers/CheckDependentLibrariesCommon.cmake`, and the patch has to leave it as it is upstream. It needs no platform check of its own: it is written only under `if(TARGET Threads::Threads)`, and GDAL looks for Threads only in the non-MSVC branch of `cmake/helpers/configure.cmake`, the same platforms where `cpl` links it.

In previous port versions the patch had that line commented out, which went unnoticed, because it kept working by accident: `GDALConfig.cmake` finds `tiff`, the config of `tiff` finds `zstd`, and the config of `zstd` `1.5.6` called `find_dependency(Threads)` itself. The `zstd` port stopped doing that with `1.6.0` (*its own target does not need it*), and then a project calling `find_package(GDAL)` failed at configure with "*link interface of target "GDAL::GDAL" contains: Threads::Threads but the target was not found*", unless it had found Threads by itself before that. So every target in the link interface of `GDAL::GDAL` has to be found by `GDALConfig.cmake` itself, also when the config of another dependency happens to find it.
