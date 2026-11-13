# Maintainer notes

## ICU

Unlike Microsoft's port, there is no `icu` feature here. It was present before (*originated with `CMakeLists.txt` taken from [azadkuh/sqlite-amalgamation](https://github.com/azadkuh/sqlite-amalgamation)*), but all it did was set the `SQLITE_ENABLE_ICU` compile definition. There was no dependency on the `icu` port, no `find_package(ICU)` and no linking, so it could never work - `sqlite3.c` would either fail to compile on `#include <unicode/utypes.h>` or pick up some system ICU headers and then fail to link. It was removed in `3.53.1`, and commented-out option in `CMakeLists.txt` and the feature line in `portfile.cmake` are left as markers.

### What it would provide

With `SQLITE_ENABLE_ICU` the amalgamation compiles in its `icu.c` and `fts3_icu.c` parts, and `sqlite3IcuInit()` registers the following (*as of `3.53.1`*):

| Function | Built-in, without ICU | With ICU | Needs full ICU data |
|----------|-----------------------|----------|---------------------|
| `upper()` / `lower()` | ASCII only | full Unicode, with an optional locale argument (*such as `'tr_TR'`*) | no, case mapping data is compiled into `icuuc` |
| `LIKE` | case-insensitive for ASCII only | case-insensitive for all of Unicode (*`u_foldCase()`*) | no |
| `REGEXP` | not defined in the library at all (*the CLI tool has its own, from `ext/misc/regexp.c`*) | ICU regular expressions (*`uregex_*()`*) | no, at least for usual patterns |
| `icu_load_collation()` | only `BINARY`, `NOCASE` (*ASCII*) and `RTRIM` collations | locale collations (*`ucol_open()`*) | yes, otherwise it fails at runtime with an ICU error |
| FTS3/FTS4 `icu` tokenizer | `simple`, `porter` and `unicode61` tokenizers | locale-aware word breaking (*`ubrk_open()`*), needs `fts3`/`fts4` too | yes |

The "*needs full ICU data*" means `icu[data]`: without that feature the `icu` port installs the stub data library, which is enough only for the functionality with compiled-in data. There is also `SQLITE_ENABLE_ICU_COLLATIONS`, which compiles in only `icu_load_collation()`, but that is exactly the one that needs the full data.

### Why it is not enabled

- ICU takes a long time to build, and here it would be built twice: the `icu` port depends on host `icu[tools]`, and the custom triplets from this registry never match the host triplet. On Windows it also goes through `vcpkg-make` with MSYS2. Binary caching helps only until the ABI changes (*compiler, toolchain file, any tweak of the port*), and then both get rebuilt;
- most of the triplets here are static, so every consumer would be linking static `icui18n`, `icuuc` and `icudata` plus the C++ standard library, and with collations also the full data, which is around 30 MB. For Emscripten builds (*where the `in-memory-vfs` feature is most likely to be used*) that is a lot;
- ICU's `LIKE` replaces the built-in one, and SQLite does not apply the [LIKE optimization](https://sqlite.org/optoverview.html#the_like_optimization) to an overloaded `LIKE`, so `column LIKE 'prefix%'` stops using indexes;
- nothing in this registry needs it: `proj` is the only port depending on `sqlite`, and it doesn't use ICU functionality;
- an optional feature that nobody builds silently rots, which is exactly what happened to the original one.

The most common needs are covered without ICU anyway:

- Unicode-aware full-text search: FTS5 default `unicode61` tokenizer (*with `remove_diacritics`*), which is also available for FTS3/FTS4;
- Unicode-aware case mapping and comparison in SQL: the application can register its own functions and collations with `sqlite3_create_function_v2()` / `sqlite3_create_collation_v2()`, implemented with whatever Unicode library it already uses (*Qt, ICU itself, OS APIs*). That also keeps the built-in `LIKE` and its optimization intact.

### Enabling it again

Microsoft's `sqlite3` port has it as the `unicode` feature (*added in [#41753](https://github.com/microsoft/vcpkg/pull/41753)*), and [#46007](https://github.com/microsoft/vcpkg/pull/46007) shows what the ICU CMake wrapper changes (*which the `icu` port in this registry carries too*) led to: they had to switch the project to `project(sqlite3 C CXX)` and patch GDAL's `FindSQLite3`. Here it would take the following:

