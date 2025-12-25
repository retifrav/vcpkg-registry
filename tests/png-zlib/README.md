# png-zlib

## Building and running

``` sh
$ cd /path/to/png-zlib/
 
$ cmake --preset vcpkg-default-triplet
$ cmake --build --preset vcpkg-default-triplet

$ cd ./install/vcpkg-default-triplet/bin/
$ echo 'In case of SHARED builds you might need to handle runtime dependencies'
$ ./some
1025x289
```

