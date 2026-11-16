# wolfSSL and curl TLS behaviour

Evidence behind the wolfSSL rules in `CLAUDE.md`. The current configuration is explained in the comments of `ports/wolfssl/portfile.cmake`, and the curl BIO retry-flags bug (exit `28` instead of `35`) in `ports/curl/_notes.md`; neither is repeated here.

## Defines have to reach `wolfssl/options.h`

wolfSSL's CMake build generates `wolfssl/options.h` from the fixed template `cmake/options.h.in`, driven only by CMake variables (`WOLFSSL_DEFINITIONS`). A define passed as a raw compiler flag gets compiled into the library but never reaches that header, and the template writes `#undef X` for every entry it knows, so consumers see the define as actively undefined. Some defines (`WOLFSSL_CUSTOM_OID`) are not in the template at all. Hence `WOLFSSL_DEFINES_WITHOUT_OPTION` in the portfile: those are passed as flags *and* appended as `#undef`/`#define` pairs before `#endif /* WOLFSSL_OPTIONS_H */` in the installed header, and the portfile fails hard if that anchor is missing.

Up to 5.8.4 the port passed 13 defines as raw flags. In curl the visible effect was that `lib/vtls/wolfssl.c` compiled out its session cache (`#ifdef HAVE_EX_DATA`) and its `SSLKEYLOGFILE` support (`#ifdef HAVE_SECRET_CALLBACK`). This was fixed in the 5.9.4 update (`b4318d3`; an earlier, amended copy of that commit, `cb0002a`, is not on any branch). The fix was verified as follows:

- the exported symbols of `libwolfssl.a` were identical before and after
- curl TLS 1.2 sessions showed `Reused` against a local `openssl s_server -www -naccept 2`
- `wolfssl[secret-callback]` made curl write the 4 TLS 1.3 keylog lines

To check what consumers see, preprocess the installed headers the way a consumer would:

```sh
printf '#include <wolfssl/options.h>\n#include <wolfssl/ssl.h>\n' | gcc -E -dM -x c -I<installed>/<triplet>/include - | rg 'HAVE_EX_DATA|HAVE_SECRET_CALLBACK'
```

## Session tickets

`WOLFSSL_SESSION_TICKET=yes` is unconditional at the user's request (before 5.9.4 only the `quic` feature enabled it), because TLS 1.3 sessions can only be resumed with tickets. Tickets also need `WOLFSSL_TICKET_NONCE_MALLOC=yes`. Without it, a NewSessionTicket nonce over 8 bytes (TLS 1.3 allows up to 255) makes `wolfSSL_read` fail the whole connection with `INVALID_PARAMETER` ("The security parameter is invalid", curl exit `56`). That broke 29 of the 46 `tests/curl/test-curl-tool.sh` checks at the time, all of them against httpbingo.org. autoconf's `--enable-curl` sets it implicitly, but the CMake `WOLFSSL_CURL` bundle does not. With both options, TLS 1.3 resumes against httpbingo.org, github.com, facebook.com, nghttp2.org and curl.se.

When checking TLS behaviour by hand, look at curl's exit code and not only the `-v` output: the verbose log still shows a completed handshake when the connection fails afterwards.

## ML-KEM and badssl.com resets

Diagnosed on 2026-11-16, after the 5.9.4 update made 2-3 `test-curl-tool.sh` checks fail. They were always badssl.com ones (expired, self-signed, untrusted-root, wrong.host, `-k`), failing with `curl: (28) Recv failure: Connection reset by peer` after the full 20 s.

- The wolfSSL 5.9.x CMake default of `WOLFSSL_MLKEM` flipped from `no` to `yes`, although the option text still says "default: disabled", and `WOLFSSL_PQC_HYBRIDS` defaults to on. The ClientHello grew from 283 to about 1490 bytes, with `SecP256r1MLKEM768` as its only key share.
- badssl.com (TLS 1.2 only, 104.154.89.105 at the time) intermittently resets large ClientHellos from any client:

  | client | resets |
  |---|---|
  | wolfSSL | 7 of 12 |
  | system curl with OpenSSL 3.5 (`X25519MLKEM768`) | 2 of 12 |
  | any client with a small ClientHello | 0 of 24 |

  `--curves P-256:P-384:P-521` on the same binary gave 12 of 12 clean runs, and `-DWOLFSSL_MLKEM=no`, which the port now sets, made the suite pass 48 of 48 twice.
- The exit code `28` instead of `35` was a separate, pre-existing bug, see `ports/curl/_notes.md`.

To measure a client's ClientHello, capture it with a local listener. Verified 2026-11-16 with the container's `/usr/bin/curl`, which sent 1578 bytes:

```sh
nc -l 127.0.0.1 4435 > <scratch>/hello.bin & ncPid=$!
<curl> -sS -m 2 -o /dev/null --connect-to expired.badssl.com:443:127.0.0.1:4435 https://expired.badssl.com/
kill $ncPid; wc -c < <scratch>/hello.bin   # bytes 4-5 (od -An -tx1 -N6) are the TLS record length
```
