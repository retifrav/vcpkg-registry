# Maintainer notes

## Windows is not supported

The Windows platform is excluded from supported ones, because one of its dependencies - `pmc` - does not support building on Windows.

## Using a fork of tinyply

The original project in that version [uses](https://github.com/MIT-SPARK/TEASER-plusplus/blob/9ca20d9b52fcb631e7f8c9e3cc55c5ba131cc4e6/cmake/tinyply.CMakeLists.txt.in#L7) a fork of tinyply, but later they switched to the original(?) [tinyply](https://github.com/ddiakopoulos/tinyply), and actually is seems to be already compatible in the current version, so this port uses the original one.
