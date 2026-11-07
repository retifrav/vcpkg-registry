# Maintainer notes

## Version

zlib releases are(?) tagged as `vX.Y` when the third component is zero (*`v1.4`*), which this registry versions as `X.Y.0` (*`1.4.0`*) - the missing component is padded with `0`, the same way as in `icu`. A three-component tag such as `v1.3.2` or `v1.4.1` maps as it is.

## Patch

`001-single-target-and-installation.patch` replaces the upstream `zlib` (*shared*) and `zlibstatic` (*static*) targets and their installation with one target, and it has to keep these properties when it is rebased onto a new upstream version:

- one library type per build: the type is chosen from `ZLIB_BUILD_SHARED` / `ZLIB_BUILD_STATIC` (*which `portfile.cmake` sets from `VCPKG_LIBRARY_LINKAGE`*), and the configuration fails when both or neither of them are enabled
- the target is called `zlib` and is exported as the lower-case namespaced `zlib::zlib` (*no `EXPORT_NAME`, `PROJECT_NAMESPACE_FOR_PACKAGE` set to `zlib`*), with the CMake package config in `share/zlib/`, installed by the common `Installing.cmake` and `Config.cmake.in` from `decovar-vcpkg-cmake`
- the public headers are installed into `include/zlib/`, so consumers include them as `<zlib/zlib.h>`
- the binaries are not renamed: `OUTPUT_NAME z` on every platform, with the `d` debug postfix everywhere, so `z.lib`/`z.dll` and `zd.lib`/`zd.dll` with MSVC, `libz.a`/`libz.so` and `libzd.a`/`libzd.so` on Linux and so on. Upstream itself names them differently on Windows (*since `1.4` with MSVC that is `libz` for the shared library and `libzs` for the static one*), which the patch overrides, and `InternalName`/`OriginalFilename` in `win32/zlib-cmake.rc` are patched to `z.dll`/`zd.dll` accordingly

Besides the top-level `CMakeLists.txt` and `win32/zlib-cmake.rc`, the patch only touches `contrib/crc32vx/`, `contrib/gcc_gvmat64/` and `contrib/infback9/`: these are the `ZLIB_WITH_*` options that add sources to the library target itself, so their `zlibstatic` references are replaced with `zlib`.

The `test/` folder and the contrib libraries (*`ada`, `blast`, `iostream3`, `minizip`, `puff`, `testzlib`, `zlib1-dll`*) are deliberately not patched. The port builds with `ZLIB_BUILD_TESTING=0`, and the contrib libraries are off by default. They still reference `ZLIB::ZLIB` / `ZLIB::ZLIBSTATIC` and look for the upstream `ZLIB` package with `shared`/`static` components, so enabling any of them fails.

The `zlib.pc` pkg-config file, the man page and the documentation are not installed.
