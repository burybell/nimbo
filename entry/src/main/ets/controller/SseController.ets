import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { ParsedSseEvent, SseParser } from '../services/SseParser';
import { HttpMethod } from '../models/ShellModels';

export type SseControllerEventKind = 'open' | 'event' | 'end' | 'error';

export interface SseControllerEvent {
  kind: SseControllerEventKind;
  event?: ParsedSseEvent;
  code: string;
  message: string;
  statusCode: number;
  contentType: string;
}

export class SseController {
  private requests: Map<string, http.HttpRequest> = new Map<string, http.HttpRequest>();

  private errorText(error: BusinessError): string {
    return error && typeof error.message === 'string' && error.message.length > 0 ? error.message :
      'SSE connection failed';
  }

  private errorCode(error: BusinessError): string {
    return error && typeof error.code === 'number' ? `${error.code}` : 'SSE_ERROR';
  }

  private headerValue(headers: Object, name: string): string {
    const values = headers as Record<string, string | Array<string>>;
    const key = Object.keys(values).find((item: string) => item.toLowerCase() === name.toLowerCase());
    if (!key) return '';
    const value = values[key];
    return Array.isArray(value) ? value.join(', ') : `${value}`;
  }

  private requestMethod(method: HttpMethod): http.RequestMethod {
    if (method === 'POST') return http.RequestMethod.POST;
    if (method === 'PUT') return http.RequestMethod.PUT;
    if (method === 'DELETE') return http.RequestMethod.DELETE;
    if (method === 'HEAD') return http.RequestMethod.HEAD;
    if (method === 'OPTIONS') return http.RequestMethod.OPTIONS;
    return http.RequestMethod.GET;
  }

  async connect(id: string, url: string, method: HttpMethod, headers: Record<string, string>, body: string,
    timeout: number,
    onEvent: (event: SseControllerEvent) => void): Promise<void> {
    this.stop(id);
    const request = http.createHttp();
    const parser = new SseParser();
    const decoder = new util.TextDecoder();
    let opened = false;
    let ended = false;
    let statusCode = 0;
    let contentType = '';
    this.requests.set(id, request);
    request.on('headersReceive', (responseHeaders: Object) => {
      if (this.requests.get(id) !== request) return;
      contentType = this.headerValue(responseHeaders, 'content-type');
      if (!opened) {
        opened = true;
        onEvent({ kind: 'open', code: '', message: '', statusCode, contentType });
      }
    });
    request.on('dataReceive', (chunk: ArrayBuffer) => {
      if (this.requests.get(id) !== request) return;
      const text = decoder.decodeToString(new Uint8Array(chunk), { stream: true });
      parser.push(text).forEach((event: ParsedSseEvent) =>
        onEvent({ kind: 'event', event, code: '', message: '', statusCode, contentType }));
    });
    request.on('dataEnd', () => {
      if (this.requests.get(id) !== request) return;
      ended = true;
      const tail = decoder.decodeToString(new Uint8Array(0), { stream: false });
      if (tail.length > 0) parser.push(tail).forEach((event: ParsedSseEvent) =>
        onEvent({ kind: 'event', event, code: '', message: '', statusCode, contentType }));
      parser.finish().forEach((event: ParsedSseEvent) =>
        onEvent({ kind: 'event', event, code: '', message: '', statusCode, contentType }));
      if (statusCode > 0) {
        this.requests.delete(id);
        request.destroy();
        onEvent({ kind: 'end', code: '', message: '', statusCode, contentType });
      }
    });
    const requestHeaders: Record<string, string> = {};
    requestHeaders['Accept'] = 'text/event-stream';
    Object.keys(headers).forEach((key: string) => { requestHeaders[key] = headers[key]; });
    const options: http.HttpRequestOptions = {
      method: this.requestMethod(method),
      header: requestHeaders,
      connectTimeout: timeout,
      readTimeout: timeout,
      usingCache: false
    };
    if (body.length > 0) options.extraData = body;
    if (method === 'PATCH') options.method = method as http.RequestMethod;
    try {
      statusCode = await request.requestInStream(url, options);
      if (this.requests.get(id) === request && !opened) {
        opened = true;
        onEvent({ kind: 'open', code: '', message: '', statusCode, contentType });
      }
      if (statusCode >= 400 && this.requests.get(id) === request) {
        this.requests.delete(id);
        request.destroy();
        onEvent({ kind: 'error', code: `HTTP_${statusCode}`, message: `HTTP ${statusCode}`,
          statusCode, contentType });
      } else if (ended && this.requests.get(id) === request) {
        this.requests.delete(id);
        request.destroy();
        onEvent({ kind: 'end', code: '', message: '', statusCode, contentType });
      }
    } catch (error) {
      if (this.requests.get(id) !== request) return;
      this.requests.delete(id);
      request.destroy();
      const failure = error as BusinessError;
      onEvent({ kind: 'error', code: this.errorCode(failure), message: this.errorText(failure),
        statusCode, contentType });
    }
  }

  stop(id: string): void {
    const request = this.requests.get(id);
    if (!request) return;
    this.requests.delete(id);
    request.destroy();
  }

  stopAll(): void {
    this.requests.forEach((request: http.HttpRequest) => request.destroy());
    this.requests.clear();
  }
}
