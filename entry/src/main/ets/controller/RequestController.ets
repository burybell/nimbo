import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { HttpEngine } from '../network/HttpEngine';
import { HttpEngineRequest, HttpEngineResponse } from '../models/NetworkModels';
import {
  EnvironmentModel,
  KeyValueItem,
  RequestDraft,
  ResponseErrorModel,
  ResponseModel,
  ResponseStatus
} from '../models/ShellModels';
import { createCancelledResponse, createEmptyResponse } from '../mock/ShellMockData';

export class RequestController {
  private engine: HttpEngine = new HttpEngine();
  private cancelledRequests: Set<string> = new Set<string>();

  private resolveVariables(value: string, environment: EnvironmentModel): string {
    let resolved = value;
    environment.variables.forEach((variable: KeyValueItem) => {
      if (!variable.enabled || variable.key.length === 0) return;
      resolved = resolved.split(`{{${variable.key}}}`).join(variable.value);
    });
    return resolved;
  }

  private encode(value: string): string {
    return encodeURIComponent(value);
  }

  private buildUrl(request: RequestDraft, environment: EnvironmentModel): string {
    let url = this.resolveVariables(request.url.trim(), environment);
    const query: string[] = [];
    request.params.forEach((item: KeyValueItem) => {
      if (!item.enabled || item.key.length === 0) return;
      const key = this.resolveVariables(item.key, environment);
      const value = this.resolveVariables(item.value, environment);
      query.push(`${this.encode(key)}=${this.encode(value)}`);
    });
    if (request.auth.type === 'apiKey' && request.auth.apiLocation === 'query' && request.auth.apiKey.length > 0) {
      query.push(`${this.encode(this.resolveVariables(request.auth.apiKey, environment))}=` +
        `${this.encode(this.resolveVariables(request.auth.apiValue, environment))}`);
    }
    if (query.length > 0) url += `${url.includes('?') ? '&' : '?'}${query.join('&')}`;
    return url;
  }

  private buildHeaders(request: RequestDraft, environment: EnvironmentModel): Record<string, string> {
    const headers: Record<string, string> = {};
    request.headers.forEach((item: KeyValueItem) => {
      if (!item.enabled || item.key.length === 0) return;
      headers[this.resolveVariables(item.key, environment)] = this.resolveVariables(item.value, environment);
    });
    if (request.auth.type === 'bearer' && request.auth.bearerToken.length > 0) {
      headers['Authorization'] = `Bearer ${this.resolveVariables(request.auth.bearerToken, environment)}`;
    }
    if (request.auth.type === 'basic') {
      const username = this.resolveVariables(request.auth.username, environment);
      const password = this.resolveVariables(request.auth.password, environment);
      try {
        const bytes = new util.TextEncoder().encodeInto(`${username}:${password}`);
        headers['Authorization'] = `Basic ${new util.Base64Helper().encodeToStringSync(bytes)}`;
      } catch (_error) {
        // The native request will continue without a malformed Authorization header.
      }
    }
    if (request.auth.type === 'apiKey' && request.auth.apiLocation === 'header' && request.auth.apiKey.length > 0) {
      headers[this.resolveVariables(request.auth.apiKey, environment)] =
        this.resolveVariables(request.auth.apiValue, environment);
    }
    return headers;
  }

  private hasHeader(headers: Record<string, string>, name: string): boolean {
    return Object.keys(headers).some((key: string) => key.toLowerCase() === name.toLowerCase());
  }

  private buildBody(request: RequestDraft, environment: EnvironmentModel,
    headers: Record<string, string>): string {
    if (request.method === 'GET' || request.method === 'HEAD' || request.bodyType === 'none') return '';
    if (request.bodyType === 'json') {
      if (!this.hasHeader(headers, 'content-type')) headers['Content-Type'] = 'application/json';
      return this.resolveVariables(request.bodyText, environment);
    }
    if (request.bodyType === 'text') {
      if (!this.hasHeader(headers, 'content-type')) headers['Content-Type'] = 'text/plain; charset=utf-8';
      return this.resolveVariables(request.bodyText, environment);
    }
    if (request.bodyType === 'form') {
      if (!this.hasHeader(headers, 'content-type')) {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }
      const fields: string[] = [];
      request.formItems.forEach((item: KeyValueItem) => {
        if (!item.enabled || item.key.length === 0) return;
        fields.push(`${this.encode(this.resolveVariables(item.key, environment))}=` +
          `${this.encode(this.resolveVariables(item.value, environment))}`);
      });
      return fields.join('&');
    }
    return '';
  }

  private headerItems(headers: Record<string, string | Array<string>>): KeyValueItem[] {
    const items: KeyValueItem[] = [];
    Object.keys(headers).forEach((key: string, index: number) => {
      const value: string | Array<string> = headers[key];
      items.push({
        id: `response-header-${index}`,
        enabled: true,
        key,
        value: Array.isArray(value) ? value.join(', ') : String(value),
        description: '',
        type: 'text',
        secret: false
      });
    });
    return items;
  }

  private headerValue(items: KeyValueItem[], name: string): string {
    const found = items.find((item: KeyValueItem) => item.key.toLowerCase() === name.toLowerCase());
    return found ? found.value : '';
  }

