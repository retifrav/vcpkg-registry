# vcpkg-registry

My [vcpkg](https://vcpkg.io/) registry. Initially created as an example for [this article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/), but then became an actual registry that I use myself for everyday development.

A good portion of the ports are either based on or just copies of the ports from the [Microsoft's registry](https://github.com/Microsoft/vcpkg).

<!-- MarkdownTOC -->

- [How to use it](#how-to-use-it)
    - [Installing ports in a dummy project](#installing-ports-in-a-dummy-project)
    - [Resolving dependencies in an actual project](#resolving-dependencies-in-an-actual-project)

<!-- /MarkdownTOC -->

## How to use it

### Installing ports in a dummy project

As described [in the article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#dummy-installation), create a dummy project:

``` sh
./dummy/
├── vcpkg-configuration.json
└── vcpkg.json
```

`vcpkg-configuration.json`:

``` json
{
    "default-registry":
    {
        "kind": "git",
        "repository": "git@github.com:retifrav/vcpkg-registry.git",
        "baseline": "ebee5c267dd774f06967c6459d0c5ae6e74a5033"
    },
    "registries": []
}
```

`vcpkg.json`:

``` json
{
    "name": "some",
    "version": "0",
    "dependencies":
    [
        {
            "name": "curl",
            "features":
            [
                "tool"
            ]
        }
    ],
    "overrides":
    [
        {
            "name": "curl",
            "version": "8.1.2"
        }
    ]
}
```

and then:

``` sh
$ vcpkg install
```

or, if you'd like to specify the triplet:

``` sh
$ vcpkg install --triplet x64-windows-static
```

### Resolving dependencies in an actual project

A CMake project, as described [in the article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#in-a-project):

``` sh
./some-project/
├── src
│   └── ...
├── CMakeLists.txt
├── vcpkg-configuration.json
└── vcpkg.json
```

`vcpkg-configuration.json` (*with Microsoft registry as a secondary source*):

``` json
{
    "default-registry":
    {
        "kind": "git",
        "repository": "git@github.com:retifrav/vcpkg-registry.git",
        "baseline": "ebee5c267dd774f06967c6459d0c5ae6e74a5033"
    },
    "registries":
    [
        {
            "kind": "git",
            "repository": "git@github.com:microsoft/vcpkg.git",
            "baseline": "8b04a7bd93bef991818fc372bb83ce00ec1c1c16",
            "packages":
            [
                "microsoft-signalr"
            ]
        }
    ]
}
```

`vcpkg.json`:

``` json
{
    "name": "some",
    "version": "0",
    "dependencies":
    [
        {
            "name": "curl",
            "features":
            [
                "tool"
            ]
        }
    ],
    "overrides":
    [
        {
            "name": "curl",
            "version": "8.1.2"
        }
    ]
}
```

and then:

``` sh
$ echo $VCPKG_ROOT
$ cd /path/to/some-project
$ mkdir build && cd $_
$ cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET="x64-windows-static" \
    ..
$ cmake --build .
```
