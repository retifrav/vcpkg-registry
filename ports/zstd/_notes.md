# Maintainer notes

## Patch

`001-single-target.patch` replaces the upstream `libzstd_shared` and `libzstd_static` targets (*and the `libzstd` interface target that points at one of them*) and their installation with one target, and it has to keep these properties when it is rebased onto a new upstream version:

- one library type per build: the type is chosen from `ZSTD_BUILD_SHARED` / `ZSTD_BUILD_STATIC` (*which `portfile.cmake` sets from `VCPKG_LIBRARY_LINKAGE`*), and the configuration fails when both or neither of them are enabled
- the target is called `zstd` and is exported as the lower-case namespaced `zstd::zstd` (*`PROJECT_NAMESPACE_FOR_PACKAGE` set to `zstd`*), with the CMake package config in `share/zstd/`, installed by the common `Installing.cmake` and `Config.cmake.in` from `decovar-vcpkg-cmake`. For that `project(libzstd C)` is removed from `build/cmake/lib/CMakeLists.txt`, so `PROJECT_NAME` and `PROJECT_VERSION` in there are the ones of the top-level `zstd` project, and `include(ZstdPackage)` is removed from `build/cmake/CMakeLists.txt`
- the public headers are installed into `include/zstd/`, so consumers include them as `<zstd/zstd.h>`
- the binaries are named the same for both library types: `OUTPUT_NAME zstd` on every platform, with the `d` debug postfix everywhere, so `zstd.lib`/`zstd.dll` and `zstdd.lib`/`zstdd.dll` with MSVC, `libzstd.a`/`libzstd.so` and `libzstdd.a`/`libzstdd.so` on Linux and so on. Upstream names the static library `zstd_static` with MSVC, which the patch drops, and `InternalName`/`OriginalFilename` in `build/VS2010/libzstd-dll/libzstd-dll.rc` are patched to `zstd.dll`/`zstdd.dll` accordingly
- nothing of pkg-config: the whole `# pkg-config` block, which generates and installs `libzstd.pc`, is removed
- the minimum required CMake version is 3.28, and the "Setup CMake policy version" block is removed from `build/cmake/CMakeModules/ZstdVersion.cmake`: it calls `cmake_policy(VERSION 3.13.0)` right after `cmake_minimum_required()`, which would unset every policy introduced after 3.13 and so undo the raised minimum

The target also gets its include directory as `PUBLIC` (*upstream: `INTERFACE`*), so that the resource compiler finds `zstd.h`, and links `${THREADS_LIBS}` under `UNIX AND NOT APPLE` (*upstream: `UNIX`*), which is carried over from the 1.5.x patch.

`build/cmake/programs/`, `build/cmake/tests/` and `build/cmake/contrib/` are deliberately not patched. The port builds with `ZSTD_BUILD_PROGRAMS=0`, `ZSTD_BUILD_TESTS=0` and `ZSTD_BUILD_CONTRIB=0`. They still link `libzstd_shared` / `libzstd_static`, and the executable target of the CLI is called `zstd` like the library, so enabling any of them fails.

What the patch drops from upstream:

- the Apple framework variant: the `ZSTD_FRAMEWORK` option is still declared in `ZstdOptions.cmake`, but it does nothing
- upstream's own package config (*`zstdConfig.cmake.in`, `ZstdPackage.cmake`*). Its `find_dependency(Threads)` is not needed, because the target links the plain `${CMAKE_THREAD_LIBS_INIT}` flag and not `Threads::Threads`, and the version file is `AnyNewerVersion` now (*upstream: `SameMajorVersion`*)

Upstream's `.gitattributes` gives `*.rc` files CRLF line endings, also in the `git archive` that vcpkg extracts, while the patch has LF. That hunk applies only with `--ignore-whitespace` (*which is what vcpkg uses*) and leaves the file with mixed line endings.

The port in microsoft/vcpkg carries three patches. `no-static-suffix.patch` and `fix-windows-rc-compile.patch` are covered by the properties above. `fix-emscripten-and-clang-cl.patch` is not taken: both `decovar-wasm32-emscripten` triplets build 1.6.0 without it. clang-cl could not be tried, so that patch is the first thing to look at if `decovar-x64-windows-static-md-clang` has trouble with the compiler flags from `AddZstdCompilationFlags.cmake`.

## Dependencies

The library has no external dependencies. LZ4, zlib and lzma are used by the `zstd` CLI only (*`ZSTD_LZ4_SUPPORT`, `ZSTD_ZLIB_SUPPORT` and `ZSTD_LZMA_SUPPORT` in `build/cmake/programs/CMakeLists.txt`, for reading and writing `.lz4`, `.gz` and `.xz` files*), which this port does not build.

Vendored code in `lib/`:

- xxHash in `lib/common/xxhash.c` and `lib/common/xxhash.h`. The rule is to use the `xxhash` port instead of a vendored copy when that copy has no modifications, and this one has them. 1.6.0 has xxHash 0.8.2, which zstd changed in its own repository after importing it: leaving comments aside, 118 lines differ from the original `v0.8.2` (*`XXH_NO_XXH3` and a default `XXH_NAMESPACE ZSTD_` as "local adaptations", a guard against AVX-512 auto-vectorization in the XXH64 round, `<inttypes.h>` on AIX, `extern "C"` blocks moved around the includes, `XXH_HAS_INCLUDE`, `_M_AMD64`*). So it stays vendored, and its symbols are prefixed with `ZSTD_`
- divsufsort in `lib/dictBuilder/divsufsort.c` and `lib/dictBuilder/divsufsort.h`: a modified libdivsufsort with a different API (*an additional `openMP` parameter*), so the original could not replace it either

## To check on every update

- whether the vendored xxHash is still modified, with the version taken from `XXH_VERSION_*` in the header: `diff <(curl -sS https://raw.githubusercontent.com/Cyan4973/xxHash/v0.8.2/xxhash.h) lib/common/xxhash.h`
- whether `defined(ZSTD_DLL_IMPORT) && (ZSTD_DLL_IMPORT==1)` is still present in `lib/zstd.h`, `lib/zdict.h` and `lib/zstd_errors.h`: `portfile.cmake` replaces it with `1` in the installed headers of a Windows DLL build
- new options in `build/cmake/CMakeModules/ZstdOptions.cmake` and at the top of `build/cmake/lib/CMakeLists.txt`