1. `vcpkg.json`: an `icu` feature with `"dependencies": ["icu"]`. Plain `icu` (*stub data*) is enough for `upper()`/`lower()`/`LIKE`/`REGEXP`, and consumers that want collations or the FTS3 tokenizer can add `icu[data]` in their own manifests;
2. `portfile.cmake`: `icu SQLITE_ENABLE_ICU` back in `vcpkg_check_features()`;
3. `CMakeLists.txt`: the `SQLITE_ENABLE_ICU` option and the `$<$<BOOL:${SQLITE_ENABLE_ICU}>:SQLITE_ENABLE_ICU>` compile definition back, and then something like this:
    ``` cmake
    if(SQLITE_ENABLE_ICU)
        # the project is C-only, but the CMake wrapper of the icu port marks static ICU::uc
        # as a C++ library and gives it `cxx_std_17` compile feature
        enable_language(CXX)
        find_package(ICU COMPONENTS i18n uc REQUIRED)
        target_link_libraries(${PROJECT_NAME} PRIVATE ICU::i18n ICU::uc)
    endif()
    ```
    for static linkage the wrapper adds the `data` component and orders the libraries by itself;
4. package config: the common `Config.cmake.in` from `decovar-vcpkg-cmake` has no dependencies, but a static `sqlite3` gets `$<LINK_ONLY:ICU::...>` in its exported link interface, so the port would need its own `Config.cmake.in` with `find_dependency(ICU COMPONENTS i18n uc)` for static builds (*conditional, the same way as `ports/curl/Config.cmake.in` does it for its dependencies*);
5. consumers: C-only projects linking to a static `sqlite3` with ICU would need to enable `CXX` as well, which is what the GDAL patch in Microsoft's registry is about.

None of that has been tried here, so it is a starting point rather than a recipe.

### Checking

As of `3.53.1`, without ICU:

``` sh
$ ./sqlite3 :memory: "select sqlite_compileoption_used('ENABLE_ICU'), upper('straße'), 'Ä' like 'ä', 'A' like 'a';"
0|STRAßE|0|1
```

With ICU it should be `1|STRASSE|1|1` (*full case mapping turns `ß` into `SS`*). It is also worth checking that `sqlite[icu,tool]` builds with a static triplet (*the tool is a C executable linking static ICU*), and that a C-only consumer project links too.

## DLL

### Exporting symbols

In the amalgamation every public function and variable is marked with `SQLITE_API`, and everything internal is `SQLITE_PRIVATE`, which is `static`. So defining `SQLITE_API=__declspec(dllexport)` when building the library exports exactly the public API, without any `.def` file. That is also how SQLite's own `Makefile.msc` builds the DLL (*`CORE_COMPILE_OPTS`*), while building its shell against that DLL with `SQLITE_API=__declspec(dllimport)` (*`SHELL_COMPILE_OPTS` with `DYNAMIC_SHELL`*).

`CMakeLists.txt` does the same with `BUILD_SHARED_LIBS` on Windows:

- `SQLITE_API=__declspec(dllexport)` is `PRIVATE` to the library;
- `SQLITE_API=__declspec(dllimport)` is in its `INTERFACE`, but wrapped in `$<BUILD_INTERFACE:...>`, so it only gets to the in-tree consumers, which is the CLI tool;
- installed consumers get `__declspec(dllimport)` from the installed `sqlite3.h` instead: with Windows and dynamic linkage `portfile.cmake` replaces the `# define SQLITE_API` default in it. That works for consumers that don't use CMake too (*such as MSBuild projects with vcpkg integration*), and since it stays within `#ifndef SQLITE_API`, it can still be overridden.

On other platforms the library gets `SQLITE_API=__attribute__((visibility("default")))`, also `PRIVATE`, as consumers don't need it.

The DLLs are `sqlite3.dll` and `sqlite3d.dll` (*`CMAKE_DEBUG_POSTFIX`*) in `bin`, with the import libraries `sqlite3.lib` and `sqlite3d.lib` in `lib`, and with the `tool` feature `vcpkg_copy_tools()` puts the DLL next to `sqlite3.exe`.

### Why consumers need dllimport

Functions link either way: without `__declspec(dllimport)` the compiler emits a plain call, which gets resolved by a stub in the import library. Variables are different: an exported variable is reachable only through its `__imp_` pointer, which the compiler uses only with `__declspec(dllimport)`, so without it `sqlite3_version`, `sqlite3_temp_directory` and `sqlite3_data_directory` fail to link with `LNK2001`.

