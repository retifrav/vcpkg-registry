# Maintainer notes

## Which commit to use for a new version

It would probably be okay to just take the latest to the date commit from `main` branch, but just in case it is better to pick the lastest from one of the recent `chromium` branches. For example, on 2026-04-20 the most fresh branch was `chromium/7802`, from which the commit hash was `afd3d886e5dca11c148021ea7ccf0f221c3abb2e`.

## Dawn and tint relations

It appears that on desktop one would like to build and link both Dawn and tint (*because debugging WebGPU in "native" environment is easier*). For web, however, one technically would only need the GLSL-to-WGSL transpiler (*which is tint*), because Dawn is already built into Chrome, and any WebGPU function called from Emscripten calls directly into Chrome and not Dawn.

Even better would be to just have Dawn/WGPU (*Chrome/Firefox*) transpile shaders, so one would not need to include a transpiler in one's build, but that wasn't possible before (*and probably still isn't now*).

## Figuring out features

It isn't(?) trivial to determine the right set of default features, as they differ per platform. I would probably suggest doing so via `features`/`default-features` in the project's `vcpkg.json`:

``` json
{
    "dependencies": [],
    "default-features":
    [
        "webgpu"
    ],
    "features":
    {
        "webgpu-with-vulkan":
        {
            "description": "WebGPU capabilities with Vulkan",
            "dependencies":
            [
                {
                    "name": "dawn",
                    "features":
                    [
                        "glsl-writer",
                        "spv-reader",
                        "spv-writer",
                        "vulkan",
                        "wgsl-reader",
                        "wgsl-writer"
                    ],
                    "platform": "linux"
                },
                {
                    "name": "dawn",
                    "features":
                    [
                        "glsl-writer",
                        "hlsl-writer",
                        "spv-reader",
                        "spv-writer",
                        "vulkan",
                        "wgsl-reader",
                        "wgsl-writer"
                    ],
                    "platform": "windows & !uwp"
                }
            ]
        },
        "webgpu":
        {
            "description": "WebGPU capabilities",
            "dependencies":
            [
                {
                    "name": "dawn",
                    "features":
                    [
                        "glsl-writer",
                        "spv-reader",
                        "wgsl-reader",
                        "wgsl-writer"
                    ],
                    "platform": "linux"
                },
                {
                    "name": "dawn",
                    "features":
                    [
                        "glsl-writer",
                        "hlsl-writer",
                        "spv-reader",
                        "wgsl-reader",
                        "wgsl-writer"
                    ],
                    "platform": "windows & !uwp"
                },
                {
                    "name": "dawn",
                    "features":
                    [
                        "msl-writer",
                        "spv-reader",
                        "wgsl-reader",
                        "wgsl-writer"
                    ],
                    "platform": "osx"
                },
                {
                    "name": "dawn",
                    "features":
                    [
                        "spv-reader",
                        "wgsl-writer"
                    ],
                    "platform": "emscripten"
                }
            ]
        }
    }
}
```
