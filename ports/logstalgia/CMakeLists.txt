cmake_minimum_required(VERSION 3.22)

project("logstalgia" VERSION 1.1.4)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

set(CMAKE_EXPORT_COMPILE_COMMANDS YES)

# seems to be redundant, as CMake 3.22 is explicitly required
#cmake_policy(PUSH)
#if(POLICY CMP0072)
#    cmake_policy(SET CMP0072 NEW) # prefer GLVND
#endif()
find_package(OpenGL REQUIRED)
#cmake_policy(POP)

set(sources
    src/custom.cpp
    src/logentry.cpp
    src/logstalgia.cpp
    src/main.cpp
    src/ncsa.cpp
    src/paddle.cpp
    src/requestball.cpp
    src/settings.cpp
    src/slider.cpp
    src/summarizer.cpp
    src/textarea.cpp
    src/tests.cpp
    src/configwatcher.cpp
    src/core/conffile.cpp
    src/core/display.cpp
    src/core/frustum.cpp
    src/core/fxfont.cpp
    src/core/logger.cpp
    src/core/plane.cpp
    src/core/png_writer.cpp
    src/core/ppm.cpp
    src/core/quadtree.cpp
    src/core/regex.cpp
    src/core/resource.cpp
    src/core/sdlapp.cpp
    src/core/seeklog.cpp
    src/core/settings.cpp
    src/core/shader.cpp
    src/core/shader_common.cpp
    src/core/stringhash.cpp
    src/core/texture.cpp
    src/core/timezone.cpp
    src/core/vbo.cpp
    src/core/vectors.cpp
)

add_executable(${CMAKE_PROJECT_NAME})

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${sources}
        resources.rc
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

find_package(Threads REQUIRED)
find_package(freetype CONFIG REQUIRED)
find_package(glew CONFIG REQUIRED)
find_package(glm CONFIG REQUIRED)
find_package(pcre CONFIG REQUIRED)
find_package(png CONFIG REQUIRED)
find_package(SDL2 CONFIG REQUIRED)
find_package(SDL2_image CONFIG REQUIRED)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        "${Boost_INCLUDE_DIR}"
)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    find_package(Boost REQUIRED) # no CONFIG, unfortunately
    # very not nice
    find_library(Boost_filesystem_LIBRARY_DEBUG
        NAMES
            "libboost_filesystem-vc143-mt-gd-x64-1_87" # STATIC library, DYNAMIC CRT
            "libboost_filesystem-vc143-mt-sgd-x64-1_87" # STATIC library, STATIC CRT
            "boost_filesystem-vc143-mt-gd-x64-1_87" # SHARED
        PATHS "${Boost_LIBRARIES_DEBUG}"
        NO_CMAKE_FIND_ROOT_PATH
    )
    find_library(Boost_filesystem_LIBRARY_RELEASE
        NAMES
            "libboost_filesystem-vc143-mt-x64-1_87" # STATIC, DYNAMIC CRT
            "libboost_filesystem-vc143-mt-s-x64-1_87" # STATIC, STATIC CRT
            "boost_filesystem-vc143-mt-x64-1_87" # SHARED
        PATHS "${Boost_LIBRARIES_RELEASE}"
        NO_CMAKE_FIND_ROOT_PATH
    )
    # that is an overkill, and it will work only for STATIC variant
    # target_link_directories(${CMAKE_PROJECT_NAME}
    #     PRIVATE
    #         "$<IF:$<CONFIG:Debug>,${Boost_LIBRARIES_DEBUG},${Boost_LIBRARIES_RELEASE}>"
    # )
    # ...because looks like vcpkg toolchain/scripts does some Boost-related shenanigans,
    # such as setting `/DEFAULTLIB:"libboost_filesystem-vc143-mt-x64-1_87.lib"` in object files
    # and the likes, and apparently `BOOST_ALL_NO_LIB` definition prevents that,
    # according to https://gitlab.kitware.com/cmake/cmake/-/issues/17717#note_372697
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            "BOOST_ALL_NO_LIB"
    )

    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            $<IF:$<CONFIG:Debug>,${Boost_filesystem_LIBRARY_DEBUG},${Boost_filesystem_LIBRARY_RELEASE}>
    )
else()
    find_package(Boost
        REQUIRED
        COMPONENTS
            filesystem
        CONFIG
    )
    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            #${Boost_FILESYSTEM_LIBRARY}
            ${Boost_LIBRARIES} # contains all the libraries that were found from COMPONENTS
    )
endif()

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${OPENGL_gl_LIBRARY}
        freetype
        GLEW::glew
        glm::glm
        pcre::pcre2-posix
        png
        SDL2::SDL2
        SDL2::SDL2main
        SDL2::SDL2_image
        # these might be needed when building with MinGW
        # -lglu32
        # -static-libgcc
        # -static-libstdc++
        # -lcomdlg32
)

install(TARGETS ${CMAKE_PROJECT_NAME})
install(DIRECTORY "data"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
    PATTERN "logstalgia.1" EXCLUDE
)
