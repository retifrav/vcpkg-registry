# vcpkg-registry

My [vcpkg](https://vcpkg.io/) registry. Initially created as an example for [this article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/), but then became an actual registry that I use myself for everyday development.

Although a good portion of the ports here are based on the ports from the [Microsoft's registry](https://github.com/Microsoft/vcpkg), it is not my intention to just duplicate stuff from there, and in many cases those ports have certain modifications.

<!-- MarkdownTOC -->

- [Why not Microsoft's registry](#why-not-microsofts-registry)
- [How to use it](#how-to-use-it)
    - [Installing ports in a dummy project](#installing-ports-in-a-dummy-project)
    - [Resolving dependencies in an actual project](#resolving-dependencies-in-an-actual-project)
    - [Custom triplets](#custom-triplets)
- [Scripts](#scripts)
    - [check-versions-and-hashes](#check-versions-and-hashes)
    - [install-vcpkg-artifacts](#install-vcpkg-artifacts)
    - [vcpkg-assets-caching](#vcpkg-assets-caching)
- [Branches](#branches)
- [Non-development ports](#non-development-ports)

<!-- /MarkdownTOC -->

## Why not Microsoft's registry

Why would one make one's own ports instead of relying on the Microsoft's registry?

I'd say, in most cases one should probably do exactly that - just use the Microsoft's registry as the main source, at the very least because there is unlikely to be a registry bigger than theirs. And since many projects are using it too, it will be easier to collaborate with them, as you'll be in accordance on dependencies sources and applied patches, file names, paths to public headers and so on.

But having been maintaining projects at my place of work and also personal ones for a while, I eventually discovered that I don't always agree on how patching/building/installation is done in some of the ports in the Microsoft's registry. At the same time, not all of my "disagreements" can be proposed as improvements to their registry, because some of those are specific to my particular needs, so they are likely to be of no use for a broader audience. Hence my own registry, where I can do all sorts of crazy things I might need.

## How to use it

It can be used just like any other vcpkg registry, thanks to Microsoft [being very open](https://learn.microsoft.com/en-us/vcpkg/users/registries) about the whole thing.

### Installing ports in a dummy project

As described [in the article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#dummy-installation), create a dummy project:

``` sh
./dummy/
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

You can use custom triplets from the `triplets` folder both with vcpkg tool:

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

### vcpkg-assets-caching

Downloading/uploading vcpkg assets (*required build tools*) from/to a remote cache of HTTP type (*such as JFrog Artifactory*).

More details [here](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/#asset-caching).

## Branches

- `master` - ready to use, tested ports;
- `experimental` - drafts, scraps and experiments, ports from this branch are not done and are unlikely to work.

## Non-development ports

Some ports in this registry aren't "normal" ports, meaning that they are not libraries or tools that are meant to be used in other projects. Instead they are rather build recipes for standalone things such as applications or games. That is probably not something vcpkg was designed to be used for, but who can stop me.

The building procedure for those ports is [the same](#installing-ports-in-a-dummy-project).

One example of such a port is the [reSL](https://github.com/retifrav/vcpkg-registry/tree/master/ports/resl) game. Here's what you'd need to have in your `vcpkg.json` for installing it:

``` json
{
    "dependencies":
    [
        "resl"
    ]
}
```

And then, with Mac OS as an example, you can build and install it either with statically linked dependencies:

``` sh
$ vcpkg install --triplet arm64-osx
```

or with dynamically linked dependencies:

``` sh
$ vcpkg install --triplet arm64-osx-dynamic
```

The game will be deployed to `/path/to/this/dummy/vcpkg_installed/TRIPLET-NAME-HERE/bin/reSL/`, which you can then copy anywhere you want and launch it from there.
