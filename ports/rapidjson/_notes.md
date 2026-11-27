# Maintainer notes

## Version

Upstream has not made a release since `v1.1.0` (*August 2016*), so the port follows `master` and takes its version from the date of the pinned commit, written as `YYYY.M.D` without leading zeros. That is the committer date: `297637bc` was committed on 2026-11-03 (*its author date is 2026-10-29*), which makes it `2026.11.3`.

It is the `version` scheme and not `version-date`, because `portfile.cmake` passes `${VERSION}` as `RAPIDJSON_VERSION`, and the patch puts that into `project(... VERSION ...)`, which accepts only dotted numbers. So `RapidJSONConfigVersion.cmake` reports the date-based version, while the headers still say `1.1.0` in `RAPIDJSON_VERSION_STRING`.

## Patch

`001-installation.patch` replaces the upstream installation, and it has to keep these properties when it is rebased onto a new upstream version:

- one `INTERFACE` target, called `RapidJSON` like the project and exported without a namespace, with the CMake package config in `share/RapidJSON/`, installed by the common `Installing.cmake` and `Config.cmake.in` from `decovar-vcpkg-cmake`. Consumers do `find_package(RapidJSON CONFIG REQUIRED)` and link to `RapidJSON`
- the public headers are installed into `include/rapidjson/`, so consumers include them as `<rapidjson/document.h>`
- `RAPIDJSON_HAS_STDSTRING` (*which `portfile.cmake` enables*) and `RAPIDJSON_USE_MEMBERSMAP` (*which it disables*) are `INTERFACE` compile definitions of the target and not `add_definitions()`. The library is header-only, so a definition reaches the consumers only through the target, and all of them have to agree on these two
- the C++ standard is the `cxx_std_11` compile feature of the target, the upstream `RAPIDJSON_BUILD_CXX11`/`17`/`20` options are removed
- `include(GNUInstallDirs)` comes before `target_include_directories()`, otherwise `$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>` expands to nothing. `Installing.cmake` adds the same folder once more with `INCLUDES DESTINATION`, so `RapidJSONTargets.cmake` lists `${_IMPORT_PREFIX}/include` twice, which is harmless

The target is not the lower-case namespaced `rapidjson::rapidjson` at the moment, but it should be considered even though it would involve updating at least `assimp` port.

Upstream's own `RapidJSONConfig.cmake.in` is not used, so its `rapidjson` alias and the `RapidJSON_INCLUDE_DIRS` variable are not provided. The `RapidJSON.pc` pkg-config file, the readme and the examples are not installed.

The `doc/`, `example/` and `test/` folders are not patched and not built (*`RAPIDJSON_BUILD_DOC`, `RAPIDJSON_BUILD_EXAMPLES` and `RAPIDJSON_BUILD_TESTS` are off*). The port compiles nothing, so the compiler flags which the upstream `CMakeLists.txt` adds (*`-march=native` with `RAPIDJSON_ENABLE_INSTRUMENTATION_OPT`, `-Werror` and others*) have no effect on the package.
