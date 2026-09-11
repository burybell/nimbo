import { KeyValueItem, RequestDraft } from '../models/ShellModels';
import { CurlCodec } from './CurlCodec';

export type RequestCodeLanguage = 'curl' | 'javascript' | 'python' | 'go';

interface GeneratedHeader {
  key: string;
  value: string;
}

export class RequestCodeGenerator {
  private static quote(value: string, delimiter: string): string {
    return value.replaceAll('\\', '\\\\').replaceAll(delimiter, `\\${delimiter}`)
      .replaceAll('\r', '\\r').replaceAll('\n', '\\n');
  }

  private static encoded(value: string): string {
    return value.includes('{{') ? value : encodeURIComponent(value);
  }

  private static url(request: RequestDraft): string {
    const pairs: string[] = [];
    request.params.filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
      .forEach((item: KeyValueItem) => pairs.push(
        `${RequestCodeGenerator.encoded(item.key)}=${RequestCodeGenerator.encoded(item.value)}`));
    if (request.auth.type === 'apiKey' && request.auth.apiLocation === 'query' && request.auth.apiKey.length > 0) {
      pairs.push(`${RequestCodeGenerator.encoded(request.auth.apiKey)}=` +
        `${RequestCodeGenerator.encoded(request.auth.apiValue)}`);
    }
    if (pairs.length === 0) return request.url;
    return `${request.url}${request.url.includes('?') ? '&' : '?'}${pairs.join('&')}`;
  }

  private static hasHeader(headers: GeneratedHeader[], name: string): boolean {
    return headers.some((item: GeneratedHeader) => item.key.toLowerCase() === name.toLowerCase());
  }

  private static headers(request: RequestDraft): GeneratedHeader[] {
    const headers: GeneratedHeader[] = request.headers
      .filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
      .map((item: KeyValueItem): GeneratedHeader => ({ key: item.key, value: item.value }));
    if (request.auth.type === 'bearer') {
      headers.push({ key: 'Authorization', value: `Bearer ${request.auth.bearerToken}` });
    } else if (request.auth.type === 'apiKey' && request.auth.apiLocation === 'header' &&
      request.auth.apiKey.length > 0) {
      headers.push({ key: request.auth.apiKey, value: request.auth.apiValue });
    }
    if (request.bodyType === 'json' && !RequestCodeGenerator.hasHeader(headers, 'Content-Type')) {
      headers.push({ key: 'Content-Type', value: 'application/json' });
    }
    if (request.bodyType === 'form' && !RequestCodeGenerator.hasHeader(headers, 'Content-Type')) {
      headers.push({ key: 'Content-Type', value: 'application/x-www-form-urlencoded' });
    }
    return headers;
  }

  private static formBody(request: RequestDraft): string {
    return request.formItems.filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
      .map((item: KeyValueItem) => `${RequestCodeGenerator.encoded(item.key)}=` +
        `${RequestCodeGenerator.encoded(item.value)}`).join('&');
  }

  private static textBody(request: RequestDraft): string {
    if (request.bodyType === 'json' || request.bodyType === 'text') return request.bodyText;
    if (request.bodyType === 'form') return RequestCodeGenerator.formBody(request);
    return '';
  }

  private static javascript(request: RequestDraft): string {
    const lines: string[] = [];
    if (request.bodyType === 'multipart') {
      lines.push('const formData = new FormData();');
      request.multipartItems.filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
        .forEach((item: KeyValueItem) => {
          const key = RequestCodeGenerator.quote(item.key, "'");
          if (item.type === 'file') lines.push(`formData.append('${key}', file); // ${item.value}`);
          else lines.push(`formData.append('${key}', '${RequestCodeGenerator.quote(item.value, "'")}');`);
        });
      lines.push('');
    }
    lines.push(`const response = await fetch('${RequestCodeGenerator.quote(RequestCodeGenerator.url(request), "'")}', {`);
    lines.push(`  method: '${request.method}',`);
    const headers = RequestCodeGenerator.headers(request);
    if (headers.length > 0 || request.auth.type === 'basic') {
      lines.push('  headers: {');
      headers.forEach((item: GeneratedHeader) => lines.push(
        `    '${RequestCodeGenerator.quote(item.key, "'")}': '${RequestCodeGenerator.quote(item.value, "'")}',`));
      if (request.auth.type === 'basic') {
        const credentials = RequestCodeGenerator.quote(`${request.auth.username}:${request.auth.password}`, "'");
        lines.push(`    'Authorization': 'Basic ' + btoa('${credentials}'),`);
      }
      lines.push('  },');
    }
    if (request.bodyType === 'multipart') lines.push('  body: formData,');
    else {
      const body = RequestCodeGenerator.textBody(request);
      if (body.length > 0) lines.push(`  body: '${RequestCodeGenerator.quote(body, "'")}',`);
    }
    lines.push('});');
    lines.push('');
    lines.push('const data = await response.text();');
    lines.push('console.log(response.status, data);');
    return lines.join('\n');
  }

