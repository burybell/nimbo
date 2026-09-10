import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { HttpEngine } from '../network/HttpEngine';
import { HttpEngineRequest, HttpEngineResponse, HttpMultipartPart } from '../models/NetworkModels';
import {
  EnvironmentModel,
  KeyValueItem,
  RequestDraft,
  ResponseErrorModel,
  ResponseMediaKind,
  ResponseModel,
  ResponseStatus
} from '../models/ShellModels';
import { createCancelledResponse, createEmptyResponse } from '../mock/ShellMockData';

export class RequestController {
  private engine: HttpEngine = new HttpEngine();
  private cancelledRequests: Set<string> = new Set<string>();
  private cookieJar: Map<string, Map<string, string>> = new Map<string, Map<string, string>>();
  private readonly maxUploadBytes: number = 32 * 1024 * 1024;

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

  private hostKey(url: string): string {
    const scheme = url.indexOf('://');
    const start = scheme >= 0 ? scheme + 3 : 0;
    const slash = url.indexOf('/', start);
    return url.substring(start, slash >= 0 ? slash : url.length).toLowerCase();
  }

  private cookieHeader(url: string): string {
    const cookies = this.cookieJar.get(this.hostKey(url));
    if (!cookies) return '';
    const values: string[] = [];
    cookies.forEach((value: string, name: string) => values.push(`${name}=${value}`));
    return values.join('; ');
  }

  private storeCookies(url: string, responseCookies: string): void {
    if (responseCookies.length === 0) return;
    const host = this.hostKey(url);
    const cookies = this.cookieJar.get(host) ?? new Map<string, string>();
    responseCookies.split('\n').forEach((line: string) => {
      const pair = line.trim().split(';')[0];
      const separator = pair.indexOf('=');
      if (separator <= 0) return;
      const name = pair.substring(0, separator).trim();
      const value = pair.substring(separator + 1).trim();
      if (value.length === 0) cookies.delete(name);
      else cookies.set(name, value);
    });
    this.cookieJar.set(host, cookies);
  }

  private fileName(uri: string): string {
    const slash = uri.lastIndexOf('/');
    const name = slash >= 0 ? uri.substring(slash + 1) : uri;
    try {
      return decodeURIComponent(name);
    } catch (_error) {
      return name;
    }
  }

  private async readFile(uri: string): Promise<ArrayBuffer> {
    let descriptor = -1;
    try {
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      descriptor = file.fd;
      const stat = await fileIo.stat(descriptor);
      if (stat.size > this.maxUploadBytes) {
        throw new Error('The selected file exceeds the 32 MB upload limit.');
      }
      const buffer = new ArrayBuffer(stat.size);
      const bytesRead = await fileIo.read(descriptor, buffer);
      return bytesRead === stat.size ? buffer : buffer.slice(0, bytesRead);
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('The selected file could not be read.');
    } finally {
      if (descriptor >= 0) {
        try {
          fileIo.closeSync(descriptor);
        } catch (_error) {
          // The descriptor may already be closed after an I/O failure.
        }
      }
    }
  }

  private async buildMultipart(request: RequestDraft,
    environment: EnvironmentModel): Promise<HttpMultipartPart[]> {
    const parts: HttpMultipartPart[] = [];
    for (let index = 0; index < request.multipartItems.length; index += 1) {
      const item = request.multipartItems[index];
      if (!item.enabled || item.key.length === 0) continue;
      if (item.type === 'file') {
        if (item.value.length === 0) continue;
        parts.push({
          name: this.resolveVariables(item.key, environment),
          contentType: 'application/octet-stream',
          remoteFileName: this.fileName(item.value),
          data: await this.readFile(item.value)
        });
      } else {
        parts.push({
          name: this.resolveVariables(item.key, environment),
          contentType: 'text/plain; charset=utf-8',
          remoteFileName: '',
          data: this.resolveVariables(item.value, environment)
        });
      }
    }
    return parts;
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

  private mediaKind(contentType: string): ResponseMediaKind {
    const type = contentType.toLowerCase();
    if (type.startsWith('image/')) return 'image';
    if (type.startsWith('video/')) return 'video';
    return 'none';
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
    const size = result.body.byteLength;
    const mediaKind = this.mediaKind(contentType);
    let status: ResponseStatus = 'success';
    if (this.isBinary(contentType)) status = 'binary';
    else if (size > 10 * 1024 * 1024) status = 'large';
    const text = status === 'binary' ? '' :
      new util.TextDecoder().decodeToString(new Uint8Array(result.body));
    return {
      status,
      statusCode: result.statusCode,
      statusText: this.statusText(result.statusCode),
      headers,
      cookies: result.cookies.length > 0 ? [{
        id: 'response-cookie', enabled: true, key: 'set-cookie', value: result.cookies,
        description: '', type: 'text', secret: false
      }] : [],
      body: status === 'binary' ? '' : this.displayBody(text, contentType),
      binaryBody: status === 'binary' ? result.body : new ArrayBuffer(0),
      mediaKind,
      mediaUri: '',
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
    const code = error.code === undefined ? 'CLIENT_ERROR' : `${error.code}`;
    let model: ResponseErrorModel = {
      type: 'unknown', title: 'Request failed', message: error.message,
      code, details: error.message
    };
    if (error.message.includes('selected file') || error.message.includes('upload limit')) {
      model = { type: 'unknown', title: 'File upload failed', message: error.message,
        code, details: 'Choose a readable file no larger than 32 MB.' };
    }
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
      model = { type: 'timeout', title: 'Request timed out', message: 'The request exceeded its configured timeout.',
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
    try {
      const url = this.buildUrl(request, environment);
      const headers = this.buildHeaders(request, environment);
      if (request.settings.useCookieJar && !this.hasHeader(headers, 'cookie')) {
        const cookie = this.cookieHeader(url);
        if (cookie.length > 0) headers['Cookie'] = cookie;
      }
      let body: string | ArrayBuffer = this.buildBody(request, environment, headers);
      let multipart: HttpMultipartPart[] = [];
      if (request.method !== 'GET' && request.method !== 'HEAD' && request.bodyType === 'binary' &&
        request.binaryFileName.length > 0) {
        body = await this.readFile(request.binaryFileName);
        if (!this.hasHeader(headers, 'content-type')) headers['Content-Type'] = 'application/octet-stream';
      } else if (request.method !== 'GET' && request.method !== 'HEAD' && request.bodyType === 'multipart') {
        multipart = await this.buildMultipart(request, environment);
      }
      const engineRequest: HttpEngineRequest = {
        url,
        method: request.method,
        headers,
        body,
        multipart,
        timeout: request.settings.timeoutMs,
        followRedirects: request.settings.followRedirects,
        sslVerification: request.settings.sslVerification
      };
      const result = await this.engine.execute(id, engineRequest);
      if (request.settings.useCookieJar) this.storeCookies(url, result.cookies);
      return this.responseModel(result);
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
