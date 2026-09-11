import scriptRuntime from 'libnimbo_script.so';

export type ScriptStatus = 'success' | 'error' | 'timeout' | 'memoryLimit';

export interface ScriptResult {
  status: ScriptStatus;
  value: string;
  error: string;
  durationMs: number;
  logs: string[];
}

export interface ScriptRequestSnapshot {
  method: string;
  url: string;
  bodyType: string;
  body: string;
  headers: Record<string, string>;
}

export interface ScriptEnvironmentSnapshot {
  available: boolean;
  values: Record<string, string>;
}

interface PreRequestPayload {
  request: ScriptRequestSnapshot;
  environmentWrites: Record<string, string>;
}

export interface PreRequestExecution {
  result: ScriptResult;
  request: ScriptRequestSnapshot;
  environmentWrites: Record<string, string>;
}

export interface ScriptResponseSnapshot {
  statusCode: number;
  statusText: string;
  body: string;
  headers: Record<string, string>;
  contentType: string;
  size: string;
  duration: string;
  protocol: string;
}

interface PostResponsePayload {
  environmentWrites: Record<string, string>;
}

export interface PostResponseExecution {
  result: ScriptResult;
  environmentWrites: Record<string, string>;
}

export class ScriptRuntimeService {
  static readonly DEFAULT_TIMEOUT_MS: number = 500;
  static readonly DEFAULT_MEMORY_LIMIT_BYTES: number = 8 * 1024 * 1024;

  static async run(source: string, timeoutMs: number = ScriptRuntimeService.DEFAULT_TIMEOUT_MS,
    memoryLimitBytes: number = ScriptRuntimeService.DEFAULT_MEMORY_LIMIT_BYTES): Promise<ScriptResult> {
    return scriptRuntime.run(source, timeoutMs, memoryLimitBytes);
  }

  private static wrappedPreRequestSource(source: string, request: ScriptRequestSnapshot,
    environment: ScriptEnvironmentSnapshot): string {
    const input = JSON.stringify({ request, environment });
    const inputLiteral = JSON.stringify(input);
    const sourceLiteral = JSON.stringify(source);
    return `(() => {
  'use strict';
  const state = JSON.parse(${inputLiteral});
  const environmentWrites = {};
  const headerName = (name) => Object.keys(state.request.headers)
    .find((key) => key.toLowerCase() === String(name).toLowerCase());
  const headers = Object.freeze({
    get: (name) => { const key = headerName(name); return key === undefined ? undefined : state.request.headers[key]; },
    set: (name, value) => {
      const normalized = String(name).trim();
      if (normalized.length === 0) throw new TypeError('Header name cannot be empty');
      const previous = headerName(normalized);
      if (previous !== undefined && previous !== normalized) delete state.request.headers[previous];
      state.request.headers[normalized] = String(value);
    },
    remove: (name) => { const key = headerName(name); if (key !== undefined) delete state.request.headers[key]; }
  });
  const requestApi = {};
  Object.defineProperties(requestApi, {
    method: { enumerable: true, get: () => state.request.method, set: (value) => { state.request.method = String(value).toUpperCase(); } },
    url: { enumerable: true, get: () => state.request.url, set: (value) => { state.request.url = String(value); } },
    body: { enumerable: true, get: () => state.request.body, set: (value) => {
      state.request.body = String(value);
      if (state.request.bodyType === 'none') state.request.bodyType = 'text';
    } },
    bodyType: { enumerable: true, get: () => state.request.bodyType,
      set: (value) => { state.request.bodyType = String(value); } },
    headers: { enumerable: true, value: headers }
  });
  const environmentApi = Object.freeze({
    get: (name) => state.environment.values[String(name)],
    set: (name, value) => {
      if (!state.environment.available) throw new Error('No active environment');
      const normalized = String(name).trim();
      if (normalized.length === 0) throw new TypeError('Environment variable name cannot be empty');
      const text = String(value);
      state.environment.values[normalized] = text;
      environmentWrites[normalized] = text;
    }
  });
  Object.defineProperty(globalThis, 'nimbo', {
    value: Object.freeze({ request: Object.freeze(requestApi), environment: environmentApi }),
    writable: false, configurable: false
  });
  Function(${sourceLiteral})();
  return JSON.stringify({ request: state.request, environmentWrites });
})()`;
  }

