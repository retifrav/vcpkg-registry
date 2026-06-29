# cef

<!-- MarkdownTOC -->

- [Building](#building)
- [Running](#running)
    - [Enabling DevTools](#enabling-devtools)

<!-- /MarkdownTOC -->

## Building

``` sh
$ cd /path/to/vcpkg-registry/tests/cef/
$ cmake --preset vcpkg-default-triplet
$ cmake --build --preset vcpkg-default-triplet
```

## Running

``` sh
$ ./install/vcpkg-default-triplet/bin/cefsimple.app/Contents/MacOS/cefsimple \
    --url=file:///path/to/vcpkg-registry/tests/cef/html/index.html \
    --enable-logging=stderr
```

### Enabling DevTools

Launch with `--remote-debugging-port` and `--remote-allow-origins`:

``` sh
$ ./install/vcpkg-default-triplet/bin/cefsimple.app/Contents/MacOS/cefsimple \
    --url=file:///path/to/vcpkg-registry/tests/cef/html/index.html \
    --enable-logging=stderr \
    --remote-debugging-port=9222 \
    --remote-allow-origins=* \
```

then open <http://127.0.0.1:9222/json> in Chromium, it will display something like:

``` json
[
    {
        "description": "",
        "devtoolsFrontendUrl": "https://chrome-devtools-frontend.appspot.com/serve_rev/@SOME-ID/inspector.html?ws=127.0.0.1:9222/devtools/page/ANOTHER-ID",
        "id": "ANOTHER-ID",
        "title": "Color the rectangle",
        "type": "page",
        "url": "file:///path/to/vcpkg-registry/tests/cef/html/index.html",
        "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/page/ANOTHER-ID"
    }
]
```

where <https://chrome-devtools-frontend.appspot.com/serve_rev/@SOME-ID/inspector.html?ws=127.0.0.1:9222/devtools/page/ANOTHER-ID> is the DevTools page for the application.

Don't know why it goes via internet to launch DevTools, while I am already in Chromium, and the application is running on the same host. Also, it doesn't seem to work all that reliable: connection gets dropped or doesn't get established at all until everything is restarted several times.
