#ifndef SOME_H
#define SOME_H

#ifdef SomeLibrary_EXPORTS // CMake sets that when BUILD_SHARED_LIBS=1
    #ifdef _MSC_VER // for MSVC
        // export on compiling the DLL (when building)
        #define DLLEXPORT __declspec(dllexport)
    //#elif __GNUC__ >= 4 // for GCC
    //    #define DLLEXPORT __attribute__ ((visibility("default")))
    #endif // any other compilers require anything like that?
#else
    #ifdef _MSC_VER // for MSVC
        // import on using the created DLL (when using in projects)
        #define DLLEXPORT __declspec(dllimport)
    //#elif __GNUC__ >= 4 // for GCC
    //    // something here for GCC?
    #endif // any other compilers require anything like that?
#endif

#ifndef DLLEXPORT
    #define DLLEXPORT // so it doesn't fail being undefined
#endif

namespace lbrSome
{
    DLLEXPORT void doSome();
    DLLEXPORT void doTheThing();
}

#endif // SOME_H
