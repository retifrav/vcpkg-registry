# cef

<!-- MarkdownTOC -->

- [Building](#building)
- [Running](#running)
    - [Disabling sandbox](#disabling-sandbox)
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

On Windows there will be no output printed from C++ side, probably because it builds as a GUI applications with no console attached, but C++ code does execute, and JS side gets results from C++ sides.

### Disabling sandbox

Trying to launch on Linux you might get this error:

``` sh
[FATAL:sandbox/linux/suid/client/setuid_sandbox_host.cc:166] The SUID sandbox helper binary was found, but is not configured correctly. Rather than run without sandboxing I'm aborting now. You need to make sure that /path/to/vcpkg-registry/tests/cef/install/vcpkg-default-triplet/bin/cefsimple/chrome-sandbox is owned by root and has mode 4755.
```

If you do want to have sandbox enabled, try setting the required ownership and permissions on the `chrome-sandbox` file:

``` sh
$ cd /path/to/vcpkg-registry/tests/cef/install/vcpkg-default-triplet/bin/cefsimple/
$ sudo chown root:root ./chrome-sandbox
$ sudo chmod 4755 ./chrome-sandbox
```

Or you can just disable sandbox by launching the application with `--no-sandbox`:

``` sh
$ ./install/vcpkg-default-triplet/bin/cefsimple/cefsimple --no-sandbox
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
