# Maintainer notes

<!-- MarkdownTOC -->

- [Why](#why)
- [How to use it](#how-to-use-it)
- [Problems](#problems)

<!-- /MarkdownTOC -->

## Why

The reason for creating this port is that [System.Data.SQLite](https://nuget.org/packages/System.Data.SQLite/) NuGet package (*version `1.0.119.0` at the time of writing*) does not provide pre-built binaries for ARM-based Mac OS targets (*here's a [forum thread](https://sqlite.org/forum/forumpost/f985511fd94fb44c)*).

And so you will get the following runtime error in your projects:

``` sh
dlopen(/path/to/project/bin/Debug/net8.0/SQLite.Interop.dll, 0x0001): tried: '/path/to/project/bin/Debug/net8.0/SQLite.Interop.dll' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/path/to/project/bin/Debug/net8.0/SQLite.Interop.dll' (no such file), '/path/to/project/bin/Debug/net8.0/SQLite.Interop.dll' (no such file)
dlopen(SQLite.Interop.dll, 0x0001): tried: 'SQLite.Interop.dll' (no such file), '/System/Volumes/Preboot/Cryptexes/OSSQLite.Interop.dll' (no such file), '/usr/lib/SQLite.Interop.dll' (no such file, not in dyld cache), 'SQLite.Interop.dll' (no such file), '/usr/local/lib/SQLite.Interop.dll' (no such file), '/usr/lib/SQLite.Interop.dll' (no such file, not in dyld cache)
dlopen(/usr/local/share/dotnet/shared/Microsoft.NETCore.App/8.0.0/libSQLite.Interop.dll, 0x0001): tried: '/usr/local/share/dotnet/shared/Microsoft.NETCore.App/8.0.0/libSQLite.Interop.dll' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/usr/local/share/dotnet/shared/Microsoft.NETCore.App/8.0.0/libSQLite.Interop.dll' (no such file), '/usr/local/share/dotnet/shared/Microsoft.NETCore.App/8.0.0/libSQLite.Interop.dll' (no such file)
dlopen(/path/to/project/bin/Debug/net8.0/libSQLite.Interop.dll, 0x0001): tried: '/path/to/project/bin/Debug/net8.0/libSQLite.Interop.dll' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/path/to/project/bin/Debug/net8.0/libSQLite.Interop.dll' (no such file), '/path/to/project/bin/Debug/net8.0/libSQLite.Interop.dll' (no such file)
dlopen(libSQLite.Interop.dll, 0x0001): tried: 'libSQLite.Interop.dll' (no such file), '/System/Volumes/Preboot/Cryptexes/OSlibSQLite.Interop.dll' (no such file), '/usr/lib/libSQLite.Interop.dll' (no such file, not in dyld cache), 'libSQLite.Interop.dll' (no such file), '/usr/local/lib/libSQLite.Interop.dll' (no such file), '/usr/lib/libSQLite.Interop.dll' (no such file, not in dyld cache)
```

[One workaround](https://stackoverflow.com/a/71387235/1688203) at the moment is to build that missing DLL from sources. [Another possible workaround](https://stackoverflow.com/a/73143706/1688203) one is to use the x64 variant of the .NET runtime, and in that case you shouldn't need to use this port. Finally, you can probably try to use [Microsoft.Data.Sqlite](https://www.nuget.org/packages/Microsoft.Data.Sqlite/) package instead.

## How to use it

It's the same as with any other vcpkg port. There is just one small detail that you most likely need a shared/dynamic library (*as it's for a .NET project*), so you might want to use the `arm64-osx-dynamic` triplet or maybe some other custom triplet for building on Mac OS, which should have:

- `VCPKG_TARGET_ARCHITECTURE` set to `arm64`
- `VCPKG_LIBRARY_LINKAGE` set to `dynamic`

The port has a `interop-only` feature, which is enabled by default, and it means that only the `SQLite.Interop` library will be built, so building `System.Data.SQLite` library will be skipped. The reason for this is that only `SQLite.Interop` should be needed, as the `System.Data.SQLite` should already be there from the NuGet package, however if you'd like to build `System.Data.SQLite` too, then disable the `interop-only` feature.

Once the port is built and installed, copy the `libSQLite.Interop.dylib` and `libz.1.3.1.dylib` (*if you are building a version that depends on zlib*) binaries into your project's build folder (*should also work if you just copy them to the project root*). The (*potential*) requirement of having `libz.1.3.1.dylib` too is a bit unfortunate, and if you'd like to get rid of it, you'll need to modify the port, so `zlib` would be built separately as a static library. After the binaries are copied, rename `libSQLite.Interop.dylib` to `SQLite.Interop.dll` (*`libSQLite.Interop.dll` will also work*).

Now you can run your project.

## Problems

For some SQL queries the application might crash with a stack overflow runtime error. Probably that is the reason why original `System.Data.SQLite` maintainers do not yet provide a pre-build binary for ARM-based Mac OS targets.
