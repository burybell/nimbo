import {
  AuthConfig,
  BodyType,
  CollectionNode,
  EnvironmentModel,
  HttpMethod,
  KeyValueItem,
  RequestDraft
} from '../models/ShellModels';
import { PersistedRequestModel } from '../models/PersistenceModels';
import { createEmptyRequest } from '../mock/ShellMockData';

interface PostmanValue { key?: string; value?: string; enabled?: boolean; disabled?: boolean; type?: string; src?: string; }
interface PostmanUrl { raw?: string; protocol?: string; host?: string[]; path?: string[]; query?: PostmanValue[]; }
interface PostmanBody { mode?: string; raw?: string; urlencoded?: PostmanValue[]; formdata?: PostmanValue[]; }
interface PostmanAuth { type?: string; bearer?: PostmanValue[]; basic?: PostmanValue[]; apikey?: PostmanValue[]; }
interface PostmanRequest { method?: string; url?: string | PostmanUrl; header?: PostmanValue[]; body?: PostmanBody; auth?: PostmanAuth; }
interface PostmanItem { name?: string; item?: PostmanItem[]; request?: PostmanRequest; auth?: PostmanAuth; event?: Object[]; }
interface PostmanInfo { name?: string; schema?: string; }
interface PostmanDocument { info?: PostmanInfo; item?: PostmanItem[]; name?: string; values?: PostmanValue[];
  auth?: PostmanAuth; event?: Object[]; }
interface ParsedUrl { url: string; params: KeyValueItem[]; }
interface PostmanItemCount { folders: number; }

export interface PostmanImportResult {
  name: string;
  collections: CollectionNode[];
  requests: PersistedRequestModel[];
  environments: EnvironmentModel[];
  requestCount: number;
  folderCount: number;
  warnings: string[];
}

export class PostmanCodec {
  private static idPrefix: string = '';
  private static nextId: number = 1;

  private static id(kind: string): string {
    const value = `postman-${PostmanCodec.idPrefix}-${kind}-${PostmanCodec.nextId}`;
    PostmanCodec.nextId += 1;
    return value;
  }

  private static value(items: PostmanValue[] | undefined, key: string): string {
    if (!items) return '';
    const found = items.find((item: PostmanValue) => item.key === key);
    return found && found.value ? found.value : '';
  }

  private static method(value: string | undefined): HttpMethod {
    const upper = value ? value.toUpperCase() : 'GET';
    if (upper === 'GET' || upper === 'POST' || upper === 'PUT' || upper === 'PATCH' ||
      upper === 'DELETE' || upper === 'HEAD' || upper === 'OPTIONS') return upper as HttpMethod;
    throw new Error(`Unsupported HTTP method: ${upper}`);
  }

  private static keyValue(prefix: string, index: number, item: PostmanValue,
    file: boolean = false): KeyValueItem {
    return {
      id: PostmanCodec.id(`${prefix}-${index}`),
      enabled: item.disabled !== true && item.enabled !== false,
      key: item.key ?? '', value: file ? (item.src ?? item.value ?? '') : (item.value ?? ''),
      description: '', type: file ? 'file' : 'text', secret: item.type === 'secret'
    };
  }

  private static parseUrl(value: string | PostmanUrl | undefined): ParsedUrl {
    if (!value) return { url: '', params: [] };
    let raw = '';
    let suppliedQuery: PostmanValue[] = [];
    if (typeof value === 'string') {
      raw = value;
    } else {
      raw = value.raw ?? '';
      suppliedQuery = value.query ?? [];
      if (raw.length === 0) {
        const protocol = value.protocol ?? 'https';
        raw = `${protocol}://${(value.host ?? []).join('.')}/${(value.path ?? []).join('/')}`;
      }
    }
    const params: KeyValueItem[] = suppliedQuery.map((item: PostmanValue, index: number) =>
      PostmanCodec.keyValue('query', index, item));
    const queryIndex = raw.indexOf('?');
    if (params.length === 0 && queryIndex >= 0) {
      const query = raw.substring(queryIndex + 1).split('#')[0];
      query.split('&').forEach((part: string, index: number) => {
        if (part.length === 0) return;
        const separator = part.indexOf('=');
        params.push(PostmanCodec.keyValue('query', index, {
          key: decodeURIComponent(separator < 0 ? part : part.substring(0, separator)),
          value: decodeURIComponent(separator < 0 ? '' : part.substring(separator + 1))
        }));
      });
    }
    const fragmentIndex = raw.indexOf('#');
    const fragment = fragmentIndex < 0 ? '' : raw.substring(fragmentIndex);
    const baseEnd = queryIndex < 0 ? (fragmentIndex < 0 ? raw.length : fragmentIndex) : queryIndex;
    return { url: `${raw.substring(0, baseEnd)}${fragment}`, params };
  }

