# Maintainer notes

## Pre-built binaries and ugly structure

Given the nature of the original CEF package, its vcpkg port ended up being a perversion too. For instance, the actual CEF libraries/frameworks (*not the wrapper*) are installed into `/path/to/vcpkg_installed/VCPKG-TRIPLET/share/cef/cef-root/{Debug,Release}`, while the package (*not the wrapper*) discovery happens in a some god-awful manner with the weirdest `Find*.cmake` module that you have ever seen.

That said, thanks a lot to Spotify for hosting (*and building/packing?*) the [CEF packages](https://cef-builds.spotifycdn.com/index.html). Without those making this port (*building the entire CEF from sources*) would be close to impossible.
