# vcpkg-registry

My [vcpkg](https://vcpkg.io/) registry. Initially created as an example for [this article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/), but then became an actual registry that I use myself for everyday development.

A good portion of the ports here are based on the ports from the [Microsoft's registry](https://github.com/Microsoft/vcpkg). It is not my intention to just duplicate stuff from there, and in most cases there are certain modifications of the original ports (*tailored to my needs*).

<!-- MarkdownTOC -->

- [Why not Microsoft's registry](#why-not-microsofts-registry)
- [How to use it](#how-to-use-it)
    - [Installing ports in a dummy project](#installing-ports-in-a-dummy-project)
    - [Resolving dependencies in an actual project](#resolving-dependencies-in-an-actual-project)
    - [Custom triplets](#custom-triplets)
- [Scripts](#scripts)
    - [check-versions-and-hashes](#check-versions-and-hashes)
    - [install-vcpkg-artifacts](#install-vcpkg-artifacts)

<!-- /MarkdownTOC -->

## Why not Microsoft's registry

Why would one make one's own ports instead of relying on the Microsoft's registry?

I'd say, in most cases one should probably do exactly that - just use the Microsoft's registry as the main source, at the very least because there is unlikely to be a registry bigger than theirs. And since many projects are using it too, it will be easier to collaborate with them, as you'll be in accordance on dependencies sources and applied patches, file names, paths to public headers and so on.

But working on my projects at work and also on personal ones, I eventually discovered that I don't always agree on the ways some dependencies are patched/built/installed in the Microsoft's registry ports. At the same time, not all of my "disagreements" could be proposed as pull-requests to their repository, because some of those are specific to my particular needs (*and so of no use for a broader audience*). Hence my own registry, where I can do all sorts of crazy things I might need.

## How to use it

It can be used just like any other vcpkg registry, thanks to Microsoft [being very open](https://learn.microsoft.com/en-us/vcpkg/users/registries) about the whole thing.

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
    ..
$ cmake --build .
```

### Custom triplets

You can use custom triplets from `triplets` folder both with vcpkg tool:

``` sh
$ vcpkg install \
    --overlay-triplets /path/to/vcpkg-registry/triplets \
    --triplet decovar-x64-windows-static-md-clang
```

and with CMake:

``` sh
$ cd /path/to/some-project
$ mkdir build && cd $_
$ cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_OVERLAY_TRIPLETS="/path/to/vcpkg-registry/triplets" \
    -DVCPKG_TARGET_TRIPLET="decovar-x64-windows-static-md-clang" \
    ..
$ cmake --build .
```

## Scripts

### check-versions-and-hashes

Checks that declared rev-parse hashes in ports versions match their actual values:

``` sh
$ cd /path/to/vcpkg-registry
$ ./scripts/check-versions-and-hashes.sh
```

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#checking-versions-and-hashes).

### install-vcpkg-artifacts

Merges vcpkg installation with project installation:

``` sh
$ cd /path/to/project
$ python /path/to/vcpkg-registry/scripts/install-vcpkg-artifacts.py \
    --cmake-preset vcpkg-default-triplet \
    --vcpkg-triplet arm64-osx \
    --blacklist "vcpkg-cmake,json-nlohmann"
```

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#distributing-your-project).
