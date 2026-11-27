# Maintainer notes

## Patch

`001-single-target-and-installation.patch` only touches `build/cmake/CMakeLists.txt`. It replaces the upstream `lz4_shared` and `lz4_static` targets (*and the `lz4` interface target that points at one of them*) and their installation with one target, and it has to keep these properties when it is rebased onto a new upstream version:

- one library type per build: the type follows `BUILD_SHARED_LIBS`, which is upstream's own switch and which vcpkg sets from `VCPKG_LIBRARY_LINKAGE`. The `BUILD_STATIC_LIBS` option, which upstream has for building the static library in addition to the shared one, is removed
- the project is renamed from `LZ4` to `lz4`, so the target is called `lz4` and is exported as the lower-case namespaced `lz4::lz4` (*`PROJECT_NAMESPACE_FOR_PACKAGE` set to `lz4`*), with the CMake package config in `share/lz4/`, installed by the common `Installing.cmake` from `decovar-vcpkg-cmake` with the port's own `Config.cmake.in` (*see [Multithreading](#multithreading)*). Upstream's `LZ4::lz4_shared`, `LZ4::lz4_static` and `LZ4::lz4` do not exist
- the public headers are installed into `include/lz4/`, so consumers include them as `<lz4/lz4.h>`. These are the four headers that upstream's CMake installs: `lz4.h`, `lz4hc.h`, `lz4frame.h` and `lz4file.h`. `lz4frame_static.h` is not one of them: it only defines `LZ4F_STATIC_LINKING_ONLY` and includes `lz4frame.h`
- the binaries are named the same for both library types: `OUTPUT_NAME lz4` on every platform, with the `d` debug postfix everywhere, so `lz4.lib`/`lz4.dll` and `lz4d.lib`/`lz4d.dll` with MSVC, `liblz4.a`/`liblz4.so` and `liblz4d.a`/`liblz4d.so` on Linux and so on
- nothing of pkg-config: the `PKG-CONFIG` section, which generates `liblz4.pc`, and its installation are removed
- upstream's multithreading options are mapped onto the one target: `LZ4_SHARED_MULTITHREAD` applies with `BUILD_SHARED_LIBS` and `LZ4_STATIC_MULTITHREAD` without it, and `LZ4_STATIC_NEEDS_THREADS` is still set, because `Config.cmake.in` goes by it
- Emscripten without `-pthread` gets no multithreading: the `EMSCRIPTEN` check of `__EMSCRIPTEN_PTHREADS__` in the multithreading section is an addition that upstream does not have (*see [Multithreading](#multithreading)*)
- the minimum required CMake version is 3.28 (*upstream: `3.5...4.0.2`*)

The whole upstream installation section is replaced, and with it the installation of the programs, the man pages and the `lz4cat`/`unlz4` symlinks. The port builds with `LZ4_BUILD_CLI=0` and `LZ4_BUILD_LEGACY_LZ4C=0`. The programs compile the library sources themselves instead of linking the library, so they would still build when enabled, but nothing would install them.

In the installed `lz4.h` and `lz4frame.h` `portfile.cmake` replaces `defined(LZ4_DLL_IMPORT) && (LZ4_DLL_IMPORT==1)` with `1 && defined(_MSC_VER)` for a shared library and with `0` for a static one, like the port in microsoft/vcpkg does, so consumers of a DLL get `__declspec(dllimport)` without defining anything, and consumers of a static library cannot get it by accident.

## Multithreading

Multithreading in the library (*`LZ4F_MULTITHREAD`, for `nbWorkers` in `LZ4F_preferences_t`*) is enabled in both library types: `portfile.cmake` passes `LZ4_SHARED_MULTITHREAD=1` and `LZ4_STATIC_MULTITHREAD=1`. Upstream enables it only in the shared library by default, so that programs linking the static one do not have to link threads. That requirement is accepted here, because every `decovar-*` triplet is static, and with upstream's default none of them would have it.

Enabling it does not make anything faster by itself. A consumer asks for it per frame with `nbWorkers` >= 1, the default 0 compresses in the calling thread exactly as before, and it exists only for compression through the frame API (*`lz4frame.h`, `lz4file.h`*): the block API and decompression have no threads. Upstream marks `nbWorkers` as experimental. `LZ4F_getMaxNbWorkers()` (*behind `LZ4F_STATIC_LINKING_ONLY`*) returns 0 when the library has no multithreading. Without it `nbWorkers` >= 1 is not an error: the jobs run in the calling thread.

Measured with the static library on x64-linux (*1.11.1, 2026-11-27, 16 cores, `LZ4F_compressFrame()` of 256 MB at level 0*): 379 MB/s with `nbWorkers` 0, then 716, 1372 and 2743 MB/s with 2, 4 and 8. `nbWorkers` 1 is no faster than 0.

For consumers of the static library the exported target links `Threads::Threads` (*as `$<LINK_ONLY:Threads::Threads>`*) everywhere except Windows, which has its own threads. That is why the port has its own `Config.cmake.in`: it calls `find_dependency(Threads)` when `LZ4_STATIC_NEEDS_THREADS` is set, like upstream's `lz4Config.cmake.in` does, and the common one does not look for anything. Unlike upstream's it does not set `THREADS_PREFER_PTHREAD_FLAG`, which would stay set in the consumer's project.

Emscripten without `-pthread` (*the `decovar-wasm32-emscripten` triplet*) is the one exception. `find_package(Threads)` succeeds there, because libc has the pthread functions, but `pthread_create()` always fails, and a library with `LZ4F_MULTITHREAD=1` then fails every frame that has `nbWorkers` >= 1 with `ERROR_allocation_failed`, while a library without it compresses the same frame in the calling thread. So the patch leaves multithreading off when `__EMSCRIPTEN_PTHREADS__` is not defined. `decovar-wasm32-emscripten-pthreads` gets it. Both were verified with Emscripten 5.0.5 on 2026-11-27.

The static library with multithreading has not been build-tested with MSVC or clang-cl. There `lz4frame.c` includes `<windows.h>` and needs the Windows Vista API (*it defines `_WIN32_WINNT` as `0x0600` when that is lower or not defined*), which is the code that upstream builds into the DLL by default.

## Dependencies

The library has no external dependencies.

xxHash is vendored in `lib/xxhash.c` and `lib/xxhash.h`, and `lib/lz4frame.c` uses its XXH32 for the frame checksums. The rule is to use the `xxhash` port instead of a vendored copy when that copy has no modifications, and this one has them. 1.11.1 has xxHash 0.6.5: the header is identical to the original `v0.6.5`, but `xxhash.c` differs from it in 223 lines (*checks for Clang on Windows, fixes for warnings and typos*). So it stays vendored, and its symbols are prefixed with `LZ4_` (*`XXH_NAMESPACE=LZ4_`*).

## To check on every update

- whether the vendored xxHash is still modified, with the version taken from `XXH_VERSION_*` in the header: `for f in xxhash.h xxhash.c; do diff <(curl -sS https://raw.githubusercontent.com/Cyan4973/xxHash/v0.6.5/$f) lib/$f; done`
- whether `defined(LZ4_DLL_IMPORT) && (LZ4_DLL_IMPORT==1)` is still present in `lib/lz4.h` and `lib/lz4frame.h`, and in no other public header
- the list of headers in upstream's `install(FILES …)` against `LZ4_PUBLIC_HEADERS` in the patch
- new options in `build/cmake/CMakeLists.txt`
- whether upstream's `lz4Config.cmake.in` still goes by `LZ4_STATIC_NEEDS_THREADS` and still needs nothing but Threads, compared with the port's `Config.cmake.in`
- whether upstream turns multithreading off for Emscripten without `-pthread` by itself (*in `build/cmake/CMakeLists.txt` or next to the `LZ4_FREESTANDING` check in `lib/lz4frame.c`*), so that the check in the patch can be dropped
