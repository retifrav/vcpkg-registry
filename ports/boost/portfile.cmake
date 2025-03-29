if(NOT VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_POLICY_EMPTY_PACKAGE enabled)

    message(STATUS
        "This port is only for getting pre-built Boost binaries for Windows. "
        "On other platforms it is expected that Boost is already pre-installed "
        "with the system package manager.\n\n"
        "# Mac OS\n\n"
        "```\n$ brew install boost\n```\n\n"
        "# GNU/Linux\n\n"
        "```\n$ sudo apt install libboost-all-dev\n```\n"
    )

    file(
        INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage-unix"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
        RENAME usage
    )

    return()
endif()

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BOOST_LINKAGE_IS_DYNAMIC)
string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "dynamic" CRT_LINKAGE_IS_DYNAMIC)

vcpkg_download_distfile(
    ARCHIVE
    URLS
        "https://boost.teeks99.com/bin/1.87.0/boost_1_87_0-bin-msvc-all-32-64.7z"
        "https://altushost-swe.dl.sourceforge.net/project/boost/boost-binaries/1.87.0/boost_1_87_0-bin-msvc-all-32-64.7z"
    FILENAME "boost_1_87_0-bin-msvc-all-32-64.7z"
    SHA512 d6a21f3fb0406115c71102f56391b91058d009f611d3b7469aea35895c2bd3236de0a6387d01753c3506bfd3351254a20fa7deb8cff3ef206c317281ecee5685
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

file(
    INSTALL "${SOURCE_PATH}/boost"
    DESTINATION "${CURRENT_PACKAGES_DIR}/include"
)

if(BOOST_LINKAGE_IS_DYNAMIC)
    # Release
    file(
        INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/bin"
        FILES_MATCHING
            PATTERN "boost_*-mt-x64-*.dll"
    )
    file(
        INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/lib"
        FILES_MATCHING
            PATTERN "boost_*-mt-x64-*.lib"
    )
    # Debug
    file(
        INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin"
        FILES_MATCHING
            PATTERN "boost_*-mt-gd-x64-*.dll"
    )
    file(
        INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
        DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib"
        FILES_MATCHING
            PATTERN "boost_*-mt-gd-x64-*.lib"
            #PATTERN "boost_*-mt-gd-x64-*.pdb" # does anyone actually need these?
    )
else()
    if(CRT_LINKAGE_IS_DYNAMIC)
        # Release
        file(
            INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/lib"
            FILES_MATCHING
                PATTERN "libboost_*-mt-x64-*.lib"
        )
        # Debug
        file(
            INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib"
            FILES_MATCHING
                PATTERN "libboost_*-mt-gd-x64-*.lib"
        )
    else()
        # Release
        file(
            INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/lib"
            FILES_MATCHING
                PATTERN "libboost_*-mt-s-x64-*.lib"
        )
        # Debug
        file(
            INSTALL "${SOURCE_PATH}/lib64-msvc-14.3/"
            DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib"
            FILES_MATCHING
                PATTERN "libboost_*-mt-sgd-x64-*.lib"
        )
    endif()
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/include/boost/headers"
    "${CURRENT_PACKAGES_DIR}/debug/bin/cmake"
    "${CURRENT_PACKAGES_DIR}/debug/lib/cmake"
    "${CURRENT_PACKAGES_DIR}/bin/cmake"
    "${CURRENT_PACKAGES_DIR}/lib/cmake"
)

set(Boost_PACKAGE_NAME "Boost")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${Boost_PACKAGE_NAME}"
)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindBoost.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${Boost_PACKAGE_NAME}"
)

file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage-windows"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME usage
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE_1_0.txt")
