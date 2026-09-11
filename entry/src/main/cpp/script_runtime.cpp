#include <napi/native_api.h>
#include <quickjs.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <string>
#include <vector>

namespace {

constexpr int32_t kDefaultTimeoutMs = 500;
constexpr int32_t kMaximumTimeoutMs = 5000;
constexpr uint32_t kDefaultMemoryLimit = 8 * 1024 * 1024;
constexpr uint32_t kMinimumMemoryLimit = 1024 * 1024;
constexpr uint32_t kMaximumMemoryLimit = 64 * 1024 * 1024;
constexpr size_t kMaximumLogEntries = 200;
constexpr size_t kMaximumLogBytes = 64 * 1024;
constexpr size_t kMaximumStackBytes = 512 * 1024;
constexpr size_t kMaximumSourceBytes = 1024 * 1024;
constexpr uint32_t kMaximumConcurrentScripts = 2;

std::atomic<uint32_t> activeScripts{0};

struct ScriptWork {
  napi_env env = nullptr;
  napi_async_work work = nullptr;
  napi_deferred deferred = nullptr;
  std::string source;
  int32_t timeoutMs = kDefaultTimeoutMs;
  uint32_t memoryLimitBytes = kDefaultMemoryLimit;
  std::string status = "error";
  std::string value;
  std::string error;
  int32_t durationMs = 0;
  std::vector<std::string> logs;
  size_t logBytes = 0;
  bool interrupted = false;
  std::chrono::steady_clock::time_point deadline;
};

std::string JsValueToString(JSContext* context, JSValueConst value) {
  const char* text = JS_ToCString(context, value);
  if (text == nullptr) {
    return {};
  }
  std::string result(text);
  JS_FreeCString(context, text);
  return result;
}

int InterruptHandler(JSRuntime*, void* opaque) {
  auto* state = static_cast<ScriptWork*>(opaque);
  if (std::chrono::steady_clock::now() < state->deadline) {
    return 0;
  }
  state->interrupted = true;
  return 1;
}

JSValue ConsoleLog(JSContext* context, JSValueConst, int argc, JSValueConst* argv) {
  auto* state = static_cast<ScriptWork*>(JS_GetContextOpaque(context));
  if (state == nullptr || state->logs.size() >= kMaximumLogEntries || state->logBytes >= kMaximumLogBytes) {
    return JS_UNDEFINED;
  }
  std::string line;
  for (int index = 0; index < argc; ++index) {
    if (!line.empty()) {
      line.push_back(' ');
    }
    line.append(JsValueToString(context, argv[index]));
  }
  const size_t remaining = kMaximumLogBytes - state->logBytes;
  if (line.size() > remaining) {
    line.resize(remaining);
  }
  state->logBytes += line.size();
  state->logs.push_back(std::move(line));
  return JS_UNDEFINED;
}

void InstallConsole(JSContext* context) {
  JSValue global = JS_GetGlobalObject(context);
  JSValue console = JS_NewObject(context);
  JS_SetPropertyStr(context, console, "log", JS_NewCFunction(context, ConsoleLog, "log", 1));
  JS_SetPropertyStr(context, console, "info", JS_NewCFunction(context, ConsoleLog, "info", 1));
  JS_SetPropertyStr(context, console, "warn", JS_NewCFunction(context, ConsoleLog, "warn", 1));
  JS_SetPropertyStr(context, console, "error", JS_NewCFunction(context, ConsoleLog, "error", 1));
  JS_SetPropertyStr(context, global, "console", console);
  JS_FreeValue(context, global);
}

std::string ExceptionText(JSContext* context, bool& memoryLimit) {
  JSValue exception = JS_GetException(context);
  memoryLimit = JS_IsNull(exception) || JS_IsUndefined(exception);
  std::string message = JsValueToString(context, exception);
  if (message.find("out of memory") != std::string::npos) {
    memoryLimit = true;
  }
  JSValue stack = JS_GetPropertyStr(context, exception, "stack");
  if (!JS_IsUndefined(stack)) {
    const std::string stackText = JsValueToString(context, stack);
    if (!stackText.empty() && stackText != message) {
      if (!message.empty()) {
        message.append("\n");
      }
      message.append(stackText);
    }
  }
  JS_FreeValue(context, stack);
  JS_FreeValue(context, exception);
  return message;
}

void ExecuteScript(napi_env, void* data) {
  auto* state = static_cast<ScriptWork*>(data);
  const auto startedAt = std::chrono::steady_clock::now();
  state->deadline = startedAt + std::chrono::milliseconds(state->timeoutMs);

  JSRuntime* runtime = JS_NewRuntime();
  if (runtime == nullptr) {
    state->status = "memoryLimit";
    state->error = "Unable to create script runtime";
    return;
  }
  JS_SetRuntimeOpaque(runtime, state);
  JS_SetMemoryLimit(runtime, state->memoryLimitBytes);
  JS_SetMaxStackSize(runtime, kMaximumStackBytes);
  JS_SetInterruptHandler(runtime, InterruptHandler, state);

  JSContext* context = JS_NewContext(runtime);
  if (context == nullptr) {
    state->status = "memoryLimit";
    state->error = "Unable to create script context";
    JS_FreeRuntime(runtime);
    return;
  }
  JS_SetContextOpaque(context, state);
  InstallConsole(context);

  JSValue result = JS_Eval(context, state->source.data(), state->source.size(), "nimbo-script.js",
    JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(result)) {
    bool memoryLimit = false;
    state->error = ExceptionText(context, memoryLimit);
    if (state->interrupted) {
      state->status = "timeout";
      state->error = "Script execution timed out";
    } else if (memoryLimit) {
      state->status = "memoryLimit";
      state->error = "Script exceeded its memory limit";
    } else {
      state->status = "error";
    }
  } else {
    state->status = "success";
    if (!JS_IsUndefined(result)) {
      state->value = JsValueToString(context, result);
    }
  }
  JS_FreeValue(context, result);
  JS_FreeContext(context);
  JS_FreeRuntime(runtime);

  state->durationMs = static_cast<int32_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
    std::chrono::steady_clock::now() - startedAt).count());
}