  private static python(request: RequestDraft): string {
    const lines: string[] = ['import requests', ''];
    const headers = RequestCodeGenerator.headers(request);
    if (headers.length > 0) {
      lines.push('headers = {');
      headers.forEach((item: GeneratedHeader) => lines.push(
        `    '${RequestCodeGenerator.quote(item.key, "'")}': '${RequestCodeGenerator.quote(item.value, "'")}',`));
      lines.push('}', '');
    }
    const requestArguments: string[] = [
      `'${request.method}'`,
      `'${RequestCodeGenerator.quote(RequestCodeGenerator.url(request), "'")}'`
    ];
    if (headers.length > 0) requestArguments.push('headers=headers');
    if (request.auth.type === 'basic') {
      requestArguments.push(`auth=('${RequestCodeGenerator.quote(request.auth.username, "'")}', ` +
        `'${RequestCodeGenerator.quote(request.auth.password, "'")}')`);
    }
    const body = RequestCodeGenerator.textBody(request);
    if (body.length > 0) requestArguments.push(`data='${RequestCodeGenerator.quote(body, "'")}'`);
    if (request.bodyType === 'multipart') {
      lines.push('files = {');
      request.multipartItems.filter((item: KeyValueItem) => item.enabled && item.type === 'file')
        .forEach((item: KeyValueItem) => lines.push(
          `    '${RequestCodeGenerator.quote(item.key, "'")}': open('${RequestCodeGenerator.quote(item.value, "'")}', 'rb'),`));
      lines.push('}', '');
      requestArguments.push('files=files');
    }
    lines.push(`response = requests.request(${requestArguments.join(', ')})`);
    lines.push('print(response.status_code, response.text)');
    return lines.join('\n');
  }

  private static go(request: RequestDraft): string {
    const body = RequestCodeGenerator.textBody(request);
    const imports: string[] = ['"fmt"', '"net/http"'];
    if (body.length > 0) imports.push('"strings"');
    const lines: string[] = ['package main', '', 'import ('];
    imports.forEach((item: string) => lines.push(`  ${item}`));
    lines.push(')', '', 'func main() {');
    const bodyReader = body.length > 0 ?
      `strings.NewReader("${RequestCodeGenerator.quote(body, '"')}")` : 'nil';
    lines.push(`  req, err := http.NewRequest("${request.method}", ` +
      `"${RequestCodeGenerator.quote(RequestCodeGenerator.url(request), '"')}", ${bodyReader})`);
    lines.push('  if err != nil { panic(err) }');
    RequestCodeGenerator.headers(request).forEach((item: GeneratedHeader) => lines.push(
      `  req.Header.Set("${RequestCodeGenerator.quote(item.key, '"')}", ` +
      `"${RequestCodeGenerator.quote(item.value, '"')}")`));
    if (request.auth.type === 'basic') {
      lines.push(`  req.SetBasicAuth("${RequestCodeGenerator.quote(request.auth.username, '"')}", ` +
        `"${RequestCodeGenerator.quote(request.auth.password, '"')}")`);
    }
    if (request.bodyType === 'multipart') {
      lines.push('  // Add multipart fields/files with mime/multipart before sending.');
    }
    lines.push('  response, err := http.DefaultClient.Do(req)');
    lines.push('  if err != nil { panic(err) }');
    lines.push('  defer response.Body.Close()');
    lines.push('  fmt.Println(response.Status)');
    lines.push('}');
    return lines.join('\n');
  }

  static generate(request: RequestDraft, language: RequestCodeLanguage): string {
    if (language === 'curl') return CurlCodec.encode(request);
    if (language === 'javascript') return RequestCodeGenerator.javascript(request);
    if (language === 'python') return RequestCodeGenerator.python(request);
    return RequestCodeGenerator.go(request);
  }
}
