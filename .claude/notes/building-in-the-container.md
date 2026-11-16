# Building ports in the container

Details behind "Building a port from the working tree" in `CLAUDE.md`.

## Why no registry rewrite is needed

In classic mode with the whole `ports/` as `--overlay-ports`, every port resolves from the working tree, including the host helpers `vcpkg-cmake`, `vcpkg-cmake-config` and `decovar-vcpkg-cmake`, which contain only local files. So vcpkg never contacts `retifrav/vcpkg-registry`, and only the upstream sources need network access. `--binarysource=clear` keeps the scratch builds out of the persistent binary cache in `~/.cache/vcpkg/archives`.

## Finding the orgs to rewrite

The orgs are in the working tree, so grep the portfiles of the port and of every port it pulls in (walk `dependencies` in `vcpkg.json`, including those of the features you enable):

```sh
rg -o --no-filename 'git@github\.com:([^/]+)/' -r '$1' ports/{curl,wolfssl,brotli,zlib,zstd,nghttp2,openssl}/portfile.cmake | sort -u
```

For the curl chain (curl, wolfssl, brotli, zlib, zstd, nghttp2, openssl) that gives `curl wolfSSL google madler facebook nghttp2 openssl`. An unused `insteadOf` entry does nothing, so adding one speculatively is harmless. A missing one fails well into the build, as `vcpkg_execute_required_process` → `git fetch … Error code: 128` inside `vcpkg_from_git`, with the org in the URL it tried.

`vcpkg_from_git` caches each fetched `REF` as `<port>-<REF>.tar.gz` in `~/.cache/vcpkg/downloads/`, which is in the mounted home and survives image rebuilds, and a cached `REF` needs no network at all.

## Measurements

- 2026-11-15: a full static `curl` 8.23.0 with wolfSSL, brotli, zlib and zstd on x64-linux took about a minute.
- 2026-11-16: `xxhash[tool]` with its source already cached took 1.3 s.

## What cannot be built here

`boringssl`: its portfile calls `vcpkg_find_acquire_program(NASM)`, which downloads only on Windows hosts, and the image has no `nasm`. Any feature that depends on it can only be tested host-side.
