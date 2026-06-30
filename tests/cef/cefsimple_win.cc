// Copyright (c) 2013 The Chromium Embedded Framework Authors. All rights
// reserved. Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

#include <windows.h>

#include <cef/cef_command_line.h>
#include <cef/cef_sandbox_win.h>
#include <cef/cef_version_info.h>

#include "simple_app.h"
#include "render_app.h"

namespace {

int RunMain(HINSTANCE hInstance,
            LPTSTR lpCmdLine,
            int nCmdShow,
            void* sandbox_info) {
  int exit_code;

  // Provide CEF with command-line arguments.
  CefMainArgs main_args(hInstance);

  // `RenderApp` implements render-process callbacks, it registers the V8 bindings
  // (`PrintColorToStdout` JS function) when a render-process V8 context
  // is created. Passing it here makes those bindings available in the render
  // sub-process. The browser process ignores it (`CefExecuteProcess` returns
  // early below) and uses `SimpleApp` via `CefInitialize` instead
  CefRefPtr<RenderApp> render_app(new RenderApp);

  // CEF applications have multiple sub-processes (render, GPU, etc) that share
  // the same executable. This function checks the command-line and, if this is
  // a sub-process, executes the appropriate logic.
  exit_code = CefExecuteProcess(main_args, render_app, sandbox_info);
  if (exit_code >= 0) {
    // The sub-process has completed so return here.
    return exit_code;
  }

  // Parse command-line arguments for use in this method.
  CefRefPtr<CefCommandLine> command_line = CefCommandLine::CreateCommandLine();
  command_line->InitFromString(::GetCommandLineW());

  // Specify CEF global settings here.
  CefSettings settings;

  if (!sandbox_info) {
    settings.no_sandbox = true;
  }

  // SimpleApp implements application-level callbacks for the browser process.
  // It will create the first browser instance in OnContextInitialized() after
  // CEF has initialized.
  CefRefPtr<SimpleApp> app(new SimpleApp);

  // Initialize the CEF browser process. May return false if initialization
  // fails or if early exit is desired (for example, due to process singleton
  // relaunch behavior).
  if (!CefInitialize(main_args, settings, app.get(), sandbox_info)) {
    return CefGetExitCode();
  }

  // Run the CEF message loop. This will block until CefQuitMessageLoop() is
  // called.
  CefRunMessageLoop();

  // Shut down CEF.
  CefShutdown();

  return 0;
}

}  // namespace

#if defined(CEF_USE_BOOTSTRAP)

// Entry point called by bootstrap.exe when built as a DLL.
CEF_BOOTSTRAP_EXPORT int RunWinMain(HINSTANCE hInstance,
                                    LPTSTR lpCmdLine,
                                    int nCmdShow,
                                    void* sandbox_info,
                                    cef_version_info_t* /*version_info*/) {
  return ::RunMain(hInstance, lpCmdLine, nCmdShow, sandbox_info);
}

#else  // !defined(CEF_USE_BOOTSTRAP)

// Entry point function for all processes.
int APIENTRY wWinMain(HINSTANCE hInstance,
                      HINSTANCE hPrevInstance,
                      LPTSTR lpCmdLine,
                      int nCmdShow) {
  UNREFERENCED_PARAMETER(hPrevInstance);
  UNREFERENCED_PARAMETER(lpCmdLine);

#if defined(ARCH_CPU_32_BITS)
  // Run the main thread on 32-bit Windows using a fiber with the preferred 4MiB
  // stack size. This function must be called at the top of the executable entry
  // point function (`main()` or `wWinMain()`). It is used in combination with
  // the initial stack size of 0.5MiB configured via the `/STACK:0x80000` linker
  // flag on executable targets. This saves significant memory on threads (like
  // those in the Windows thread pool, and others) whose stack size can only be
  // controlled via the linker flag.
  int exit_code = CefRunWinMainWithPreferredStackSize(wWinMain, hInstance,
                                                      lpCmdLine, nCmdShow);
  if (exit_code >= 0) {
    // The fiber has completed so return here.
    return exit_code;
  }
#endif

  void* sandbox_info = nullptr;

#if defined(CEF_USE_SANDBOX)
  // Manage the life span of the sandbox information object. This is necessary
  // for sandbox support on Windows. See cef_sandbox_win.h for complete details.
  CefScopedSandboxInfo scoped_sandbox;
  sandbox_info = scoped_sandbox.sandbox_info();
#endif

  return ::RunMain(hInstance, lpCmdLine, nCmdShow, sandbox_info);
}

#endif  // !defined(CEF_USE_BOOTSTRAP)
