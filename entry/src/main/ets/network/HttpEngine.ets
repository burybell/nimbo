import { http } from '@kit.NetworkKit';
import { HttpEngineRequest, HttpEngineResponse } from '../models/NetworkModels';

class StopRedirectInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.REDIRECTION;

  async interceptorHandle(_request: http.HttpRequestContext,
    _response: http.HttpResponse): Promise<http.ChainContinue> {
    return false;
  }
}

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
    if (!request.followRedirects) {
      try {
        const interceptorChain = new http.HttpInterceptorChain();
        interceptorChain.addChain([new StopRedirectInterceptor()]);
        interceptorChain.apply(task);
      } catch (_error) {
        task.destroy();
        throw new Error('Redirect control is unavailable on this device.');
      }
    }
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
    options.remoteValidation = request.sslVerification ? 'system' : 'skip';
    if (typeof request.body === 'string') {
      if (request.body.length > 0) options.extraData = request.body;
    } else if (request.body.byteLength > 0) {
      options.extraData = request.body;
    }
    if (request.multipart.length > 0) {
      options.multiFormDataList = request.multipart.map((part) => {
        const formPart: http.MultiFormData = {
          name: part.name,
          contentType: part.contentType,
          data: part.data
        };
        if (part.remoteFileName.length > 0) formPart.remoteFileName = part.remoteFileName;
        return formPart;
      });
    }
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
