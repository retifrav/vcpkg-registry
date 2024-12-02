# Maintainer notes

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
                    "features": [ "vulkan", "spv-reader", "wgsl-writer", "wgsl-reader", "glsl-writer", "spv-writer" ],
                    "platform": "linux"
                },
                {
                    "name": "dawn",
                    "features": [ "vulkan", "spv-reader", "wgsl-writer", "wgsl-reader", "glsl-writer", "spv-writer", "hlsl-writer" ],
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
                    "features": [ "spv-reader", "wgsl-writer", "wgsl-reader", "glsl-writer" ],
                    "platform": "linux"
                },
                {
                    "name": "dawn",
                    "features": [ "spv-reader", "wgsl-writer", "wgsl-reader", "glsl-writer", "hlsl-writer" ],
                    "platform": "windows & !uwp"
                },
                {
                    "name": "dawn",
                    "features": [ "spv-reader", "wgsl-writer", "wgsl-reader", "msl-writer" ],
                    "platform": "osx"
                },
                {
                    "name": "dawn",
                    "features": [ "spv-reader", "wgsl-writer" ],
                    "platform": "emscripten"
                }
            ]
        }
    }
}

```
