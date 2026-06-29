#ifndef CEF_TESTS_CEFSIMPLE_RENDER_APP_H_
#define CEF_TESTS_CEFSIMPLE_RENDER_APP_H_

#include <cef/cef_app.h>
#include <cef/cef_v8.h>

// application-level callbacks for the render process
class RenderApp : public CefApp,
                  public CefRenderProcessHandler
{
public:
    RenderApp();

    CefRefPtr<CefRenderProcessHandler> GetRenderProcessHandler() override
    {
        return this;
    }

    void OnContextCreated(
        CefRefPtr<CefBrowser> browser,
        CefRefPtr<CefFrame> frame,
        CefRefPtr<CefV8Context> context
    ) override;

private:
    IMPLEMENT_REFCOUNTING(RenderApp);
};

#endif  // CEF_TESTS_CEFSIMPLE_RENDER_APP_H_
