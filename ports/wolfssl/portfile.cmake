vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL git@github.com:wolfSSL/wolfssl.git
    REF 59f4fa568615396fbf381b073b220d1e8d61e4c2
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
set(ENABLE_CURVE25519 no)
if("curve25519" IN_LIST FEATURES)
    set(ENABLE_CURVE25519 yes)
endif()
#
vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")
#
foreach(config RELEASE DEBUG)
    string(APPEND
        VCPKG_COMBINED_C_FLAGS_${config}
        " -DHAVE_EX_DATA -DNO_WOLFSSL_STUB -DWOLFSSL_ALT_CERT_CHAINS -DWOLFSSL_DES_ECB -DWOLFSSL_CUSTOM_OID -DHAVE_OID_ENCODING -DWOLFSSL_CERT_GEN -DWOLFSSL_ASN_TEMPLATE -DWOLFSSL_KEY_GEN -DHAVE_PKCS7 -DHAVE_AES_KEYWRAP -DWOLFSSL_AES_DIRECT -DHAVE_X963_KDF"
    )
    if("secret-callback" IN_LIST FEATURES)
        string(APPEND
            VCPKG_COMBINED_C_FLAGS_${config}
            " -DHAVE_SECRET_CALLBACK"
        )
    endif()
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
        -DWOLFSSL_ASIO=${ENABLE_ASIO}
        -DWOLFSSL_DTLS=${ENABLE_DTLS}
        -DWOLFSSL_DTLS13=${ENABLE_DTLS}
        -DWOLFSSL_DTLS_CID=${ENABLE_DTLS}
        -DWOLFSSL_QUIC=${ENABLE_QUIC}
        -DWOLFSSL_SESSION_TICKET=${ENABLE_QUIC}
        -DWOLFSSL_CURVE25519=${ENABLE_CURVE25519}
    OPTIONS_RELEASE
        -DCMAKE_C_FLAGS=${VCPKG_COMBINED_C_FLAGS_RELEASE}
    OPTIONS_DEBUG
        -DCMAKE_C_FLAGS=${VCPKG_COMBINED_C_FLAGS_DEBUG}
        -DWOLFSSL_DEBUG=yes
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
