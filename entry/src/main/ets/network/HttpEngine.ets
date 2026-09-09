import { http } from '@kit.NetworkKit';
import { HttpEngineRequest, HttpEngineResponse } from '../models/NetworkModels';

export class HttpEngine {
  private activeRequests: Map<string, http.HttpRequest> = new Map<string, http.HttpRequest>();

  private requestMethod(method: string): http.RequestMethod {
    if (method === 'POST') return http.RequestMethod.POST;
    if (method === 'PUT') return http.RequestMethod.PUT;
    if (method === 'DELETE') return http.RequestMethod.DELETE;
    if (method === 'HEAD') return http.RequestMethod.HEAD;
    if (method === 'OPTIONS') return http.RequestMethod.OPTIONS;
    return http.RequestMethod.GET;
  }

  async execute(id: string, request: HttpEngineRequest): Promise<HttpEngineResponse> {
    this.cancel(id);
    const task = http.createHttp();
    this.activeRequests.set(id, task);
    const startedAt = Date.now();
    const options: http.HttpRequestOptions = {
      method: this.requestMethod(request.method),
      header: request.headers,
      readTimeout: request.timeout,
      connectTimeout: request.timeout,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      maxLimit: 12 * 1024 * 1024
    };
    if (request.method === 'PATCH') options.method = request.method as http.RequestMethod;
    if (request.body.length > 0) options.extraData = request.body;
    try {
      const response = await task.request(request.url, options);
      let body = '';
      if (typeof response.result === 'string') body = response.result;
      return {
        statusCode: Number(response.responseCode),
        headers: response.header as Record<string, string | Array<string>>,
        cookies: response.cookies,
        body,
        durationMs: Date.now() - startedAt,
        protocol: response.connectionExtraInfo ? response.connectionExtraInfo.networkProtocolName : 'HTTP'
      };
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('Unknown HTTP engine error');
    } finally {
      if (this.activeRequests.get(id) === task) {
        task.destroy();
        this.activeRequests.delete(id);
      }
    }
  }

  cancel(id: string): void {
    const task = this.activeRequests.get(id);
    if (task) {
      task.destroy();
      this.activeRequests.delete(id);
    }
  }
}
