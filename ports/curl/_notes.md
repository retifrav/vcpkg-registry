# Maintainer notes

## wolfSSL BIO retry flags

`002-wolfssl-bio-retry-flags.patch` works around a bug in `lib/vtls/wolfssl.c`, which is still there in upstream `master` as of `337ec0c3d5601437125e667bebe609e14a9d6065` (*2026-11-16*), so check it on every update and drop the patch once upstream has fixed it.

cURL gives wolfSSL its own BIO, and on `CURLE_AGAIN` that BIO sets the retry flags (*`wolfSSL_BIO_set_retry_read()`/`wolfSSL_BIO_set_retry_write()`*), but it clears them (*`wolfSSL_BIO_clear_retry_flags()`*) only when `USE_FULL_BIO` is defined. That one depends on `HAVE_WOLFSSL_BIO_SET_SHUTDOWN`, and `wolfSSL_BIO_set_shutdown()` (*as well as `wolfSSL_BIO_clear_retry_flags()`*) is only compiled with `OPENSSL_ALL`, while the `wolfssl` port has `WOLFSSL_OPENSSLEXTRA` but not that. So once the flags are set, they stay set, and then wolfSSL reports any later failure of the BIO, such as a connection reset or a closed connection, as `WOLFSSL_ERROR_WANT_READ`. cURL keeps calling `wolfSSL_connect()` in a busy loop at 100% CPU until the timeout and fails with `28` (*`CURLE_OPERATION_TIMEDOUT`*) instead of `35` (*`CURLE_SSL_CONNECT_ERROR`*) right away, and without an explicit timeout that takes up to 300 seconds (*libcurl's default connect timeout*). It happens with wolfSSL `5.8.4` and `5.9.4` alike.

The patch clears the flags with `wolfSSL_BIO_clear_flags()`, which is available without `OPENSSL_ALL`, in the `#else` branches of both `wssl_bio_cf_out_write()` and `wssl_bio_cf_in_read()`. With `USE_FULL_BIO` defined (*if the `wolfssl` port ever gets `OPENSSL_ALL`*) it does nothing.

It showed up in `tests/curl/test-curl-tool.sh` as badssl.com checks failing with `curl: (28) Recv failure: Connection reset by peer` after the full timeout, when wolfSSL `5.9.4` had ML-KEM enabled by default (*see the `WOLFSSL_MLKEM` comment in the `wolfssl` portfile*) and badssl.com was resetting some of the connections with its larger ClientHello. Note that the error message is right and only the exit code is wrong, because the message comes from the socket filter, before wolfSSL turns the failure into `WANT_READ`.

To check whether the patch is still needed, build the port without it and point the tool at a local server that resets the connection as soon as it gets the ClientHello:

``` sh
$ python3 -c "
import socket, struct
s = socket.create_server(('127.0.0.1', 4434))
c, _ = s.accept()
c.recv(65536)
c.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack('ii', 1, 0))
c.close()
" &
$ time ./curl -sS -m 4 -o /dev/null --connect-to x.test:443:127.0.0.1:4434 https://x.test/; echo "exit $?"
```

With the bug it takes the whole 4 seconds (*with `user` + `sys` time close to `real`*) and exits with `28`, without the bug it exits with `35` in a few milliseconds. With `--trace-config ssl` the bug shows as `wolfSSL_connect() -> -1, detail=2` repeating hundreds of thousands of times after `bio_read(len=5) -> 56, 0`.
