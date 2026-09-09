import { HttpMethod } from './ShellModels';

export interface HttpMultipartPart {
  name: string;
  contentType: string;
  remoteFileName: string;
  data: string | ArrayBuffer;
}

export interface HttpEngineRequest {
  url: string;
  method: HttpMethod;
  headers: Record<string, string>;
  body: string | ArrayBuffer;
  multipart: HttpMultipartPart[];
  timeout: number;
  followRedirects: boolean;
  sslVerification: boolean;
}

export interface HttpEngineResponse {
  statusCode: number;
  headers: Record<string, string | Array<string>>;
  cookies: string;
  body: ArrayBuffer;
  durationMs: number;
  protocol: string;
}
