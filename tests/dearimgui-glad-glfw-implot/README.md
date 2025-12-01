# dearimgui-glad-glfw-implot

Testing vcpkg ports for [Dear ImGui](https://github.com/ocornut/imgui), [glad](https://github.com/Dav1dde/glad), [GLFW](https://glfw.org) and [ImPlot](https://github.com/epezent/implot).

## Building and running

``` sh
$ cd /path/to/dearimgui-glad-glfw-implot

$ cmake --preset vcpkg-default-triplet
$ cmake --build --preset vcpkg-default-triplet

$ echo 'In case of SHARED builds you might need to handle runtime dependencies'
$ ./install/vcpkg-default-triplet/bin/dearimgui-glad-glfw-implot
```
