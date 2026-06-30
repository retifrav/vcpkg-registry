# Maintainer notes

## Pre-built binaries and ugly structure

Given the nature of the project (*an abomination*), its vcpkg port ended up
being a perversion too. For instance, the actual CEF libraries/frameworks (*not the wrapper*)
are installed into `/path/to/vcpkg_installed/VCPKG-TRIPLET/share/cef/cef-root/{Debug,Release}`, while the package (*not the wrapper*) discovery happens in a god-awful manner with the weirdest `FindCEF.cmake` module that you have ever seen.