  private statusText(code: number): string {
    if (code === 200) return 'OK';
    if (code === 201) return 'Created';
    if (code === 202) return 'Accepted';
    if (code === 204) return 'No Content';
    if (code === 301) return 'Moved Permanently';
    if (code === 302) return 'Found';
    if (code === 304) return 'Not Modified';
    if (code === 400) return 'Bad Request';
    if (code === 401) return 'Unauthorized';
    if (code === 403) return 'Forbidden';
    if (code === 404) return 'Not Found';
    if (code === 409) return 'Conflict';
    if (code === 429) return 'Too Many Requests';
    if (code === 500) return 'Internal Server Error';
    if (code === 502) return 'Bad Gateway';
    if (code === 503) return 'Service Unavailable';
    if (code === 504) return 'Gateway Timeout';
    return '';
  }

  private formatSize(bytes: number): string {
    if (bytes >= 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    if (bytes >= 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${bytes} B`;
  }

  private isBinary(contentType: string): boolean {
    const type = contentType.toLowerCase();
    if (type.startsWith('text/')) return false;
    if (type.includes('json') || type.includes('xml') || type.includes('javascript') ||
      type.includes('x-www-form-urlencoded')) return false;
    return type.length > 0;
  }

  private displayBody(body: string, contentType: string): string {
    if (!contentType.toLowerCase().includes('json') || body.length === 0) return body;
    try {
      return JSON.stringify(JSON.parse(body), null, 2);
    } catch (_error) {
      return body;
    }
  }

  private responseModel(result: HttpEngineResponse): ResponseModel {
    const headers = this.headerItems(result.headers);
    const contentType = this.headerValue(headers, 'content-type');
    const size = result.body.length;
    let status: ResponseStatus = 'success';
    if (size > 10 * 1024 * 1024) status = 'large';
    else if (this.isBinary(contentType)) status = 'binary';
    return {
      status,
      statusCode: result.statusCode,
      statusText: this.statusText(result.statusCode),
      headers,
      cookies: result.cookies.length > 0 ? [{
        id: 'response-cookie', enabled: true, key: 'set-cookie', value: result.cookies,
        description: '', type: 'text', secret: false
      }] : [],
      body: status === 'binary' ? '' : this.displayBody(result.body, contentType),
      contentType,
      size: this.formatSize(size),
      duration: `${result.durationMs} ms`,
      protocol: result.protocol,
      error: { type: 'unknown', title: '', message: '', code: '', details: '' },
      previewAvailable: status === 'large'
    };
  }

  private errorModel(error: BusinessError): ResponseModel {
    const response = createEmptyResponse();
    response.status = 'error';
    let model: ResponseErrorModel = {
      type: 'unknown', title: 'Request failed', message: error.message,
      code: `${error.code}`, details: error.message
    };
    if (error.code === 2300003 || error.code === 2300001) {
      model = { type: 'invalidUrl', title: 'Invalid URL', message: error.message,
        code: `${error.code}`, details: 'Check the URL and protocol, then try again.' };
    } else if (error.code === 2300006) {
      model = { type: 'dns', title: 'DNS lookup failed', message: error.message,
        code: `${error.code}`, details: 'The host name could not be resolved.' };
    } else if (error.code === 2300007) {
      model = { type: 'connectionRefused', title: 'Connection failed', message: error.message,
        code: `${error.code}`, details: 'The remote server refused or could not accept the connection.' };
    } else if (error.code === 2300028) {
      model = { type: 'timeout', title: 'Request timed out', message: 'The request exceeded the 30 second timeout.',
        code: `${error.code}`, details: error.message };
    } else if (error.code === 2300058 || error.code === 2300059 || error.code === 2300060 ||
      error.code === 2300077) {
      model = { type: 'tls', title: 'TLS certificate verification failed', message: error.message,
        code: `${error.code}`, details: 'Review the certificate and request settings.' };
    }
    response.error = model;
    return response;
  }

  async send(id: string, request: RequestDraft, environment: EnvironmentModel): Promise<ResponseModel> {
    this.cancelledRequests.delete(id);
    if (request.bodyType === 'multipart' || request.bodyType === 'binary') {
      const unsupported = createEmptyResponse();
      unsupported.status = 'error';
      unsupported.error = {
        type: 'unknown',
        title: 'Body type not connected yet',
        message: 'Multipart and binary transfer are scheduled after the core HTTP methods.',
        code: 'UNSUPPORTED_BODY',
        details: 'Use JSON, Text, or Form for the current HTTP milestone.'
      };
      return unsupported;
    }
    const headers = this.buildHeaders(request, environment);
    const engineRequest: HttpEngineRequest = {
      url: this.buildUrl(request, environment),
      method: request.method,
      headers,
      body: this.buildBody(request, environment, headers),
      timeout: 30000
    };
    try {
      return this.responseModel(await this.engine.execute(id, engineRequest));
    } catch (error) {
      if (this.cancelledRequests.has(id)) return createCancelledResponse();
      return this.errorModel(error as BusinessError);
    }
  }

  cancel(id: string): void {
    this.cancelledRequests.add(id);
    this.engine.cancel(id);
  }
}
