# vcpkg-registry

My [vcpkg](https://vcpkg.io/) registry. Initially created as an example for [this article](https://decovar.dev/blog/2022/10/30/cpp-dependencies-with-vcpkg/), but then became an actual registry that I use myself for everyday development.

A good portion of the ports are either based on or just copies of the ports from the [Microsoft's registry](https://github.com/Microsoft/vcpkg).

## An example of installing a port

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
