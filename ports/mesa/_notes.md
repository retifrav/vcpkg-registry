# Maintainer notes

At the moment this port is used only for getting the SpirvToDxil library (*the `spirv-to-dxil` default feature*). No Gallium or Vulkan drivers are built (*`-Dgallium-drivers=[]` and `-Dvulkan-drivers=[]`*), and neither are other features (*`opengl`, `gles1`, `gles2`, `egl`, `offscreen`*).

## No feature auto-discovery

Mesa's Meson build looks up the dependency of every `auto` feature option and enables the feature when the dependency is found. In a vcpkg build that lookup sees the whole installed tree (*`pkg-config` and `cmake_prefix_path` both point there*), so without precautions the result depends on whatever other ports happen to be installed alongside, and the vcpkg ABI hash of this port knows nothing about it - a binary-cached package built in one project can then carry a dependency that another project restoring it does not have. That is why the `portfile.cmake` passes `-Dauto_features=disabled`: every `auto` feature becomes `disabled`, and only the options that the `portfile.cmake` sets explicitly are enabled.

The problem that brought this up was SPIRV-Tools, which gets into a consumer's installed tree via `glslang`, `tint` or `dawn`. When Mesa found it, `libvtn` (*the SPIR-V to NIR frontend that `spirv_to_dxil` links*) was compiled with `HAVE_SPIRV_TOOLS`, and `spirv_to_dxil` ended up referencing `spv*` symbols, which consumers then had to resolve by linking SPIRV-Tools themselves. SPIRV-Tools is redundant for `spirv_to_dxil`: its only use is `spirv_print_asm()` in `src/compiler/spirv/vtn_debug.c`, which disassembles the input shader when `MESA_SPIRV_DEBUG=asm` is set (*without SPIRV-Tools it prints a "Cannot dump SPIR-V assembly" message instead*), and nothing in `src/microsoft/` uses it. It is disabled explicitly with `-Dspirv-tools=disabled` too, so that it stays disabled even if `auto_features` is ever dropped.

What `spirv_to_dxil` links, as of `26.1.1`:

- `src/microsoft/spirv_to_dxil/meson.build` - `idep_nir`, `idep_vtn`, `idep_libdxil_compiler`
- `src/microsoft/compiler/meson.build` - `idep_nir_headers`, `dep_valgrind`, `idep_mesautil`, `dep_version`
- `src/compiler/spirv/meson.build` - `dep_spirv_tools`, `idep_nir`, `idep_mesautil`, `dep_valgrind`
- `src/compiler/nir/meson.build` and `src/compiler/meson.build` - `idep_compiler`, `idep_mesautil`, `dep_valgrind`
- `src/util/meson.build` - `deps_for_libmesa_util`: `dep_zlib`, `dep_zstd`, `dep_valgrind`, `dep_unwind`, plus `dep_libdrm` when found (*never on Windows*), perfetto, gpuvis and sysprof when their boolean options are set (*all `false` by default*), and system libraries (*`dep_clock`, `dep_thread`, `dep_atomic`, `dep_m`, `dep_dl`, `dep_futex`*)

So the only external libraries that can get into `spirv_to_dxil` are:

| Dependency | Mesa option | Default | In this port |
|------------|-------------|---------|--------------|
| SPIRV-Tools | `spirv-tools` | `auto` | disabled, redundant (*see above*) |
| libunwind | `libunwind` | `auto` | disabled by `auto_features`, used only for debug backtraces (*`src/util/u_debug_stack.c`*) |
| valgrind | `valgrind` | `auto` | disabled |
| zlib | `zlib` | `enabled` | the `zlib` feature, disabled by default |
| zstd | `zstd` | `auto` | the `zstd` feature, disabled by default |

Neither zlib nor zstd is needed for `spirv_to_dxil` on Windows. Both are used for compression in `src/util/compress.c`, which is wrapped entirely in `HAVE_COMPRESSION`, and the only user of that is the shader cache, which Mesa always disables on Windows (*`get_option('shader-cache').require(host_machine.system() != 'windows')`*). The only other zlib use is `util_hash_crc32()` in `src/util/crc32.c`, which falls back to its own table without `HAVE_ZLIB`. Until `26.1.1#4` zlib was a mandatory dependency of the port; the zlib-related hunks of `001-dependencies.patch` are still there and only matter with the `zlib` feature enabled.

Other dependencies that Mesa looks up (*expat, libva, lua, libelf, libudev, DirectX-Headers and so on*) can still show up as found in the configuration log, either because they are looked up with `required : false` regardless of any option, or because they belong to other components - but they are not linked into `spirv_to_dxil`.

## Build tools

The Flex and Bison tools are acquired only with the `opengl`, `gles1` or `gles2` features. Mesa requires them when `needs_flex_bison` in its `meson.build` is true, which is `with_any_opengl or with_freedreno_vk or with_intel_tools or with_gallium` as of `26.1.1` - they generate the GLSL compiler, glcpp and `src/mesa/program` parsers, the Intel and Freedreno assemblers. This port has no Gallium or Vulkan drivers and does not pass `-Dtools`, so `with_any_opengl` (*`opengl`, `gles1` or `gles2`*) is the only part of it that applies here. Should the port ever enable Gallium drivers (*`-Dgallium-drivers`*) or Mesa tools (*`-Dtools`*), the condition in `portfile.cmake` has to be extended.

## Updating to a new version

Check that the above still holds:

1. Look through the `dependencies :` of the files listed above, and `deps_for_libmesa_util` in particular, for new external dependencies;
2. Compare `meson.options` with the previous version for new `auto` features: they are disabled now, so a new one that `spirv_to_dxil` actually needs has to be enabled explicitly in the `portfile.cmake`;
3. Check that `needs_flex_bison` in `meson.build` still matches the condition for acquiring flex and bison in the `portfile.cmake`, see [build tools](#build-tools);
4. After building, check `buildtrees/mesa/config-<triplet>-rel-out.log` (*and `-dbg-`*) for `Run-time dependency ... found: YES` lines, and the installed `spirv_to_dxil.lib` for undefined symbols of libraries that the port does not depend on (*for example, with `dumpbin /symbols`*).