Up to `3.49.1` the `SQLITE_API` definition was `PRIVATE`, so consumers had it empty, and the first `3.53.1` made it `PUBLIC`, so consumers were getting `__declspec(dllexport)` from `sqlite3Targets.cmake`. In both cases functions worked and those variables did not.

If a new SQLite version changes that block in `sqlite3.h`, `vcpkg_replace_string()` only prints a `vcpkg_replace_string made no changes.` warning (*it is fatal only with `_VCPKG_PROHIBIT_BACKCOMPAT_FEATURES`*), and the build carries on without the import, so look out for that warning after updating.

The CLI tool doesn't use any of those variables (*as of `3.53.1`, `shell.c` references only `sqlite3IoTrace`, and only with `SQLITE_ENABLE_IOTRACE`*), so it would link even without `dllimport`.

### memvfs.c

The `in-memory-vfs` feature installs `memvfs.c` into `share/sqlite3/etc/`, for consumers to compile it in their own projects. It is written as a loadable extension: it includes `sqlite3ext.h`, so all its SQLite API calls go through the `sqlite3_api` routines table and don't depend on how SQLite is linked. The only thing that does is the `sqlite3_memvfs_init()` entry point itself.

Upstream marks that function with `__declspec(dllexport)` on Windows unconditionally. `001-dll-definitions.patch` replaces that with its own `SQLITE_MEMVFS_API` macro, which is empty by default, so a consumer project that is a DLL and needs to export `sqlite3_memvfs_init()` should set `SQLITE_MEMVFS_API=__declspec(dllexport)` compile definition. It cannot be `SQLITE_API`, because for consumers of the SQLite DLL that one is `__declspec(dllimport)`, and defining a function declared as dllimport is an error ([C2491](https://learn.microsoft.com/en-us/cpp/error-messages/compiler-errors-1/compiler-error-c2491)). The first `3.53.1` did use `SQLITE_API` there, which only worked because consumers were getting `__declspec(dllexport)` from it.

`memvfs.c` is not a part of the amalgamation, and it isn't even in SQLite repository anymore (*removed in 2025-10, see the links in `portfile.cmake`*), so the port downloads the copy saved from `3.49.1` (*Git blob `83fc946`*).

The patch is applied with Git, not with the `patch` tool, because the latter usually isn't available on Windows (*Git for Windows has `patch.exe` in its `usr\bin`, which is not in `PATH` by default*). The arguments are the same as vcpkg's own patching uses, and `--work-tree=. --git-dir=.git` are important: the `packages` folder is normally inside vcpkg's own Git repository, and there a plain `git apply` prints `Skipped patch 'memvfs.c'` and exits with `0`, leaving the file unpatched. The patch is made against SQLite's source tree (*`ext/misc/memvfs.c`*), hence the `-p3` here, while applied to a full source tree it would take the default `-p1`.

To update the patch, in a temporary folder:

``` sh
$ mkdir -p ./ext/misc && cp /path/to/memvfs.c ./ext/misc/
$ git init && git add ./ext/misc/memvfs.c
$ # edit ./ext/misc/memvfs.c
$ git diff > /path/to/ports/sqlite/001-dll-definitions.patch
```

### Checking on Windows

As of `3.53.1` all of the above was checked only on Linux: the Windows branch of `CMakeLists.txt` by configuring the project with `-DWIN32=1` (*the library gets `dllexport`, the tool gets `dllimport`, and `sqlite3Targets.cmake` has no `SQLITE_API`*), the `sqlite3.h` replacement by running it on a copy of the header, and `memvfs.c` by compiling it with `-DSQLITE_API=__declspec(dllimport)` (*plus a consumer actually using it, with both static and shared SQLite on Linux*). On Windows, with a dynamic triplet such as `x64-windows`:

- `dumpbin /exports sqlite3.dll` should list the API functions, `sqlite3_version`, `sqlite3_temp_directory` and `sqlite3_data_directory` included;
- the installed `include/sqlite3/sqlite3.h` should have `# define SQLITE_API __declspec(dllimport)`;
- a consumer referencing `sqlite3_version` should link;
- `sqlite[in-memory-vfs]` should install, and a consumer DLL compiling `memvfs.c` with `SQLITE_MEMVFS_API=__declspec(dllexport)` should export `sqlite3_memvfs_init`.
