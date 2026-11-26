# Maintainer notes

<!-- MarkdownTOC -->

- [Empty certs and private folders](#empty-certs-and-private-folders)
- [Default directories in the resulting package](#default-directories-in-the-resulting-package)
    - [OPENSSLDIR](#openssldir)
    - [ENGINESDIR and MODULESDIR](#enginesdir-and-modulesdir)
    - [Default folders on Windows](#default-folders-on-windows)
        - [MinGW](#mingw)
- [CMake config without the vcpkg toolchain](#cmake-config-without-the-vcpkg-toolchain)

<!-- /MarkdownTOC -->

## Empty certs and private folders

The installed `etc/ssl/certs/` and `etc/ssl/private/` folders are empty (*apart from the `.keep` files*), and that is correct - the port is not supposed to deploy any CA certificates bundle there:

- OpenSSL itself never ships CA certificates: its `install_ssldirs` target only creates empty `certs/`, `private/` and `misc/` folders and installs `openssl.cnf` and `ct_log_list.cnf`. On an actual system `certs/` is populated by the OS (*the `ca-certificates` package on Debian, Arch, Alpine and so on*)
- `private/` is for the machine's own private keys, so a package must never put anything there - a key that is shipped with every installation is not private
- the `.keep` files are created in `unix/portfile.cmake` only because vcpkg post-build checks do not allow empty directories in a package (*the upstream microsoft/vcpkg port does the same*)

## Default directories in the resulting package

### OPENSSLDIR

Everything except the MSVC Windows builds (*MinGW included*) goes through `unix/portfile.cmake`, which configures OpenSSL with `--openssldir=/etc/ssl`. That is the path compiled into the library, so at runtime it looks for the CA certificates in `/etc/ssl/certs/` (*a hashed folder*) and `/etc/ssl/cert.pem` of the target machine, and for the configuration in `/etc/ssl/openssl.cnf`. The `move-openssldir.patch` only makes what `install_ssldirs` writes into `$(DESTDIR)/etc/ssl` end up in the package (*`<installed>/etc/ssl/`*) instead of the build machine's `/etc/ssl` - nothing reads that folder at runtime, so a bundle placed there would not be found anyway.

That is intended: the trust store stays the one of the OS, which gets security updates, removals of distrusted CAs and the corporate root CAs, while a bundle frozen into a port version would only get stale. The `curl` port relies on that too: it is configured with `-DCURL_CA_BUNDLE=none` and `-DCURL_CA_PATH=none`, and with the `openssl` feature `CURL_CA_FALLBACK` makes it use the OpenSSL default paths.

The defaults can be overridden at runtime with the `SSL_CERT_FILE` / `SSL_CERT_DIR` environment variables (*and `OPENSSL_CONF` for the configuration*), or in code with `SSL_CTX_load_verify_locations()` (*`CURLOPT_CAINFO` / `CURLOPT_CAPATH` for curl*).

### ENGINESDIR and MODULESDIR

Besides [OPENSSLDIR](#OPENSSLDIR), two more default folders are compiled into libcrypto (*`openssl version -e -m` prints them*):

- `MODULESDIR` - where `OSSL_PROVIDER_load()` looks for a provider that is requested by name (*from the code or from the providers section of a configuration file*), unless the `OPENSSL_MODULES` environment variable or `OSSL_PROVIDER_set_default_search_path()` says otherwise
- `ENGINESDIR` - the same for the deprecated `ENGINE_by_id()`, for an engine that is not built in, unless the `OPENSSL_ENGINES` environment variable says otherwise

This port puts very little there: the engines are built into libcrypto (*`enable-static-engine`*), and so is the `legacy` provider in the static builds (*`no-module`*). Only the dynamic builds install anything - the `legacy` provider (*and `fips`, with the `fips` feature*) in `lib/ossl-modules/` (*`bin/` on Windows*).

Upstream OpenSSL derives both folders from the install prefix, and `vcpkg_configure_make()` always passes `--prefix=${CURRENT_INSTALLED_DIR}`, so without a patch a folder of the build machine gets compiled in (*such as `/path/to/build/vcpkg_installed/x64-linux/lib/ossl-modules`*), and with binary caching that is the folder of whichever machine built that ABI hash first. Nothing is found there on a target machine, and a user who can create that path there (*a home folder of a user with the same name, a CI build folder under `/tmp`, `/Users/Shared` on macOS*) can plant a module to be loaded into another user's process. That is why `unix/default-search-dirs.patch` compiles in `$(OPENSSLDIR)/engines-3` and `$(OPENSSLDIR)/ossl-modules` instead (*so `/etc/ssl/engines-3` and `/etc/ssl/ossl-modules`*): only root can write there, and no distribution puts modules there, so in practice there is no default folder, unless an administrator creates it. The patch changes only the compiled-in values - the installation layout, the pkg-config variables and the CMake ones (*`OPENSSL_ENGINES_DIR`, `OPENSSL_MODULES_DIR`*) stay as they were.

No compiled-in default can know where an application gets installed, so an application that needs a module (*such as `legacy` with a dynamic build, or a third-party provider*) has to deploy it and point OpenSSL at it: with `OSSL_PROVIDER_set_default_search_path()` before loading it, with the `OPENSSL_MODULES` environment variable, or with an absolute `module` path in the provider section of its configuration.

### Default folders on Windows

The MSVC Windows builds go through `windows/portfile.cmake`, which passes neither `--prefix` nor `--openssldir`, the same as upstream since `3.6.1#3` (*[microsoft/vcpkg#50518](https://github.com/microsoft/vcpkg/pull/50518)*). Before that, the packages folder of the build machine was compiled in as OPENSSLDIR, ENGINESDIR and MODULESDIR. On Windows any user can usually create such a path on another machine (*a new folder in the root of a drive does not require administrative permissions*), and libssl loads `openssl.cnf` from OPENSSLDIR on initialization, so a planted configuration file could load any DLL into a privileged process - that is CVE-2026-34054 (*[GHSA-p322-v6vw-vrq9](https://github.com/microsoft/vcpkg/security/advisories/GHSA-p322-v6vw-vrq9)*).

Now OpenSSL keeps its default paths, which it takes from `%ProgramFiles%` and `%CommonProgramFiles%` of the build machine (*`Program Files (x86)` for 32-bit targets*), and writing there requires administrative permissions:

- OPENSSLDIR - `C:\Program Files\Common Files\SSL`
- ENGINESDIR - `C:\Program Files\OpenSSL\lib\engines-3`
- MODULESDIR - `C:\Program Files\OpenSSL\bin` (*`windows/install-layout.patch` puts the modules into `bin/` instead of `lib/ossl-modules/`*)

The results are installed with `DESTDIR` into `Program Files/` inside the packages folder, and then `z_rearrange_openssl_dirs()` moves them where they belong. Unlike upstream (*[microsoft/vcpkg#52353](https://github.com/microsoft/vcpkg/issues/52353)*), what is left in `Program Files/Common Files/SSL/` (*the configuration files and the empty `certs/` and `private/`*) is removed from the package, except for `openssl.cnf` (*and `fipsmodule.cnf`*) with the `tools` feature, which goes to `tools/openssl/`.

`C:\Program Files\Common Files\SSL` normally does not exist on a target machine, so the default paths find no CA certificates there. The `curl` port uses Schannel (*the Windows certificate store*) by default on Windows, but an application that uses OpenSSL directly has to load a CA bundle of its own (*for example, Mozilla's `cacert.pem` that the curl project distributes*). The same goes for the other targets that have no populated `/etc/ssl`, such as Android and iOS. That is a decision of the application's deployment, not of this port.

#### MinGW

MinGW builds go through `unix/portfile.cmake`, so they get `--openssldir=/etc/ssl` and the `/etc/ssl/...` engines and modules folders compiled in, which on Windows means `\etc\ssl` in the root of the current drive - a folder that any user can create, so it is the same problem as CVE-2026-34054. None of the triplets used with this registry is MinGW, so this is not fixed yet, but it has to be before the port is used with MinGW.

## CMake config without the vcpkg toolchain

The installed `share/openssl/OpenSSLConfig.cmake` is OpenSSL's own config, but `cmake-config.patch` makes it chainload `find_package(OpenSSL MODULE)` (*CMake's `FindOpenSSL.cmake`*), which creates multi-config targets, whereas the original config only knows one set of libraries. `FindOpenSSL.cmake` never looks in `debug/lib` though: on MSVC its `LIB_EAY_DEBUG` / `SSL_EAY_DEBUG` names fall back to plain `libcrypto` / `libssl`, so it takes `lib/libcrypto.lib` for Debug too, and elsewhere it finds one library for all configurations. `vcpkg-cmake-wrapper.cmake` takes care of that by pre-seeding those cache variables from `debug/lib` and `lib` (*and for non-MSVC also the `LIB_EAY_LIBRARY_*` / `SSL_EAY_LIBRARY_*` variables, which `FindOpenSSL.cmake` uses for the targets' `IMPORTED_LOCATION_DEBUG` / `_RELEASE`*), and for static Windows builds it adds `crypt32` and `ws2_32`, which `FindOpenSSL.cmake` adds only with `OPENSSL_USE_STATIC_LIBS`.

But only the vcpkg toolchain runs that wrapper (*its `find_package()` override, and only from the consumer's own `vcpkg_installed`*), so a package consumed without it got release libraries in Debug - for example, the mMap SDK installation copies all the files of its vcpkg ports into its install prefix, and a project using it with `find_package(mMap CONFIG)` (*whose config does `find_dependency(OpenSSL CONFIG)`, like many ports here*) linked a `/MDd` Debug build against the `/MD` release `libcrypto.lib`. That is why `cmake-config.patch` does the same pre-seeding (*and the same `crypt32`/`ws2_32` for `no-shared` builds*) in the config itself, before and after the chainload, using `_ossl_prefix` as the package root. Upstream microsoft/vcpkg does not do that: its `cmake-config.patch` relies on the toolchain. The wrapper part itself is from upstream ([microsoft/vcpkg#54220](https://github.com/microsoft/vcpkg/pull/54220), which extended it from MSVC to non-MSVC multi-config generators such as Xcode and Ninja Multi-Config), so when updating the port from upstream, keep the copy in `cmake-config.patch` in sync with the wrapper. With the toolchain both of them run and set the same values, so that is harmless.

Things to keep in mind:

- `find_library()` does not search again for a cache variable that already holds a found path, so an existing build folder of a consumer keeps the wrong `LIB_EAY_*` / `SSL_EAY_*` values from before the fix until those cache entries are deleted (*or the project is configured from scratch*)
- without the toolchain, a consumer that calls a module-mode `find_package(OpenSSL)` before any config-mode one still gets the plain `FindOpenSSL.cmake` behaviour, because the config is not involved there, and afterwards it returns early, as the targets already exist
- a known upstream quirk of the wrapper: with a non-MSVC multi-config generator, every config-mode `find_package(OpenSSL CONFIG)` after the first one rewrites the already rewritten `OPENSSL_LIBRARIES` (*and `OPENSSL_CRYPTO_LIBRARIES` / `OPENSSL_SSL_LIBRARIES`*) once more, because the config returns early then, but the wrapper does not. That only gives a CMake dev warning (*`Link library type specifier "debug" is followed by specifier "optimized"`*) to a project that links those variables instead of the `OpenSSL::*` targets, and the resulting libraries are still right. It is kept as it is upstream, and the copy in the config does not have it, as it only runs on the first config-mode lookup
