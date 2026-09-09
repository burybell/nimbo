import { AuthConfig, BodyType, HttpMethod, KeyValueItem, RequestDraft } from '../models/ShellModels';

export interface CurlImportResult {
  method: HttpMethod;
  url: string;
  params: KeyValueItem[];
  headers: KeyValueItem[];
  auth: AuthConfig;
  bodyType: BodyType;
  bodyText: string;
  formItems: KeyValueItem[];
  multipartItems: KeyValueItem[];
}

interface CurlUrlResult {
  url: string;
  params: KeyValueItem[];
}

export class CurlCodec {
  private static tokenise(command: string): string[] {
    const normalized = command.replaceAll('\\\r\n', ' ').replaceAll('\\\n', ' ');
    const tokens: string[] = [];
    let current = '';
    let quote = '';
    let escaping = false;
    for (let index = 0; index < normalized.length; index += 1) {
      const character = normalized[index];
      if (escaping) {
        current += character;
        escaping = false;
      } else if (character === '\\' && quote !== "'") {
        escaping = true;
      } else if (quote.length > 0) {
        if (character === quote) quote = '';
        else current += character;
      } else if (character === "'" || character === '"') {
        quote = character;
      } else if (character === ' ' || character === '\t' || character === '\n' || character === '\r') {
        if (current.length > 0) {
          tokens.push(current);
          current = '';
        }
      } else {
        current += character;
      }
    }
    if (escaping || quote.length > 0) throw new Error('The cURL command contains an unfinished quote or escape.');
    if (current.length > 0) tokens.push(current);
    return tokens;
  }

  private static method(value: string): HttpMethod {
    const upper = value.toUpperCase();
    if (upper === 'GET' || upper === 'POST' || upper === 'PUT' || upper === 'PATCH' ||
      upper === 'DELETE' || upper === 'HEAD' || upper === 'OPTIONS') return upper as HttpMethod;
    throw new Error(`Unsupported HTTP method: ${value}`);
  }

  private static item(prefix: string, index: number, key: string, value: string,
    type: 'text' | 'file' = 'text'): KeyValueItem {
    return { id: `${prefix}-${index}`, enabled: true, key, value, description: '', type, secret: false };
  }

  private static splitUrl(source: string): CurlUrlResult {
    const queryIndex = source.indexOf('?');
    if (queryIndex < 0) return { url: source, params: [] };
    const fragmentIndex = source.indexOf('#', queryIndex);
    const query = source.substring(queryIndex + 1, fragmentIndex < 0 ? source.length : fragmentIndex);
    const suffix = fragmentIndex < 0 ? '' : source.substring(fragmentIndex);
    const params: KeyValueItem[] = [];
    query.split('&').forEach((part: string, index: number) => {
      if (part.length === 0) return;
      const separator = part.indexOf('=');
      const key = separator < 0 ? part : part.substring(0, separator);
      const value = separator < 0 ? '' : part.substring(separator + 1);
      params.push(CurlCodec.item('curl-param', index, decodeURIComponent(key), decodeURIComponent(value)));
    });
    return { url: `${source.substring(0, queryIndex)}${suffix}`, params };
  }