  private static validMethod(method: string): boolean {
    return method === 'GET' || method === 'POST' || method === 'PUT' || method === 'PATCH' ||
      method === 'DELETE' || method === 'HEAD' || method === 'OPTIONS';
  }

  static async runPreRequest(source: string, request: ScriptRequestSnapshot,
    environment: ScriptEnvironmentSnapshot): Promise<PreRequestExecution> {
    const result = await ScriptRuntimeService.run(
      ScriptRuntimeService.wrappedPreRequestSource(source, request, environment));
    if (result.status !== 'success') return { result, request, environmentWrites: {} };
    try {
      const payload = JSON.parse(result.value) as PreRequestPayload;
      if (payload.request === undefined || !ScriptRuntimeService.validMethod(payload.request.method) ||
        typeof payload.request.url !== 'string' || typeof payload.request.body !== 'string' ||
        payload.request.headers === undefined || payload.environmentWrites === undefined) {
        throw new Error('Script returned an invalid request');
      }
      return { result, request: payload.request, environmentWrites: payload.environmentWrites };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to read script output';
      return {
        result: { status: 'error', value: '', error: message, durationMs: result.durationMs, logs: result.logs },
        request,
        environmentWrites: {}
      };
    }
  }

  private static wrappedPostResponseSource(source: string, response: ScriptResponseSnapshot,
    environment: ScriptEnvironmentSnapshot): string {
    const input = JSON.stringify({ response, environment });
    const inputLiteral = JSON.stringify(input);
    const sourceLiteral = JSON.stringify(source);
    return `(() => {
  'use strict';
  const state = JSON.parse(${inputLiteral});
  const environmentWrites = {};
  const headerName = (name) => Object.keys(state.response.headers)
    .find((key) => key.toLowerCase() === String(name).toLowerCase());
  const headers = Object.freeze({
    get: (name) => { const key = headerName(name); return key === undefined ? undefined : state.response.headers[key]; }
  });
  const responseApi = Object.freeze({
    statusCode: state.response.statusCode,
    statusText: state.response.statusText,
    body: state.response.body,
    headers,
    contentType: state.response.contentType,
    size: state.response.size,
    duration: state.response.duration,
    protocol: state.response.protocol
  });
  const environmentApi = Object.freeze({
    get: (name) => state.environment.values[String(name)],
    set: (name, value) => {
      if (!state.environment.available) throw new Error('No active environment');
      const normalized = String(name).trim();
      if (normalized.length === 0) throw new TypeError('Environment variable name cannot be empty');
      const text = String(value);
      state.environment.values[normalized] = text;
      environmentWrites[normalized] = text;
    }
  });
  Object.defineProperty(globalThis, 'nimbo', {
    value: Object.freeze({ response: responseApi, environment: environmentApi }),
    writable: false, configurable: false
  });
  Function(${sourceLiteral})();
  return JSON.stringify({ environmentWrites });
})()`;
  }

  static async runPostResponse(source: string, response: ScriptResponseSnapshot,
    environment: ScriptEnvironmentSnapshot): Promise<PostResponseExecution> {
    const result = await ScriptRuntimeService.run(
      ScriptRuntimeService.wrappedPostResponseSource(source, response, environment));
    if (result.status !== 'success') return { result, environmentWrites: {} };
    try {
      const payload = JSON.parse(result.value) as PostResponsePayload;
      if (payload.environmentWrites === undefined) throw new Error('Script returned an invalid result');
      return { result, environmentWrites: payload.environmentWrites };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to read script output';
      return {
        result: { status: 'error', value: '', error: message, durationMs: result.durationMs, logs: result.logs },
        environmentWrites: {}
      };
    }
  }
}
