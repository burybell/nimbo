import scriptRuntime from 'libnimbo_script.so';

export type ScriptStatus = 'success' | 'error' | 'timeout' | 'memoryLimit';

export interface ScriptResult {
  status: ScriptStatus;
  value: string;
  error: string;
  durationMs: number;
  logs: string[];
}

export class ScriptRuntimeService {
  static readonly DEFAULT_TIMEOUT_MS: number = 500;
  static readonly DEFAULT_MEMORY_LIMIT_BYTES: number = 8 * 1024 * 1024;

  static async run(source: string, timeoutMs: number = ScriptRuntimeService.DEFAULT_TIMEOUT_MS,
    memoryLimitBytes: number = ScriptRuntimeService.DEFAULT_MEMORY_LIMIT_BYTES): Promise<ScriptResult> {
    return scriptRuntime.run(source, timeoutMs, memoryLimitBytes);
  }
}