void SetString(napi_env env, napi_value object, const char* name, const std::string& value) {
  napi_value text;
  napi_create_string_utf8(env, value.c_str(), value.size(), &text);
  napi_set_named_property(env, object, name, text);
}

void CompleteScript(napi_env env, napi_status completionStatus, void* data) {
  auto* state = static_cast<ScriptWork*>(data);
  napi_value result;
  napi_create_object(env, &result);
  if (completionStatus != napi_ok) {
    state->status = "error";
    state->error = "Native script worker failed";
  }
  SetString(env, result, "status", state->status);
  SetString(env, result, "value", state->value);
  SetString(env, result, "error", state->error);

  napi_value duration;
  napi_create_int32(env, state->durationMs, &duration);
  napi_set_named_property(env, result, "durationMs", duration);

  napi_value logs;
  napi_create_array_with_length(env, state->logs.size(), &logs);
  for (size_t index = 0; index < state->logs.size(); ++index) {
    napi_value line;
    napi_create_string_utf8(env, state->logs[index].c_str(), state->logs[index].size(), &line);
    napi_set_element(env, logs, index, line);
  }
  napi_set_named_property(env, result, "logs", logs);
  napi_resolve_deferred(env, state->deferred, result);
  napi_delete_async_work(env, state->work);
  activeScripts.fetch_sub(1);
  delete state;
}

bool ReadString(napi_env env, napi_value value, std::string& output) {
  napi_valuetype type;
  if (napi_typeof(env, value, &type) != napi_ok || type != napi_string) {
    return false;
  }
  size_t length = 0;
  if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
    return false;
  }
  std::vector<char> buffer(length + 1);
  if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &length) != napi_ok) {
    return false;
  }
  output.assign(buffer.data(), length);
  return true;
}

napi_value Run(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value argv[3] = {nullptr, nullptr, nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  if (argc < 1) {
    napi_throw_type_error(env, nullptr, "Script source is required");
    return nullptr;
  }

  auto* state = new ScriptWork();
  state->env = env;
  if (!ReadString(env, argv[0], state->source)) {
    delete state;
    napi_throw_type_error(env, nullptr, "Script source must be a string");
    return nullptr;
  }
  if (state->source.size() > kMaximumSourceBytes) {
    delete state;
    napi_throw_range_error(env, nullptr, "Script source exceeds 1 MB");
    return nullptr;
  }
  if (argc >= 2) {
    int32_t timeout = 0;
    if (napi_get_value_int32(env, argv[1], &timeout) == napi_ok) {
      state->timeoutMs = std::clamp(timeout, 1, kMaximumTimeoutMs);
    }
  }
  if (argc >= 3) {
    uint32_t memoryLimit = 0;
    if (napi_get_value_uint32(env, argv[2], &memoryLimit) == napi_ok) {
      state->memoryLimitBytes = std::clamp(memoryLimit, kMinimumMemoryLimit, kMaximumMemoryLimit);
    }
  }

  const uint32_t previousActive = activeScripts.fetch_add(1);
  if (previousActive >= kMaximumConcurrentScripts) {
    activeScripts.fetch_sub(1);
    delete state;
    napi_throw_error(env, nullptr, "Too many scripts are already running");
    return nullptr;
  }
  napi_value promise;
  napi_create_promise(env, &state->deferred, &promise);
  napi_value resourceName;
  napi_create_string_utf8(env, "NimboScript", NAPI_AUTO_LENGTH, &resourceName);
  if (napi_create_async_work(env, nullptr, resourceName, ExecuteScript, CompleteScript, state,
    &state->work) != napi_ok) {
    activeScripts.fetch_sub(1);
    delete state;
    napi_throw_error(env, nullptr, "Unable to start script worker");
    return nullptr;
  }
  if (napi_queue_async_work(env, state->work) != napi_ok) {
    napi_delete_async_work(env, state->work);
    activeScripts.fetch_sub(1);
    delete state;
    napi_throw_error(env, nullptr, "Unable to queue script worker");
    return nullptr;
  }
  return promise;
}

napi_value Init(napi_env env, napi_value exports) {
  napi_property_descriptor properties[] = {
    {"run", nullptr, Run, nullptr, nullptr, nullptr, napi_default, nullptr},
  };
  napi_define_properties(env, exports, sizeof(properties) / sizeof(properties[0]), properties);
  return exports;
}

}  // namespace

EXTERN_C_START
static napi_module nimboScriptModule = {
  .nm_version = 1,
  .nm_flags = 0,
  .nm_filename = nullptr,
  .nm_register_func = Init,
  .nm_modname = "nimbo_script",
  .nm_priv = nullptr,
  .reserved = {nullptr},
};
EXTERN_C_END

extern "C" __attribute__((constructor)) void RegisterNimboScriptModule() {
  napi_module_register(&nimboScriptModule);
}
