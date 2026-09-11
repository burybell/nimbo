export type NativeScriptStatus = 'success' | 'error' | 'timeout' | 'memoryLimit';

export interface NativeScriptResult {
  status: NativeScriptStatus;
  value: string;
  error: string;
  durationMs: number;
  logs: string[];
}

export const run: (source: string, timeoutMs?: number, memoryLimitBytes?: number) => Promise<NativeScriptResult>;