  static parse(command: string): CurlImportResult {
    const tokens = CurlCodec.tokenise(command.trim());
    if (tokens.length === 0 || tokens[0].toLowerCase() !== 'curl') {
      throw new Error('Expected a command beginning with curl.');
    }
    let method: HttpMethod = 'GET';
    let explicitMethod = false;
    let sourceUrl = '';
    let bodyText = '';
    let bodyType: BodyType = 'none';
    const headers: KeyValueItem[] = [];
    const formItems: KeyValueItem[] = [];
    const multipartItems: KeyValueItem[] = [];
    let auth: AuthConfig = { type: 'none', bearerToken: '', username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };

    const nextValue = (index: number, option: string): string => {
      if (index + 1 >= tokens.length) throw new Error(`${option} requires a value.`);
      return tokens[index + 1];
    };
    for (let index = 1; index < tokens.length; index += 1) {
      const token = tokens[index];
      if (token === '-X' || token === '--request') {
        method = CurlCodec.method(nextValue(index, token)); explicitMethod = true; index += 1;
      } else if (token.startsWith('-X') && token.length > 2) {
        method = CurlCodec.method(token.substring(2)); explicitMethod = true;
      } else if (token === '--url') {
        sourceUrl = nextValue(index, token); index += 1;
      } else if (token === '-H' || token === '--header') {
        const header = nextValue(index, token); index += 1;
        const separator = header.indexOf(':');
        if (separator <= 0) throw new Error(`Invalid header: ${header}`);
        const key = header.substring(0, separator).trim();
        const value = header.substring(separator + 1).trim();
        if (key.toLowerCase() === 'authorization' && value.toLowerCase().startsWith('bearer ')) {
          auth = { type: 'bearer', bearerToken: value.substring(7), username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
        } else {
          headers.push(CurlCodec.item('curl-header', headers.length, key, value));
        }
      } else if (token === '-A' || token === '--user-agent') {
        headers.push(CurlCodec.item('curl-header', headers.length, 'User-Agent', nextValue(index, token))); index += 1;
      } else if (token === '-u' || token === '--user') {
        const credentials = nextValue(index, token); index += 1;
        const separator = credentials.indexOf(':');
        auth = { type: 'basic', bearerToken: '', username: separator < 0 ? credentials : credentials.substring(0, separator),
          password: separator < 0 ? '' : credentials.substring(separator + 1), apiKey: '', apiValue: '', apiLocation: 'header' };
      } else if (token === '-d' || token === '--data' || token === '--data-raw' || token === '--data-binary') {
        bodyText = nextValue(index, token); bodyType = 'text'; index += 1;
        if (!explicitMethod) method = 'POST';
      } else if (token === '--data-urlencode') {
        const field = nextValue(index, token); index += 1;
        const separator = field.indexOf('=');
        formItems.push(CurlCodec.item('curl-form', formItems.length,
          separator < 0 ? field : field.substring(0, separator), separator < 0 ? '' : field.substring(separator + 1)));
        bodyType = 'form';
        if (!explicitMethod) method = 'POST';
      } else if (token === '-F' || token === '--form') {
        const field = nextValue(index, token); index += 1;
        const separator = field.indexOf('=');
        if (separator <= 0) throw new Error(`Invalid form field: ${field}`);
        const value = field.substring(separator + 1);
        multipartItems.push(CurlCodec.item('curl-multipart', multipartItems.length, field.substring(0, separator),
          value.startsWith('@') ? value.substring(1) : value, value.startsWith('@') ? 'file' : 'text'));
        bodyType = 'multipart';
        if (!explicitMethod) method = 'POST';
      } else if (token === '-G' || token === '--get') {
        method = 'GET'; explicitMethod = true;
      } else if (token === '-I' || token === '--head') {
        method = 'HEAD'; explicitMethod = true;
      } else if (!token.startsWith('-') && (token.startsWith('http://') || token.startsWith('https://'))) {
        sourceUrl = token;
      } else if ((token === '-L' || token === '--location' || token === '-s' || token === '--silent' ||
        token === '--compressed' || token === '-k' || token === '--insecure')) {
        // These transport flags are represented by request settings or require no draft field.
      } else if (token.startsWith('-')) {
        throw new Error(`Unsupported cURL option: ${token}`);
      }
    }
    if (!sourceUrl.startsWith('http://') && !sourceUrl.startsWith('https://')) {
      throw new Error('No valid http:// or https:// URL was found.');
    }
    if (bodyType === 'text') {
      const contentType = headers.find((header: KeyValueItem) => header.key.toLowerCase() === 'content-type');
      if (contentType && contentType.value.toLowerCase().includes('json')) bodyType = 'json';
    }
    const split = CurlCodec.splitUrl(sourceUrl);
    return { method, url: split.url, params: split.params, headers, auth, bodyType, bodyText, formItems, multipartItems };
  }

  private static quote(value: string): string {
    return `'${value.replaceAll("'", "'\\''")}'`;
  }

  static encode(request: RequestDraft): string {
    const parts: string[] = ['curl', '-X', request.method, CurlCodec.quote(CurlCodec.urlWithParams(request))];
    request.headers.filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
      .forEach((item: KeyValueItem) => parts.push('-H', CurlCodec.quote(`${item.key}: ${item.value}`)));
    if (request.auth.type === 'bearer') parts.push('-H', CurlCodec.quote(`Authorization: Bearer ${request.auth.bearerToken}`));
    if (request.auth.type === 'basic') parts.push('-u', CurlCodec.quote(`${request.auth.username}:${request.auth.password}`));
    if (request.bodyType === 'json' || request.bodyType === 'text') parts.push('--data-raw', CurlCodec.quote(request.bodyText));
    if (request.bodyType === 'form') request.formItems.filter((item: KeyValueItem) => item.enabled)
      .forEach((item: KeyValueItem) => parts.push('--data-urlencode', CurlCodec.quote(`${item.key}=${item.value}`)));
    if (request.bodyType === 'multipart') request.multipartItems.filter((item: KeyValueItem) => item.enabled)
      .forEach((item: KeyValueItem) => parts.push('-F', CurlCodec.quote(`${item.key}=${item.type === 'file' ? '@' : ''}${item.value}`)));
    return parts.join(' ');
  }

  private static urlWithParams(request: RequestDraft): string {
    const params: string[] = [];
    request.params.filter((item: KeyValueItem) => item.enabled && item.key.length > 0)
      .forEach((item: KeyValueItem) => params.push(`${encodeURIComponent(item.key)}=${encodeURIComponent(item.value)}`));
    if (params.length === 0) return request.url;
    return `${request.url}${request.url.includes('?') ? '&' : '?'}${params.join('&')}`;
  }
}
