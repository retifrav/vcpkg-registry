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

## Large ClientHellos and badssl.com resets

badssl.com (TLS 1.2 only, 104.154.89.105) intermittently resets a connection whose ClientHello arrives in more than one TCP segment, whatever the client and whatever is in it. The reset comes one round trip after the ClientHello, and curl reports `35` with `Recv failure: Connection reset by peer`. It is the server bug class described at https://tldr.fail/ (a single `read()` for the ClientHello). A post-quantum hybrid key share (1216 bytes for `X25519MLKEM768`) is what pushes a ClientHello over one segment, so every client that sends one is affected, a stock distribution curl included.

History: the wolfSSL 5.9.x CMake default of `WOLFSSL_MLKEM` flipped from `no` to `yes` (the option text still says "default: disabled"; `WOLFSSL_PQC_HYBRIDS` defaults to on), which made 2-3 badssl.com checks of `test-curl-tool.sh` fail after the 5.9.4 update. On 2026-11-16 that was put down to the ClientHello size (wolfSSL 7 resets of 12, system curl with OpenSSL 3.5 2 of 12, small ClientHellos 0 of 24), and the port got `-DWOLFSSL_MLKEM=no` (5.9.4#0). The exit code `28` instead of `35` at the time was a separate bug, see `ports/curl/_notes.md`. On 2026-11-26 the same failure showed up with `curl[openssl]`, and the cause was narrowed down to segmentation.

Measured on 2026-11-26 from the container on the Arch host, where the path MSS was 1408 bytes (`TCP_MAXSEG` on the connected socket). The rate drifts: a later sample the same day had 0 resets in 180 multi-segment runs.

| what was sent | segments | resets |
|---|---|---|
| `curl[openssl]` from the port, OpenSSL 3.6.3 defaults (1571 bytes) | 2 | 4 of 138 |
| the container's curl 8.14.1 with OpenSSL 3.5.9 (1581 bytes) | 2 | 3 of 104 |
| raw replay of that 1571-byte ClientHello | 2 | 19 of 150 |
| 1595 bytes without any ML-KEM (`--curves '*ffdhe8192:*ffdhe2048:P-256:X25519'`) | 2 | 7 of 40 |
| 306- and 517-byte ClientHellos cut in two `send()` calls | 2 | 11 of 60 |
| `curl[wolfssl]` with ML-KEM off (306 bytes) | 1 | 0 of 40 |
| `curl[openssl]` with `--curves X25519:P-256:P-384` or `'X25519MLKEM768:*X25519:P-256:P-384'` (517 bytes) | 1 | 0 of 90 |
| raw replay of the 306- and 517-byte ClientHellos in one piece | 1 | 0 of 100 |

What the user decided on 2026-11-26, and what was rejected:

- The resets are handled in the test, not in the ports. `badssl()` in `tests/curl/test-curl-tool.sh` repeats a request up to 5 times while its output has `Connection reset by peer` (`Connection was reset` on Windows). It was verified with a local relay to badssl.com that resets some connections after their first bytes (`SO_LINGER` with a zero timeout): with 2 of every 3 connections reset the suite passed 48 of 48, and with all of them reset the five certificate and `-k` checks failed, listing five attempts each. In that second case 'TLS 1.0 only server is rejected' still passes, because it expects `35` anyway.
- Rejected for the ports: OpenSSL's `no-ml-kem` (removes ML-KEM for every consumer), and removing the `*` of `?*X25519MLKEM768` from `TLS_DEFAULT_GROUP_LIST` in OpenSSL's `ssl/t1_lib.c` or setting a group list in curl's `lib/vtls/openssl.c` (patches against an upstream security default, as neither has a build option for it). None of these was built. At runtime `--curves 'X25519MLKEM768:*X25519:P-256:P-384'` does what the second one would: a 517-byte ClientHello, and cloudflare.com and google.com still end up with `X25519MLKEM768`.
- Rejected for the test: `--curves` on the badssl.com checks, because the list is specific to the back end. wolfSSL without Curve25519 fails `X25519:P-256:P-384` with `59`, and the tool ignores the option with Schannel.
- ML-KEM was enabled in the `wolfssl` port (5.9.4#1), together with Curve25519 and both unconditionally, so that the `wolfssl` feature of curl is not weaker than the `openssl` one.

## wolfSSL ML-KEM needs Curve25519

wolfSSL sends exactly one key share, `WOLFSSL_KEY_SHARE_DEFAULT_GROUP` in `src/tls.c`: `X25519MLKEM768` when ML-KEM and Curve25519 are both enabled, `SecP256r1MLKEM768` with ML-KEM alone, and `secp256r1` without ML-KEM. OpenSSL 3.5 and later send two, `X25519MLKEM768` and `x25519`. This is what cloudflare.com, google.com, github.com, httpbingo.org, nghttp2.org, facebook.com and curl.se answered on 2026-11-26:

| build | ClientHello | key share | accepted by | HelloRetryRequest from |
|---|---|---|---|---|
| wolfSSL, ML-KEM off (5.9.4#0) | about 300 bytes | `secp256r1` | 6 | httpbingo.org, which asks for `secp384r1` |
| wolfSSL, ML-KEM on, no Curve25519 | about 1490 bytes | `SecP256r1MLKEM768` | 0 | all 7, asking for `secp256r1` or `secp384r1` |
| wolfSSL, ML-KEM on, Curve25519 (5.9.4#1) | about 1460 bytes | `X25519MLKEM768` | 5 | github.com (`x25519`) and httpbingo.org (`secp384r1`) |
| OpenSSL 3.6.3 | about 1570 bytes | `X25519MLKEM768` and `x25519` | 7 | none |

So ML-KEM without Curve25519 never gets a post-quantum key exchange and only adds a round trip, which is why 5.9.4#1 sets `WOLFSSL_MLKEM=yes` and `WOLFSSL_CURVE25519=yes` together. A HelloRetryRequest costs one round trip of handshake time (`time_appconnect` minus `time_connect`): with the P-256 hybrid nghttp2.org went from 249 to 473 ms and github.com from 29 to 51 ms. With 5.9.4#1 github.com still takes 49 ms, the price of having no second key share. Avoiding that would take a curl patch calling `wolfSSL_UseKeyShare()` for a classical group as well, which was not tried.

Both options are unconditional, like session tickets, and the `curve25519` feature that the port had up to 5.9.4#0 was removed, as it would always be on (the user's decision, 2026-11-26). No port in the registry referred to that feature, and the curl port needed no change: its `wolfssl` feature depends on a plain `wolfssl`. A manifest outside the registry that asks for `wolfssl[curve25519]` has to drop the feature.

Rejected: a default feature `mlkem` depending on `curve25519`, which was the first implementation. Apart from the user preferring no feature at all, its opt-out would not have worked through curl. vcpkg (2026-09-26) keeps the default features of a package whenever some port depends on it with defaults on, so with `curl[wolfssl]` depending on a plain `wolfssl` a top-level `{"name": "wolfssl", "default-features": false}`, or `wolfssl[core]` on the command line in classic mode, did not remove `mlkem` (checked with `vcpkg install --dry-run` in both modes, with and without a `builtin-baseline`). It only worked with `"default-features": false` on curl's `wolfssl` dependency as well.

Other things measured with 5.9.4#1 on x64-linux:

- the consumer view (the `gcc -E -dM` check above) has `WOLFSSL_HAVE_MLKEM`, `WOLFSSL_PQC_HYBRIDS`, `WOLFSSL_TLS_NO_MLKEM_STANDALONE` and `HAVE_CURVE25519`
- `wolfssl[asio,dtls,quic,secret-callback]` builds, and its consumer view also has `WOLFSSL_DTLS_CH_FRAG`, which upstream's CMake turns on for ML-KEM with DTLS 1.3, so including the headers with `-Werror` does not trip the `#warning` in `settings.h`
- `libwolfssl.a` grew by about 176 KB and a static curl tool by about 135 KB
- the suite passed 48 of 48 twice with each back end, both session reuse checks included
- an application that has to reach a server with the segment bug can set classical groups for that connection (`CURLOPT_SSL_EC_CURVES`): `--curves P-256:P-384:P-521` gave a 294-byte ClientHello

## Looking at a ClientHello

To measure a client's ClientHello, capture it with a local listener. Verified 2026-11-16 with the container's `/usr/bin/curl`, which sent 1578 bytes:

```sh
nc -l 127.0.0.1 4435 > <scratch>/hello.bin & ncPid=$!
<curl> -sS -m 2 -o /dev/null --connect-to expired.badssl.com:443:127.0.0.1:4435 https://expired.badssl.com/
kill $ncPid; wc -c < <scratch>/hello.bin   # bytes 4-5 (od -An -tx1 -N6) are the TLS record length
```

To see what a server makes of it, send the captured bytes to the server over a plain socket and read the first record of the reply (capture with the server's own host name, so that the SNI matches). In the ClientHello, extension 51 lists the key shares and extension 10 the supported groups. In the reply, a ServerHello (handshake type 2) whose random is `cf21ad74e59a6111be1d8c021e65b891c2a211167abb8c5e079e09e2c8a8339c` is a HelloRetryRequest and its extension 51 holds the group the server asks for, while in a real ServerHello it holds the accepted group. The group ids are `0x11ec` for X25519MLKEM768, `0x11eb` for SecP256r1MLKEM768, `0x11ed` for SecP384r1MLKEM1024, `0x001d` for x25519, `0x0017` for secp256r1 and `0x0018` for secp384r1. curl's `-v` prints the negotiated group only with OpenSSL. Sending the same bytes in two `send()` calls with `TCP_NODELAY` and a pause in between is how a small ClientHello was put into two segments.
