cmake_minimum_required(VERSION 3.28)

project("gource" VERSION 0.55.0)

set(REQUIRED_CPP_STANDARD 17 CACHE STRING "Required C++ standard")
if(DEFINED CMAKE_CXX_STANDARD)
    if(CMAKE_CXX_STANDARD LESS ${REQUIRED_CPP_STANDARD})
        message(FATAL_ERROR "This project requires at least C++${REQUIRED_CPP_STANDARD}")
    endif()
else()
    set(CMAKE_CXX_STANDARD ${REQUIRED_CPP_STANDARD})
endif()
set(CMAKE_CXX_STANDARD_REQUIRED YES)
if(NOT DEFINED CMAKE_CXX_EXTENSIONS)
    set(CMAKE_CXX_EXTENSIONS NO)
endif()

set(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Filename postfix for libraries under DEBUG configuration")

option(BOOST_IS_A_PROPER_VCPKG_PORT "Boost is resolved as a proper vcpkg port (not as pre-built binaries)" YES)

add_executable(${CMAKE_PROJECT_NAME})

# seems to be redundant, as CMake 3.22 is explicitly required, so CMP0072 should already be NEW
#cmake_policy(PUSH)
#if(POLICY CMP0072)
#    cmake_policy(SET CMP0072 NEW) # prefer GLVND
#endif()
#
# vcpkg toolchain sets CMAKE_FIND_FRAMEWORK to LAST, and that leads to finding OpenGL from Homebrew,
# which then results in segmentation fault crash on application launch on Mac OS
set(CMAKE_FIND_FRAMEWORK_BACKUP ${CMAKE_FIND_FRAMEWORK})
if(
    DEFINED VCPKG_INSTALLED_DIR
    AND
    CMAKE_SYSTEM_NAME STREQUAL "Darwin"
)
    set(CMAKE_FIND_FRAMEWORK "FIRST")
endif()
find_package(OpenGL REQUIRED)
set(CMAKE_FIND_FRAMEWORK ${CMAKE_FIND_FRAMEWORK_BACKUP})
#
#cmake_policy(POP)

set(sources
    src/action.cpp
    src/bloom.cpp
    src/caption.cpp
    src/dirnode.cpp
    src/file.cpp
    src/gource.cpp
    src/gource_settings.cpp
    src/gource_shell.cpp
    src/key.cpp
    src/logmill.cpp
    src/main.cpp
    src/pawn.cpp
    src/slider.cpp
    src/spline.cpp
    src/textbox.cpp
    src/user.cpp
    src/zoomcamera.cpp
    #
    src/formats/apache.cpp
    src/formats/bzr.cpp
    src/formats/commitlog.cpp
    src/formats/custom.cpp
    src/formats/cvs-exp.cpp
    src/formats/cvs2cl.cpp
    src/formats/git.cpp
    src/formats/gitraw.cpp
    src/formats/hg.cpp
    src/formats/svn.cpp
    #
    src/core/conffile.cpp
    src/core/display.cpp
    src/core/frustum.cpp
    src/core/fxfont.cpp
    src/core/logger.cpp
    src/core/mousecursor.cpp
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
    src/core/tga.cpp
    src/core/timezone.cpp
    src/core/vbo.cpp
    src/core/vectors.cpp
)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    list(APPEND sources
        resources.rc
    )
endif()

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${sources}
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

find_package(Threads REQUIRED)
#
find_package(freetype CONFIG REQUIRED)
find_package(glew CONFIG REQUIRED)
find_package(glm CONFIG REQUIRED)
find_package(pcre CONFIG REQUIRED)
find_package(png CONFIG REQUIRED)
find_package(SDL2 CONFIG REQUIRED)
find_package(SDL2_image CONFIG REQUIRED)
find_package(tinyxml CONFIG REQUIRED)

if(BOOST_IS_A_PROPER_VCPKG_PORT)
    find_package(boost_algorithm CONFIG REQUIRED)
    find_package(boost_assign CONFIG REQUIRED)
    find_package(boost_filesystem CONFIG REQUIRED)
    find_package(boost_format CONFIG REQUIRED)
    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            Boost::algorithm
            Boost::assign
            Boost::filesystem
            Boost::format
    )
else()
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
        SDL2::SDL2_image
        SDL2::SDL2main
        tinyxml
        # these might be needed when building with MinGW
        # -lglu32
        # -static-libgcc
        # -static-libstdc++
        # -lcomdlg32
)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            NOMINMAX
    )
endif()

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
)

include(GNUInstallDirs)

install(TARGETS ${CMAKE_PROJECT_NAME})
install(DIRECTORY "data"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
    PATTERN "gource.1" EXCLUDE
    PATTERN "fonts/README" EXCLUDE
)
