#include "render_app.h"

#include <string>

#include <cef/cef_v8.h>
#include <cef/base/cef_logging.h>

namespace {

class SomeV8Handler : public CefV8Handler
{
public:
    bool Execute(
        const CefString &name,
        CefRefPtr<CefV8Value> object,
        const CefV8ValueList &arguments,
        CefRefPtr<CefV8Value> &retval,
        CefString &exception
    ) override
    {
        const std::string ourFunctionName = "PrintColorToStdout";
        if (name == ourFunctionName)
        {
            LOG(INFO) << "[C++] JS side called " << ourFunctionName << "() function";
            if (!arguments.empty() && arguments[0]->IsString())
            {
                std::string input = arguments[0]->GetStringValue();
                const std::string msg = "got a value from JS side";
                LOG(INFO) << "[C++] " << msg << ": " << input;
                retval = CefV8Value::CreateString(msg + " - " + input);
            }
            else
            {
                const std::string msg = "no value was passed from JS side";
                LOG(INFO) << "[C++] " << msg;
                retval = CefV8Value::CreateString(msg);
            }
            return true;
        }
        return false;
    }

    IMPLEMENT_REFCOUNTING(SomeV8Handler);
};

}  // namespace

RenderApp::RenderApp() = default;

void RenderApp::OnContextCreated(
    CefRefPtr<CefBrowser> browser,
    CefRefPtr<CefFrame> frame,
    CefRefPtr<CefV8Context> context
)
{
    CefRefPtr<CefV8Value> global = context->GetGlobal();
    CefRefPtr<CefV8Handler> handler = new SomeV8Handler();

    CefRefPtr<CefV8Value> func = CefV8Value::CreateFunction("PrintColorToStdout", handler);

    global->SetValue("PrintColorToStdout", func, V8_PROPERTY_ATTRIBUTE_NONE);
}
