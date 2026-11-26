vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:wolfSSL/wolfssl.git
    REF 3c5eead44904df64e6a5a1f4ebdce377d35a849a
    PATCHES
        001-installation.patch
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in" DESTINATION "${SOURCE_PATH}")
file(COPY
    "${CURRENT_HOST_INSTALLED_DIR}/share/decovar-vcpkg-cmake/common/Installing.cmake"
    DESTINATION "${SOURCE_PATH}"
)

# they hardcode options to `yes` and `no`, hence no usual `vcpkg_check_features()`
#
set(ENABLE_ASIO no)
if("asio" IN_LIST FEATURES)
    set(ENABLE_ASIO yes)
endif()
#
set(ENABLE_DTLS no)
if("dtls" IN_LIST FEATURES)
    set(ENABLE_DTLS yes)
endif()
#
set(ENABLE_QUIC no)
if("quic" IN_LIST FEATURES)
    set(ENABLE_QUIC yes)
endif()
#
# these defines have no CMake option, so they can only be passed as compiler flags, but those do not
# get into the generated `wolfssl/options.h`, so they are also added there after installation,
# otherwise consumers would build against a different configuration than the library. Everything else
# is set via CMake options below (and `WOLFSSL_ASN_TEMPLATE` is the default anyway)
set(WOLFSSL_DEFINES_WITHOUT_OPTION
    HAVE_OID_ENCODING
    WOLFSSL_CUSTOM_OID
    WOLFSSL_DES_ECB
)
# there is `WOLFSSL_KEYLOG_EXPORT` option, but in addition to `HAVE_SECRET_CALLBACK`
# it also sets `SHOW_SECRETS` and `WOLFSSL_SSLKEYLOGFILE`, with which the library itself
# prints and writes TLS secrets to a file, while here only the callback is wanted
if("secret-callback" IN_LIST FEATURES)
    list(APPEND WOLFSSL_DEFINES_WITHOUT_OPTION HAVE_SECRET_CALLBACK)
endif()
#
vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")
#
foreach(config RELEASE DEBUG)
    foreach(define IN LISTS WOLFSSL_DEFINES_WITHOUT_OPTION)
        string(APPEND VCPKG_COMBINED_C_FLAGS_${config} " -D${define}")
    endforeach()
endforeach()

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DWOLFSSL_BUILD_OUT_OF_TREE=yes
        -DWOLFSSL_EXAMPLES=no
        -DWOLFSSL_CRYPT_TESTS=no
        -DWOLFSSL_OPENSSLEXTRA=yes
        -DWOLFSSL_TPM=yes
        -DWOLFSSL_TLSX=yes
        -DWOLFSSL_OCSP=yes
        -DWOLFSSL_OCSPSTAPLING=yes
        -DWOLFSSL_OCSPSTAPLING_V2=yes
        -DWOLFSSL_CRL=yes
        -DWOLFSSL_DES3=yes
        -DWOLFSSL_HPKE=yes
        -DWOLFSSL_SNI=yes
        -DWOLFSSL_ALT_CERT_CHAINS=yes
        -DWOLFSSL_EX_DATA=yes
        -DWOLFSSL_NO_STUB=yes
        # TLS 1.3 sessions can only be resumed with tickets, and it is also needed for QUIC
        -DWOLFSSL_SESSION_TICKET=yes
        # without it ticket nonces longer than 8 bytes (TLS 1.3 allows up to 255) fail
        # the connection with `INVALID_PARAMETER` (for example on httpbingo.org), also
        # the original `./configure --enable-curl` enables it too
        -DWOLFSSL_TICKET_NONCE_MALLOC=yes
        # these are also enabled by `WOLFSSL_TPM`, but set explicitly to not depend on that
        -DWOLFSSL_AESKEYWRAP=yes # also sets `WOLFSSL_AES_DIRECT`
        -DWOLFSSL_CERTGEN=yes
        -DWOLFSSL_KEYGEN=yes
        -DWOLFSSL_PKCS7=yes
        -DWOLFSSL_X963KDF=yes
        # post-quantum hybrid key exchange in TLS 1.3. Upstream default was `no` in 5.8.4
        # and is `yes` in 5.9.4 (although the option description still says "disabled"),
        # so it is set explicitly. Such a key share is sent right away, so ClientHello grows
        # from ~300 bytes to ~1.5 KB and no longer fits into one TCP segment, which some servers
        # cannot handle (for example, badssl.com resets such a connection every now and then).
        # An application that has to talk to a server like that can set classical groups
        # for that connection (`CURLOPT_SSL_EC_CURVES` with cURL)
        -DWOLFSSL_MLKEM=yes
        # ML-KEM is of little use without Curve25519, wolfSSL sends only one key share,
        # and without Curve25519 that is SecP256r1MLKEM768, which hardly any server supports,
        # so the only result would be an extra round trip (HelloRetryRequest) to agree
        # on a classical group. With Curve25519 it is X25519MLKEM768, the same one that browsers
        # and OpenSSL send. A server that does not support it still costs that extra round trip,
        # as there is no second (classical) key share, like OpenSSL has
        -DWOLFSSL_CURVE25519=yes
        #
        -DWOLFSSL_ASIO=${ENABLE_ASIO}
        -DWOLFSSL_DTLS=${ENABLE_DTLS}
        -DWOLFSSL_DTLS13=${ENABLE_DTLS}
        -DWOLFSSL_DTLS_CID=${ENABLE_DTLS}
        -DWOLFSSL_QUIC=${ENABLE_QUIC}
    OPTIONS_RELEASE
        -DCMAKE_C_FLAGS=${VCPKG_COMBINED_C_FLAGS_RELEASE}
    OPTIONS_DEBUG
        -DCMAKE_C_FLAGS=${VCPKG_COMBINED_C_FLAGS_DEBUG}
        -DWOLFSSL_DEBUG=yes
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

# add the defines that were passed as compiler flags (see above) to the installed `options.h`
set(options_h "${CURRENT_PACKAGES_DIR}/include/wolfssl/options.h")
set(options_h_guard_end "#endif /* WOLFSSL_OPTIONS_H */")
file(READ "${options_h}" options_h_contents)
string(FIND "${options_h_contents}" "${options_h_guard_end}" options_h_guard_end_position)
if(options_h_guard_end_position EQUAL -1)
    message(FATAL_ERROR "Could not find [${options_h_guard_end}] in ${options_h}")
endif()
set(options_h_defines "/* added by the vcpkg port, as these had to be set via compiler flags */\n")
foreach(define IN LISTS WOLFSSL_DEFINES_WITHOUT_OPTION)
    string(APPEND options_h_defines "#undef ${define}\n#define ${define}\n")
endforeach()
string(REPLACE
    "${options_h_guard_end}"
    "${options_h_defines}\n${options_h_guard_end}"
    options_h_contents
    "${options_h_contents}"
)
file(WRITE "${options_h}" "${options_h_contents}")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
