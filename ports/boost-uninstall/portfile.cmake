set(VCPKG_POLICY_EMPTY_PACKAGE enabled)

message(STATUS "\nTo remove all the Boost ports/components you can use the following command:\n\n\
    ./vcpkg remove boost-uninstall:${TARGET_TRIPLET} --recurse\n")

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
    "${CURRENT_PACKAGES_DIR}/share/boost/vcpkg-cmake-wrapper.cmake"
    @ONLY
)
