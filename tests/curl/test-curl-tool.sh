#!/bin/bash

# Tests for the cURL tool from the `curl` port (built with the `tool` feature): sends real requests
# to public test services and checks exit codes and output. Checks adapt to the features reported
# by `curl --version`, so for example `--http2` is expected to work with the `http2` feature
# and to be rejected without it.
#
# It needs network access to httpbingo.org, badssl.com, nghttp2.org, www.facebook.com, github.com
# and echo.websocket.org. Those are third-party services, so if a single check fails, re-run it
# before blaming cURL. The only failure that is handled here is badssl.com resetting the connection,
# those requests are repeated (see `badssl()` below).
#
# Windows caveats:
#
# - run it from Git Bash or MSYS2, as it needs bash, grep and coreutils; it does not work in cmd or PowerShell
# - pass the port's tool explicitly with -c (`.../tools/curl/curl.exe`), because Windows has its own
#   `C:\Windows\System32\curl.exe`, and in Windows PowerShell 5.1 a plain `curl` is not even cURL
#   but an alias for `Invoke-WebRequest`, so when running commands manually, call `curl.exe`
# - when copying commands from here to cmd/PowerShell, `/dev/null` needs to become `NUL`
#   and single quotes need to become double quotes (escaping the inner ones)
# - the script needs LF line endings: with `core.autocrlf=true` Git checks it out with CRLF,
#   and then bash fails with `$'\r': command not found` (`dos2unix` it or set `core.autocrlf=input`)
# - with Schannel (the `ssl`/`sspi` features on Windows) certificate errors can end up with different
#   exit codes than with OpenSSL/wolfSSL; the known alternatives are accepted, but others might show up
# - Schannel supports TLS 1.3 only on Windows 11 / Windows Server 2022 and newer,
#   so the `--tlsv1.3` check fails on older Windows versions
# - Schannel does not report TLS session reuse (only debug builds of cURL log it),
#   so the session reuse checks are skipped
# - trust comes from the Windows certificate store (`CURL_CA_NATIVE`), so a TLS-inspecting corporate proxy
#   or antivirus that re-signs traffic with its own root certificate can turn the badssl.com checks
#   for expired/self-signed/wrong host certificates into false failures
# - the explicit CA bundle check looks for the bundle that comes with Git for Windows/MSYS2;
#   for other setups pass one with -a, otherwise the check is skipped
# - with dynamic triplets the tool needs libcurl and dependencies DLLs next to it; vcpkg copies them
#   into `tools/curl/`, but if the executable was moved elsewhere, it fails to start (exit code 127)

curlTool=""
timeout=20
caBundle=""
verbose=0

helpMessage="Testing the curl tool built from the \`curl\` port with requests to public test services.

Usage:

    $(basename $0) -c PATH-TO-CURL-TOOL [-t TIMEOUT-SECONDS] [-a PATH-TO-CA-BUNDLE] [-v]

Example:

    $(basename $0) -c ./vcpkg_installed/x64-linux/tools/curl/curl

