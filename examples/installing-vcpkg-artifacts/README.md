# installing-vcpkg-artifacts

The `prjct` is used to demonstrate merging of vcpkg-resolved dependencies artifacts into the project installation using [install-vcpkg-artifacts.py](../../scripts/install-vcpkg-artifacts.py) script, and `tl` project plays the role of a consuming project that should be able to configure and build using the `prjct` installation path provided in `CMAKE_PREFIX_PATH`.
