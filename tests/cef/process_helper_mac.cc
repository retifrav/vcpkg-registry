// Copyright (c) 2013 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that can
// be found in the LICENSE file.

#include <cef/cef_app.h>
#include <cef/wrapper/cef_library_loader.h>

#include "render_app.h"

// the `CEF_USE_SANDBOX` value is defined with CMake,
// pass `-DUSE_SANDBOX=0` to disable the sandbox
#if defined(CEF_USE_SANDBOX)
#include <cef/cef_sandbox_mac.h>
#endif

int main(int argc, char *argv[])
{
#if defined(CEF_USE_SANDBOX)
    CefScopedSandboxContext sandbox_context;
    if (!sandbox_context.Initialize(argc, argv))
    {
        return 1;
    }
#endif

    // load the CEF framework library at runtime instead of linking directly,
    // as required by the macOS sandbox implementation
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInHelper())
    {
        return 1;
    }

    CefMainArgs main_args(argc, argv);
    CefRefPtr<RenderApp> app(new RenderApp);
    return CefExecuteProcess(main_args, app.get(), nullptr);
}
