set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Emscripten)

if(NOT DEFINED ENV{EMSDK})
    message(FATAL_ERROR "[ERROR] The EMSDK environment variable isn't set, you probably haven't sourced emsdk_env.sh")
endif()

# will chainload our custom Emscripten toolchain
set(EMSCRIPTEN_TOOLCHAIN_FILE_PATH "${CMAKE_CURRENT_LIST_DIR}/../toolchains/emscripten-pthreads.cmake")
if(NOT EXISTS ${EMSCRIPTEN_TOOLCHAIN_FILE_PATH})
    message(FATAL_ERROR "[ERROR] Could not find Emscripten.cmake toolchain file, expected it to be at ${EMSCRIPTEN_TOOLCHAIN_FILE_PATH}")
endif()

# otherwise these environment variables won't be available in the chainloaded toolchain
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSDK EMSCRIPTEN PATH)
# required, otherwise "Unable to determine toolchain use ... with CMAKE_SYSTEM_NAME Emscripten"
# and yes, for building the main project you'll yet again need to provide `-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"` in CLI
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${EMSCRIPTEN_TOOLCHAIN_FILE_PATH})
