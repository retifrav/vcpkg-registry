# we got only static libraries
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
# and there are no Debug binaries
set(VCPKG_POLICY_MISMATCHED_NUMBER_OF_BINARIES enabled)

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://securecdn.oculus.com/binaries/download/?id=4377593722298679"
        "https://softpedia-secure-download.com/dl/c92a5740ff22014457f4491c704bb850/67d5da72/100251663/software/programming/ovr_sdk_win_32.0.0.zip"
    FILENAME "ovr_sdk_win_32.0.0.zip"
    SHA512 393bd5b5f70bf7c8d71537b1a96ee40671395e4b88dc34b65ab1d818dccecab8f8c2f24fc46800b79488bd441b4dd333c39cf79eb4c5438ef52796be73a4d9b4
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    NO_REMOVE_ONE_LEVEL # ah yes, Facebook developers don't know how to create archives
)

file(INSTALL "${SOURCE_PATH}/LibOVR/Include"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include"
    RENAME "ovr"
)

file(INSTALL "${SOURCE_PATH}/LibOVR/Lib/Windows/x64/Release/VS2017/LibOVR.lib" # ah yes, "lib" in the library name - classic
    DESTINATION "${CURRENT_PACKAGES_DIR}/lib"
)

set(OculusSDK_PACKAGE_NAME "OculusSDK")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${OculusSDK_PACKAGE_NAME}"
)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindOculusSDK.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${OculusSDK_PACKAGE_NAME}"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/LICENSE")