Options:

    -c  path to the curl tool, required, so the system curl does not get tested by accident
    -t  maximum time for every request, default: $timeout
    -a  CA bundle for the explicit \`--cacert\` check, default: first one found in common locations
    -v  print output of every check, not only of failed ones

Exit code is 0 if all checks passed (or were skipped), and 1 if any of them failed."

while getopts ":c:t:a:vh" opt; do
  case $opt in
    c) curlTool="$OPTARG"
    ;;
    t) timeout="$OPTARG"
    ;;
    a) caBundle="$OPTARG"
    ;;
    v) verbose=1
    ;;
    h)
        echo "$helpMessage"
        exit 0
    ;;
    \?)
        echo "Unknown option -$OPTARG" >&2
        exit 2
    ;;
    :)
        echo "Option -$OPTARG requires a value" >&2
        exit 2
    ;;
  esac
done

if [ -z "$curlTool" ]; then
    echo "[ERROR] You need to provide path to the curl tool (-c)" >&2
    exit 2
fi
if [ ! -f "$curlTool" ]; then
    echo "[ERROR] The curl tool [$curlTool] does not exist" >&2
    exit 2
fi
# absolute path, because checks run inside a temporary folder
curlTool="$(cd "$(dirname "$curlTool")" && pwd)/$(basename "$curlTool")"

if [ -z "$caBundle" ]; then
    for candidate in \
        /etc/ssl/certs/ca-certificates.crt \
        /etc/pki/tls/certs/ca-bundle.crt \
        /etc/ssl/cert.pem \
        /mingw64/etc/ssl/certs/ca-bundle.crt \
        /usr/ssl/certs/ca-bundle.crt
    do
        if [ -f "$candidate" ]; then
            caBundle="$candidate"
            break
        fi
    done
elif [ ! -f "$caBundle" ]; then
    echo "[ERROR] The CA bundle [$caBundle] does not exist" >&2
    exit 2
fi

versionOutput="$("$curlTool" --version 2>&1)"
if [ $? -ne 0 ]; then
    echo "[ERROR] Could not run [$curlTool --version]:" >&2
    echo "$versionOutput" >&2
    exit 2
fi
versionOutput="${versionOutput//$'\r'/}"
versionLine="$(printf '%s\n' "$versionOutput" | head -n 1)"
features="$(printf '%s\n' "$versionOutput" | sed -n 's/^Features: //p')"

hasFeature()
{
    case " $features " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

# certificate verification failures: 60 (peer verification), 77 (CA problem, wolfSSL),
# and Schannel also reports some of them as 35 (TLS handshake)
certErrors="60|77"
schannel=0
case "$versionLine" in
    *Schannel*)
        certErrors="35|60|77"
        schannel=1
    ;;
esac

tmpDir="$(mktemp -d "${TMPDIR:-/tmp}/curl-tool-tests.XXXXXX")" || exit 2
trap 'cd / && rm -rf "$tmpDir"' EXIT
cd "$tmpDir" || exit 2

passed=0
failed=0
skipped=0

# every request gets a time limit; a later `-m` in the arguments overrides it
crl()
{
    "$curlTool" --max-time "$timeout" "$@"
}

# badssl.com every now and then resets the connection, if ClientHello did not fit into one TCP segment,
# which is the case with a post-quantum key share (X25519MLKEM768 makes ClientHello about 1.5 KB),
# and it does so to any client, cURL or not. So that is not a cURL failure, and the request is repeated
badssl()
{
    local output exitCode attempt
    for attempt in 1 2 3 4 5; do
        output="$(crl "$@" 2>&1)"
        exitCode=$?
        case "$output" in
            # the second one is how it is reported on Windows
            *"Connection reset by peer"*|*"Connection was reset"*)
                echo "attempt $attempt: badssl.com has reset the connection"
            ;;
            *) break
            ;;
        esac
    done
    printf '%s\n' "$output"
    return $exitCode
}

section()
{
    echo
    echo "--- $1"
}

printOutput()
{
    printf '%s\n' "$1" | head -n 25 | sed 's/^/    | /'
}

# check NAME EXPECTED-EXIT-CODES [PATTERN...] -- COMMAND [ARGUMENTS...]
#
# EXPECTED-EXIT-CODES is one code or several separated by `|`;
# every PATTERN is an extended regular expression that the combined stdout/stderr has to match
check()
{
    local name="$1"
    local expectedExits="$2"
    shift 2
    local patterns=()
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do
        patterns+=("$1")
        shift
    done
    shift # the `--`

    local output
    output="$("$@" 2>&1)"
    local exitCode=$?
    output="${output//$'\r'/}"

    local problem=""
    case "|$expectedExits|" in
        *"|$exitCode|"*) ;;
        *) problem="exit code $exitCode, expected $expectedExits" ;;
    esac
    if [ -z "$problem" ]; then
        local pattern
        for pattern in "${patterns[@]}"; do
            if ! printf '%s\n' "$output" | grep -Eq -- "$pattern"; then
                problem="output does not match /$pattern/"
                break
            fi
        done
    fi

    if [ -z "$problem" ]; then
        passed=$((passed + 1))
        echo "PASS  $name"
        if [ $verbose -eq 1 ]; then
            printOutput "$output"
        fi
    else
        failed=$((failed + 1))
        echo "FAIL  $name: $problem"
        printOutput "$output"
    fi
}

skip()
{
    skipped=$((skipped + 1))
    echo "SKIP  $1 ($2)"
}

# --- multi-step checks

compressedResponse()
{
    crl -sS --compressed -H "Accept-Encoding: $1" -D headers.txt -o body.html https://www.facebook.com/ || return $?
    grep -i '^content-encoding' headers.txt
    head -c 100 body.html
    echo
}

openSslBackend()
(
    export CURL_SSL_BACKEND=openssl
    "$curlTool" --version | head -n 1
    crl -sS -o /dev/null -w '%{http_code} verify=%{ssl_verify_result}\n' https://httpbingo.org/get
)

# two requests over separate connections (HTTP/1.1 with `Connection: close`, as with HTTP/2
# the second request would simply go over the same connection), so the second TLS handshake
# can use the session cached from the first one. Extra arguments are passed to cURL. Note
# that cURL only reports offering the cached session, not whether the server accepted it
# (otherwise there is just a full handshake)
sessionReuse()
{
    local output exitCode
    output="$(crl -sS -v --http1.1 -H 'Connection: close' "$@" -o /dev/null -o /dev/null \
        -w 'transfer: %{http_code} %{num_connects}\n' \
        https://httpbingo.org/get https://httpbingo.org/get 2>&1)"
    exitCode=$?
    output="${output//$'\r'/}"
    printf '%s\n' "$output" | grep -E '^\* (SSL connection using|SSL reusing session|cached session)|^transfer: |^curl: '
    [ $exitCode -eq 0 ] || return $exitCode
    local total=0 connects
    while read -r _ _ connects; do
        total=$((total + connects))
    done <<< "$(printf '%s\n' "$output" | grep '^transfer: ')"
    echo "new connections: $total"
}

cookieJar()
{
    crl -sS -c jar.txt -o /dev/null 'https://httpbingo.org/cookies/set?flavour=oat' || return $?
    crl -sS -b jar.txt https://httpbingo.org/cookies
}

rangeAndResume()
{
    rm -f part.bin full.bin
    crl -sS -r 0-99 -o part.bin https://httpbingo.org/range/1000 || return $?
    echo "after range: $(( $(wc -c < part.bin) )) bytes"
    crl -sS -C - -o part.bin -w 'resume: HTTP %{http_code}\n' https://httpbingo.org/range/1000 || return $?
    echo "after resume: $(( $(wc -c < part.bin) )) bytes"
    crl -sS -o full.bin https://httpbingo.org/range/1000 || return $?
    cmp -s part.bin full.bin && echo "resumed file is identical to a full download"
}

# three requests that take 2 seconds each: in parallel they finish well before the 6 seconds
# that they would take one after another; extra arguments are passed to curl
parallelRequests()
{
    local output start=$SECONDS elapsed
    output="$(crl -sS -Z --parallel-max 3 "$@" -o /dev/null -o /dev/null -o /dev/null \
        -w '%{http_version} %{num_connects}\n' \
        https://httpbingo.org/delay/2 https://httpbingo.org/delay/2 https://httpbingo.org/delay/2)" || return $?
    elapsed=$((SECONDS - start))
    output="${output//$'\r'/}"
    printf '%s\n' "$output"
    local total=0 version connects
    while read -r version connects; do
        total=$((total + connects))
    done <<< "$output"
    echo "new connections: $total"
    echo "elapsed: ${elapsed}s"
    [ $elapsed -lt 5 ] && echo "ran in parallel"
}

pinnedAddress()
{
    local ip result
    ip="$(crl -sS -4 -o /dev/null -w '%{remote_ip}' https://httpbingo.org/get)" || return $?
    result="$(crl -sS --resolve "httpbingo.org:443:$ip" -o /dev/null -w '%{http_code} %{remote_ip}' https://httpbingo.org/get)" || return $?
    result="${result//$'\r'/}"
    echo "resolved: $ip, connected: $result"
    [ "$result" = "200 $ip" ] && echo "pinned"
}

hstsUpgrade()
{
    rm -f hsts.txt
    crl -sS --hsts hsts.txt -o /dev/null https://github.com/ || return $?
    grep -v '^#' hsts.txt
    crl -sS --hsts hsts.txt -o /dev/null -w '%{url_effective} %{http_code}\n' http://github.com/
}

libcurlCode()
{
    crl -sS --json '{"a":1}' --libcurl snippet.c -o /dev/null https://httpbingo.org/post || return $?
    cat snippet.c
}

rejectedProtocols()
{
    local protocol message exitCode result=0
    for protocol in \
        dict file ftp ftps gopher gophers imap imaps ipfs ipns ldap ldaps mqtt mqtts \
        pop3 pop3s rtsp scp sftp smb smbs smtp smtps telnet tftp
    do
        message="$(crl -sS "$protocol://localhost/" 2>&1)"
        exitCode=$?
        message="${message//$'\r'/}"
        echo "$protocol: exit $exitCode: $message"
        case "$message" in
            *"Protocol \"$protocol\" is disabled"*|*"Protocol \"$protocol\" not supported"*)
                [ $exitCode -eq 1 ] || result=1
            ;;
            *) result=1
            ;;
        esac
    done
    return $result
}

# --- checks

echo "Testing: $curlTool"
echo "Version: $versionLine"
echo "Features: $features"
echo "CA bundle for the explicit --cacert check: ${caBundle:-(none found)}"

section "basics"

check 'only HTTP(S) and WS(S) protocols' 0 '^Protocols: http https ws wss$' -- \
    crl --version
check 'plain HTTP' 0 '^200 HTTP/1\.1$' -- \
    crl -sS -o /dev/null -w '%{http_code} HTTP/%{http_version}\n' http://httpbingo.org/get
check 'only HTTP(S)/WS(S) URLs are accepted' 0 -- \
    rejectedProtocols

if hasFeature SSL; then
    check 'native CA store is the default' 0 -- \
        hasFeature NativeCA
    check 'HTTPS with default trust (no CA options)' 0 '^200 HTTP/[0-9.]+ verify=0$' -- \
        crl -sS -o /dev/null -w '%{http_code} HTTP/%{http_version} verify=%{ssl_verify_result}\n' https://httpbingo.org/get
    check 'TLS handshake and ALPN' 0 'ALPN: server accepted (h2|http/1\.1)' -- \
        crl -sS -v -o /dev/null https://httpbingo.org/get
else
    skip 'HTTPS checks' 'no SSL feature'
fi

section "HTTP versions"

if hasFeature HTTP2; then
    check 'HTTP/2 over TLS' 0 '^200 HTTP/2$' -- \
        crl -sS --http2 -o /dev/null -w '%{http_code} HTTP/%{http_version}\n' https://httpbingo.org/get
    check 'HTTP/2 with prior knowledge (cleartext h2c)' 0 '^200 HTTP/2$' -- \
        crl -sS --http2-prior-knowledge -o /dev/null -w '%{http_code} HTTP/%{http_version}\n' http://nghttp2.org/
else
    check '--http2 is rejected without the http2 feature' 2 'does not support this' -- \
        crl -sS --http2 -o /dev/null https://httpbingo.org/get
    skip 'HTTP/2 with prior knowledge' 'no HTTP2 feature'
fi
check 'forced HTTP/1.1' 0 '^200 HTTP/1\.1$' -- \
    crl -sS --http1.1 -o /dev/null -w '%{http_code} HTTP/%{http_version}\n' https://httpbingo.org/get
check 'forced HTTP/1.0' 0 '^200 HTTP/1(\.0)?$' -- \
    crl -sS --http1.0 -o /dev/null -w '%{http_code} HTTP/%{http_version}\n' https://httpbingo.org/get

section "TLS"

if hasFeature SSL; then
    check 'expired certificate is rejected' "$certErrors" -- \
        badssl -sS -o /dev/null https://expired.badssl.com/
    check 'self-signed certificate is rejected' "$certErrors" -- \
        badssl -sS -o /dev/null https://self-signed.badssl.com/
    check 'untrusted root is rejected' "$certErrors" -- \
        badssl -sS -o /dev/null https://untrusted-root.badssl.com/
    check 'wrong host name is rejected' "$certErrors" -- \
        badssl -sS -o /dev/null https://wrong.host.badssl.com/
    check 'TLS 1.0 only server is rejected' 35 -- \
        badssl -sS -o /dev/null https://tls-v1-0.badssl.com:1010/
    check '-k skips verification' 0 '^200$' -- \
        badssl -sS -k -o /dev/null -w '%{http_code}\n' https://self-signed.badssl.com/
    check 'TLS 1.3 only' 0 '^200$' -- \
        crl -sS --tlsv1.3 -o /dev/null -w '%{http_code}\n' https://httpbingo.org/get
    if [ $schannel -eq 1 ]; then
        skip 'TLS session reuse' 'Schannel does not report it'
    else
        check 'TLS 1.2 session is reused on a new connection' 0 'SSL reusing session' 'new connections: 2$' -- \
            sessionReuse --tls-max 1.2
        check 'TLS 1.3 session is reused on a new connection' 0 'SSL reusing session' 'new connections: 2$' -- \
            sessionReuse --tlsv1.3
    fi
    if [ -n "$caBundle" ]; then
        check 'explicit CA bundle' 0 '^200$' -- \
            crl -sS --cacert "$caBundle" -o /dev/null -w '%{http_code}\n' https://httpbingo.org/get
    else
        skip 'explicit CA bundle' 'no CA bundle found, pass one with -a'
    fi
    : > empty.pem
    check 'explicit (empty) CA file replaces the native store' "$certErrors" -- \
        crl -sS --cacert empty.pem -o /dev/null https://httpbingo.org/get
    if hasFeature MultiSSL && printf '%s\n' "$versionLine" | grep -q 'OpenSSL/'; then
        # the version line lists all backends, the inactive ones in parentheses
        check 'OpenSSL backend selected at runtime' 0 ' OpenSSL/[0-9]' '^200 verify=0$' -- \
            openSslBackend
    else
        skip 'OpenSSL backend selected at runtime' 'not a MultiSSL build with OpenSSL'
    fi
else
    skip 'TLS checks' 'no SSL feature'
fi

section "compression"

if hasFeature libz; then
    check 'gzip' 0 '^[Cc]ontent-[Ee]ncoding: gzip' '<![Dd][Oo][Cc][Tt][Yy][Pp][Ee] html' -- \
        compressedResponse gzip
else
    skip 'gzip' 'no libz feature'
fi
if hasFeature brotli; then
    check 'brotli' 0 '^[Cc]ontent-[Ee]ncoding: br' '<![Dd][Oo][Cc][Tt][Yy][Pp][Ee] html' -- \
        compressedResponse br
else
    skip 'brotli' 'no brotli feature'
fi
if hasFeature zstd; then
    check 'zstd' 0 '^[Cc]ontent-[Ee]ncoding: zstd' '<![Dd][Oo][Cc][Tt][Yy][Pp][Ee] html' -- \
        compressedResponse zstd
else
    skip 'zstd' 'no zstd feature'
fi

section "requests"

check 'GET with query, custom headers and user agent' 0 '"vcpkg-test/1\.0"' '"X-Test"' '"two"' -- \
    crl -sS -A 'vcpkg-test/1.0' -H 'X-Test: 42' 'https://httpbingo.org/get?a=1&b=two'
check 'HEAD' 0 '^HTTP/[0-9.]+ 200' -- \
    crl -sS -I https://httpbingo.org/get
check 'POST JSON' 0 '"application/json"' '"name": *"curl"' -- \
    crl -sS --json '{"name":"curl","version":8.23}' https://httpbingo.org/post
check 'POST urlencoded form' 0 '"hello world&more"' -- \
    crl -sS -d 'a=1' --data-urlencode 'q=hello world&more' https://httpbingo.org/post
printf 'hello from a file\n' > upload.txt
check 'multipart upload' 0 'hello from a file' '"note"' -- \
    crl -sS -F 'file=@upload.txt;type=text/plain' -F 'note=test' https://httpbingo.org/post
check 'PUT' 0 '^200$' -- \
    crl -sS -X PUT -d 'x' -o /dev/null -w '%{http_code}\n' https://httpbingo.org/put
check 'DELETE' 0 '^200$' -- \
    crl -sS -X DELETE -o /dev/null -w '%{http_code}\n' https://httpbingo.org/delete

section "redirects, authentication, cookies"

check 'redirects are followed' 0 '^200 after 3 redirects -> https://httpbingo\.org/get$' -- \
    crl -sS -L -o /dev/null -w '%{http_code} after %{num_redirects} redirects -> %{url_effective}\n' https://httpbingo.org/redirect/3
check 'basic authentication' 0 '^200$' -- \
    crl -sS -u user:passwd -o /dev/null -w '%{http_code}\n' https://httpbingo.org/basic-auth/user/passwd
check 'basic authentication, wrong password' 0 '^401$' -- \
    crl -sS -u user:wrong -o /dev/null -w '%{http_code}\n' https://httpbingo.org/basic-auth/user/passwd
check 'digest authentication' 0 '^200$' -- \
    crl -sS --digest -u user:passwd -o /dev/null -w '%{http_code}\n' https://httpbingo.org/digest-auth/auth/user/passwd
if hasFeature NTLM; then
    skip '--ntlm is rejected' 'NTLM is enabled in this build'
else
    check '--ntlm is rejected (NTLM is off)' 2 'does not support this' -- \
        crl -sS --ntlm -u user:passwd -o /dev/null https://httpbingo.org/get
fi
check 'cookie jar' 0 '"flavour": *"oat"' -- \
    cookieJar

section "errors, retries, downloads"

check '--fail on HTTP 404' 22 'returned error: 404' -- \
    crl -sS --fail -o /dev/null https://httpbingo.org/status/404
check 'retries on HTTP 503' 0 'Retrying in 1 second\. 2 retries left' '1 retry left' '^503$' -- \
    crl --no-progress-meter --retry 2 --retry-delay 1 -o /dev/null -w '%{http_code}\n' https://httpbingo.org/status/503
check 'range request and resumed download' 0 'after range: 100 bytes' 'resume: HTTP 206' 'after resume: 1000 bytes' 'identical' -- \
    rangeAndResume

section "connections and diagnostics"

check 'timing breakdown' 0 '^dns [0-9.]+s tcp [0-9.]+s tls [0-9.]+s ttfb [0-9.]+s total [0-9.]+s$' -- \
    crl -sS -o /dev/null -w 'dns %{time_namelookup}s tcp %{time_connect}s tls %{time_appconnect}s ttfb %{time_starttransfer}s total %{time_total}s\n' https://httpbingo.org/get
check 'write-out as JSON' 0 '"response_code": *200' -- \
    crl -sS -o /dev/null -w '%{json}' https://httpbingo.org/get
if hasFeature HTTP2; then
    check 'parallel transfers multiplexed over one HTTP/2 connection' 0 '^2 ' 'new connections: 1$' 'ran in parallel' -- \
        parallelRequests
else
    # by default curl waits for the first connection to find out whether it can multiplex,
    # which without HTTP/2 delays one of the transfers until another one is done
    check 'parallel transfers' 0 'ran in parallel' -- \
        parallelRequests --parallel-immediate
fi
check '--resolve pins the host name to an address' 0 '^pinned$' -- \
    pinnedAddress
check 'IPv4 only' 0 '^([0-9]{1,3}\.){3}[0-9]{1,3}$' -- \
    crl -sS -4 -o /dev/null -w '%{remote_ip}\n' https://httpbingo.org/get
if crl -sS -6 -m 5 -o /dev/null https://httpbingo.org/get > /dev/null 2>&1; then
    check 'IPv6 only' 0 ':' -- \
        crl -sS -6 -o /dev/null -w '%{remote_ip}\n' https://httpbingo.org/get
else
    skip 'IPv6 only' 'no IPv6 connectivity'
fi

section "WebSocket, HSTS, libcurl code"

# the connection stays open after the greeting, so the transfer ends with a timeout (28)
check 'WebSocket greeting from echo server' 28 'Request served by' -- \
    crl -sS -m 3 wss://echo.websocket.org/
check 'HSTS cache upgrades http:// to https://' 0 'github\.com "[0-9]{8} ' '^https://github\.com/ 200$' -- \
    hstsUpgrade
check 'equivalent libcurl code is generated' 0 'CURLOPT_URL, "https://httpbingo\.org/post"' 'CURLOPT_POSTFIELDS' -- \
    libcurlCode

echo
echo "$passed passed, $failed failed, $skipped skipped"
[ $failed -eq 0 ]
