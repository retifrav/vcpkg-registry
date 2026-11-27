# Maintainer notes

## Names

Upstream's project is called `cpp-httplib` (*and so is the port in microsoft/vcpkg*), while this port is `cpp-http`, and what consumers use is named after the port:

- the CMake package is `cpp-http` and the target is `cpp-http::cpp-http` (*upstream: `httplib` and `httplib::httplib`*)
- the header is installed into `include/cpp-http/`, so it is included as `<cpp-http/httplib.h>` (*upstream: `<httplib.h>`*)

## Features

The library is header-only, so a feature does not change what gets compiled here, it only adds a dependency, a `CPPHTTPLIB_*_SUPPORT` compile definition and the libraries to link to the exported target:

- `brotli`, `zlib` and `zstd` (*all three are default features*) set `HTTPLIB_REQUIRE_BROTLI`, `HTTPLIB_REQUIRE_ZLIB` and `HTTPLIB_REQUIRE_ZSTD`
- `openssl` sets `HTTPLIB_REQUIRE_OPENSSL`

Every `HTTPLIB_USE_*_IF_AVAILABLE` option is set to `0` in `portfile.cmake`. Upstream has four of them enabled by default (*OpenSSL, zlib, Brotli and zstd*), and those would make the result depend on what happens to be installed.