  private static parseAuth(value: PostmanAuth | undefined, warnings: string[], name: string): AuthConfig {
    const empty: AuthConfig = { type: 'none', bearerToken: '', username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
    if (!value || !value.type || value.type === 'noauth') return empty;
    if (value.type === 'bearer') return { type: 'bearer', bearerToken: PostmanCodec.value(value.bearer, 'token'),
      username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
    if (value.type === 'basic') return { type: 'basic', bearerToken: '',
      username: PostmanCodec.value(value.basic, 'username'), password: PostmanCodec.value(value.basic, 'password'),
      apiKey: '', apiValue: '', apiLocation: 'header' };
    if (value.type === 'apikey') {
      const location = PostmanCodec.value(value.apikey, 'in');
      return { type: 'apiKey', bearerToken: '', username: '', password: '',
        apiKey: PostmanCodec.value(value.apikey, 'key'), apiValue: PostmanCodec.value(value.apikey, 'value'),
        apiLocation: location === 'query' ? 'query' : 'header' };
    }
    warnings.push(`${name}: unsupported ${value.type} authorization`);
    return empty;
  }

  private static parseRequest(source: PostmanRequest, inheritedAuth: PostmanAuth | undefined,
    name: string, warnings: string[]): RequestDraft {
    const method = PostmanCodec.method(source.method);
    const request = createEmptyRequest(method);
    const parsedUrl = PostmanCodec.parseUrl(source.url);
    request.url = parsedUrl.url;
    request.params = parsedUrl.params;
    request.headers = (source.header ?? []).map((item: PostmanValue, index: number) =>
      PostmanCodec.keyValue('header', index, item));
    request.auth = PostmanCodec.parseAuth(source.auth ?? inheritedAuth, warnings, name);
    const body = source.body;
    if (body && body.mode === 'raw') {
      request.bodyText = body.raw ?? '';
      const contentType = request.headers.find((item: KeyValueItem) => item.key.toLowerCase() === 'content-type');
      request.bodyType = contentType && contentType.value.toLowerCase().includes('json') ? 'json' : 'text';
    } else if (body && body.mode === 'urlencoded') {
      request.bodyType = 'form';
      request.formItems = (body.urlencoded ?? []).map((item: PostmanValue, index: number) =>
        PostmanCodec.keyValue('form', index, item));
    } else if (body && body.mode === 'formdata') {
      request.bodyType = 'multipart';
      request.multipartItems = (body.formdata ?? []).map((item: PostmanValue, index: number) =>
        PostmanCodec.keyValue('multipart', index, item, item.type === 'file'));
    } else if (body && body.mode && body.mode !== 'none') {
      warnings.push(`${name}: unsupported ${body.mode} body`);
    }
    return request;
  }

  private static parseItems(items: PostmanItem[], inheritedAuth: PostmanAuth | undefined, warnings: string[],
    requests: PersistedRequestModel[], count: PostmanItemCount): CollectionNode[] {
    return items.map((item: PostmanItem) => {
      const name = item.name ?? 'Untitled';
      if (item.event && item.event.length > 0) warnings.push(`${name}: scripts or tests were not imported`);
      if (item.item) {
        count.folders += 1;
        const folder: CollectionNode = { id: PostmanCodec.id('folder'), type: 'folder', name, expanded: true,
          children: PostmanCodec.parseItems(item.item, item.auth ?? inheritedAuth, warnings, requests, count) };
        return folder;
      }
      if (!item.request) throw new Error(`${name}: request data is missing.`);
      const request = PostmanCodec.parseRequest(item.request, item.auth ?? inheritedAuth, name, warnings);
      const id = PostmanCodec.id('request');
      requests.push({ id, name, method: request.method, request });
      const requestNode: CollectionNode = { id, type: 'request', name, method: request.method,
        expanded: false, children: [] };
      return requestNode;
    });
  }

  static parse(text: string): PostmanImportResult {
    let document: PostmanDocument;
    try {
      document = JSON.parse(text) as PostmanDocument;
    } catch (_error) {
      throw new Error('The selected file is not valid JSON.');
    }
    PostmanCodec.idPrefix = Date.now().toString();
    PostmanCodec.nextId = 1;
    if (document.values && !document.item) {
      const name = document.name ?? 'Imported Environment';
      const environment: EnvironmentModel = { id: PostmanCodec.id('environment'), name,
        kind: 'development', variables: document.values.map((item: PostmanValue, index: number) =>
          PostmanCodec.keyValue('environment', index, item)) };
      return { name, collections: [], requests: [], environments: [environment],
        requestCount: 0, folderCount: 0, warnings: [] };
    }
    if (!document.info || !document.item) throw new Error('The file is not a Postman Collection or Environment export.');
    const schema = document.info.schema ?? '';
    if (!schema.includes('/v2.0.') && !schema.includes('/v2.1.')) {
      throw new Error('Only Postman Collection v2 and v2.1 are supported.');
    }
    const warnings: string[] = [];
    if (document.event && document.event.length > 0) warnings.push('Collection scripts or tests were not imported');
    const requests: PersistedRequestModel[] = [];
    const count: PostmanItemCount = { folders: 0 };
    const name = document.info.name ?? 'Imported Collection';
    const children = PostmanCodec.parseItems(document.item, document.auth, warnings, requests, count);
    const collection: CollectionNode = { id: PostmanCodec.id('collection'), type: 'collection', name,
      expanded: true, children };
    return { name, collections: [collection], requests, environments: [], requestCount: requests.length,
      folderCount: count.folders, warnings };
  }
}
