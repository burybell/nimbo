import { HttpMethod } from './ShellModels';

export interface HttpEngineRequest {
  url: string;
  method: HttpMethod;
  headers: Record<string, string>;
  body: string;
  timeout: number;
}

export interface HttpEngineResponse {
  statusCode: number;
  headers: Record<string, string | Array<string>>;
  cookies: string;
  body: string;
  durationMs: number;
  protocol: string;
}