OpenSSL is the only TLS back end. There is no MbedTLS port in this registry, and for wolfSSL see [below](#wolfssl).

## Patch

`001-dependencies-and-installation.patch` is made against upstream's `CMakeLists.txt` and `httplib.h`, and it has to keep these properties when it is rebased onto a new upstream version:

- the project is renamed to `cpp-http`: the target, the package and the folder for the header all come from `PROJECT_NAME`
- in the `HTTPLIB_REQUIRE_*` branches the dependencies are found in CONFIG mode by the names of this registry: `find_package(OpenSSL CONFIG REQUIRED)`, `find_package(zlib CONFIG REQUIRED)`, `find_package(brotli CONFIG REQUIRED)` and `find_package(zstd CONFIG REQUIRED)` (*the latter replaces upstream's check for the `zstd::libzstd` target with its pkg-config fallback*)
- the target links `brotlicommon`, `brotlienc`, `brotlidec`, `zlib::zlib` and `zstd::zstd` (*upstream: `Brotli::common`, `Brotli::encoder`, `Brotli::decoder`, `ZLIB::ZLIB` and `zstd::libzstd`*). The OpenSSL targets have the same names in both
- `httplib.h` includes `<zlib/zlib.h>` and `<zstd/zstd.h>`, which is where the `zlib` and `zstd` ports install their headers. The Brotli and OpenSSL headers are where upstream expects them
- upstream's installation (*everything from `_TARGET_INSTALL_CMAKEDIR` to the end of the `if(HTTPLIB_INSTALL)` block*) is replaced with the common `Installing.cmake` from `decovar-vcpkg-cmake` and one `install(FILES)` for the header. The config comes from `Config.cmake.in` of this port, which `portfile.cmake` copies into the sources. So the `HTTPLIB_INSTALL` option does nothing, and nothing of this gets installed: upstream's `httplibConfig.cmake` (*with its `HTTPLIB_IS_USING_*`, `HTTPLIB_HEADER_PATH` and other variables, and the `OpenSSL`/`ZLIB`/`Brotli`/`zstd` components*), `FindBrotli.cmake`, the README and the CPack setup
- the `CFNetwork` and `CoreFoundation` frameworks for the non-blocking `getaddrinfo()` are linked on every Apple platform (*`$<BOOL:${APPLE}>`*) and not only on Mac OS (*upstream: `$<PLATFORM_ID:Darwin>`*), because `httplib.h` uses `CFHost` under `TARGET_OS_MAC`, which is also set on iOS. **That was never built**, the hunk is written from reading the code, so it is the first thing to look at if an Apple build has trouble with linking

Deliberately not patched, because `portfile.cmake` turns all of that off:

- the `HTTPLIB_USE_*_IF_AVAILABLE` branches, which still look for upstream's package and target names (*a plain `find_package(OpenSSL …)` among them, which is never reached*)
- the wolfSSL and MbedTLS lookups
- the `HTTPLIB_COMPILE` branch, which splits the header into a compiled library with `split.py` (*requires Python*) and names it `cpp-httplib`, and the C++ modules that depend on it (*`HTTPLIB_BUILD_MODULES`, `cmake/modules.cmake`*). Its `INSTALL_INTERFACE` still points at `include/httplib.h`
- `test/`: it links a target called `httplib`, requires GTest and CURL, downloads googletest when it is not found and adds the fuzzing subdirectory. The port had a `tests` feature for it up to 0.15.3, which could not have linked after the project got renamed

`portfile.cmake` also deletes `cmake/FindBrotli.cmake`, so that nothing can fall back to it.

There is no `CMAKE_DEBUG_POSTFIX` as in the other ports, since nothing is compiled, and for the same reason the port builds the release configuration only.

## wolfSSL

Upstream supports wolfSSL as a TLS back end (*`HTTPLIB_REQUIRE_WOLFSSL`, `CPPHTTPLIB_WOLFSSL_SUPPORT`*), and its README says that wolfSSL "must build with `--enable-opensslall`". The `wolfssl` port sets `WOLFSSL_OPENSSLEXTRA` only, and that turned out not to be enough. Tried on 2026-11-27 with cpp-httplib 0.67.0 and `wolfssl` 5.9.4#1 on x64-linux:

- with the port as it is, a consumer does not compile: `httplib.h` calls `wolfSSL_CTX_get_ex_new_index()` and `wolfSSL_get_ex_new_index()`, which `wolfssl/ssl.h` declares only under `HAVE_EX_DATA_CRYPTO`. `wolfssl/wolfcrypt/settings.h` defines that for `OPENSSL_ALL` (*and for a few application bundles*) but not for `OPENSSL_EXTRA`, and `libwolfssl.a` has neither function. These two were the only errors
- with `OPENSSL_ALL` everything worked. `wolfssl[asio]` happens to enable `WOLFSSL_OPENSSLALL`, and against that a consumer compiled, linked with `-fkeep-inline-functions` (*GCC then emits every inline function of the header, so every wolfSSL function it refers to anywhere has to exist in the library*) and passed the HTTPS checks listed [below](#to-check-on-every-update)

So a `wolfssl` feature needs `WOLFSSL_OPENSSLALL=yes` in the `wolfssl` port first, which is a change for every consumer of that port, `curl` included. With that in place the feature would take:

- in the patch: `find_package(wolfssl CONFIG REQUIRED)` in the `HTTPLIB_REQUIRE_WOLFSSL` branch (*the target is `wolfssl::wolfssl` in both*), and `HTTPLIB_IS_USING_WOLFSSL` next to `HTTPLIB_IS_USING_OPENSSL` in the condition for the Keychain frameworks on Mac OS, as `httplib.h` reads the Keychain with any back end, while upstream links `Security` only with OpenSSL (*again from reading the code*)
- `find_dependency(wolfssl CONFIG REQUIRED)` under `"@HTTPLIB_IS_USING_WOLFSSL@"` in `Config.cmake.in`
- in `portfile.cmake`: `wolfssl HTTPLIB_REQUIRE_WOLFSSL` in `vcpkg_check_features()` instead of the explicit `-DHTTPLIB_REQUIRE_WOLFSSL=0`, and an error for `openssl` together with `wolfssl`, as upstream allows only one TLS back end (*otherwise it fails later with "TLS libraries are mutually exclusive"*)

## What has changed for consumers since 0.15.3

Apart from the features (*Brotli and zlib used to be unconditional dependencies, and zstd and OpenSSL were not available*):

- Windows 10 is the minimum: `httplib.h` has an `#error` for `_WIN32_WINNT` below `0x0A00`
- OpenSSL 3.0 is the minimum, also with an `#error`. The oldest `openssl` in this registry is 3.1.4, hence no `version>=` in the manifest
- upstream's README declares 32-bit platforms unsupported (*"use at your own risk"*)
- `CPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO` is defined, as `HTTPLIB_USE_NON_BLOCKING_GETADDRINFO` is on by default: name resolution with a connection timeout goes through `GetAddrInfoExW()` on Windows, `CFHost` on Apple platforms and `getaddrinfo_a()` with glibc. The latter has been a part of libc itself since glibc 2.34 (*a consumer built in the Debian 13 container refers to `getaddrinfo_a@GLIBC_2.34`*), and before that it was in `libanl`, which upstream's CMake does not link
- the version file is `AnyNewerVersion`, as written by `Installing.cmake` (*upstream: `SameMinorVersion`, so `find_package(cpp-http 0.15 CONFIG)` no longer fails with a newer minor version*)

## To check on every update

- the option list at the top of upstream's `CMakeLists.txt` against `portfile.cmake`: a new `HTTPLIB_USE_*_IF_AVAILABLE` has to be turned off there, and a new back end is either a feature or turned off too
- the `target_link_libraries()` and `target_compile_definitions()` blocks, for new libraries and for new conditions on the platform ones (*`ws2_32`, `crypt32`, the Apple frameworks*)
- third-party `#include`s in `httplib.h` (*`rg -n '^#include <(zlib|zstd|brotli|openssl|wolfssl|mbedtls|psa)' httplib.h`*), for headers that this registry installs elsewhere
- whether the patch still applies the way vcpkg applies it: `git apply --check --ignore-whitespace`. Upstream's files have tabs and LF line endings, and the patch was made with `git diff` in a clone, so it has exact context
- the port in microsoft/vcpkg. It was last compared at 0.67.0, where its only patch was `fix-find-brotli.patch` (*Brotli from the `unofficial-brotli` config and no `FindBrotli.cmake` in the package*), which this patch covers in its own way. It also has `brotli` as its only default feature and no TLS back end other than OpenSSL
- a build of `cpp-http`, `cpp-http[core]` and `cpp-http[openssl]`, and a consumer for each, with the vcpkg toolchain and with a bare `CMAKE_PREFIX_PATH`. With 0.67.0 the consumer was a server and a client in one process on a port of `127.0.0.1`, and it checked the following:
    - for each of `gzip`, `br` and `zstd` in `Accept-Encoding`: `Content-Encoding` and a compressed body with decompression turned off in the client, and the original body with it turned on. With `[core]` the response is not encoded at all
    - a request by host name with a connection timeout, which is what takes the non-blocking `getaddrinfo()` path
    - with `[openssl]`, the same over an `SSLServer` with a certificate issued by a local CA for `DNS:localhost` and `IP:127.0.0.1`: requests by that name and by that address succeed with the CA set in the client, a host name that is not in the certificate and a client without the CA are both rejected, and a request with the verification turned off succeeds
    - with `[openssl]`, a request to a public host, which is verified against the system trust store
    - with `[openssl]`, a link with `-fkeep-inline-functions`
