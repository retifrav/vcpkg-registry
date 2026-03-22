include(${CMAKE_CURRENT_LIST_DIR}/_set-vcpkg-registry-path.cmake)
set_vcpkg_registry_path() # should set `VCPKG_TOOL_PARENT_PATH`
include("${VCPKG_TOOL_PARENT_PATH}/scripts/toolchains/ios.cmake")
unset(VCPKG_TOOL_PARENT_PATH) # just in case

# to make a Mach-O combined/fat/universal binary, one needs to set both architectures,
# either here with `CMAKE_OSX_ARCHITECTURES` or in the triplet with `VCPKG_OSX_ARCHITECTURES`
#set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
# and set Xcode attributes to specify which architecture is for actual devices
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=iphoneos*] "arm64")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=iphoneos*] "arm64")
# and which architecture is for simulator
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=iphonesimulator*] "x86_64")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=iphonesimulator*] "x86_64")
# and probably also set these flags
#set(CMAKE_IOS_INSTALL_COMBINED 1)
#set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH 0)
