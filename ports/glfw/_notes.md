# Maintainer notes

## System libraries by name

The `002-system-libraries-by-name.patch` fixes linking to system libraries. In `src/CMakeLists.txt` the `rt` and `m` libraries are linked by name instead of the `find_library()` results `${RT_LIBRARY}`/`${MATH_LIBRARY}`, which are absolute paths on the build machine. A static library exports its `PRIVATE` link items, so the exported `glfw3Targets.cmake` had `/usr/lib/librt.a;/usr/lib/libm.so` in it (*3.5.1 built on Arch Linux*), which do not exist on Debian/Ubuntu (*`/usr/lib/x86_64-linux-gnu/`*). The `find_library()` calls stay as the check whether to link them at all. Now the export reads `$<LINK_ONLY:Threads::Threads>;$<LINK_ONLY:rt>;$<LINK_ONLY:m>;$<LINK_ONLY:dl>`

On every update check `src/CMakeLists.txt` for other `find_library()` (*or `find_package()` result variable*) values passed to `target_link_libraries`, as each of them ends up as a build-host path in the exported targets of the static build, and check that `002` still applies. X11 and Wayland libraries are not linked since 3.4 (*GLFW loads them with `dlopen` at runtime*), only their headers are used.
