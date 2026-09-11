import {
  AuthConfig,
  BodyType,
  CollectionNode,
  HttpMethod,
  KeyValueItem,
  RequestDraft
} from '../models/ShellModels';
import { PersistedRequestModel } from '../models/PersistenceModels';
import { createEmptyRequest } from '../mock/ShellMockData';

interface OpenApiInfo { title?: string; }
interface OpenApiServerVariable { default?: string; }
interface OpenApiServer { url?: string; variables?: Record<string, OpenApiServerVariable>; }
interface OpenApiSchema {
  type?: string;
  format?: string;
  example?: Object;
  default?: Object;
  enum?: Object[];
  properties?: Record<string, OpenApiSchema>;
  items?: OpenApiSchema;
  allOf?: OpenApiSchema[];
  oneOf?: OpenApiSchema[];
  anyOf?: OpenApiSchema[];
  $ref?: string;
}
interface OpenApiExample { value?: Object; }
interface OpenApiMediaType { schema?: OpenApiSchema; example?: Object; examples?: Record<string, OpenApiExample>; }
interface OpenApiRequestBody { content?: Record<string, OpenApiMediaType>; required?: boolean; $ref?: string; }
interface OpenApiParameter {
  $ref?: string;
  name?: string;
  in?: string;
  description?: string;
  required?: boolean;
  example?: Object;
  schema?: OpenApiSchema;
  type?: string;
  format?: string;
  items?: OpenApiSchema;
}
interface OpenApiSecurityScheme { type?: string; scheme?: string; name?: string; in?: string; }
interface OpenApiComponents {
  schemas?: Record<string, OpenApiSchema>;
  securitySchemes?: Record<string, OpenApiSecurityScheme>;
  parameters?: Record<string, OpenApiParameter>;
  requestBodies?: Record<string, OpenApiRequestBody>;
}
interface OpenApiOperation {
  summary?: string;
  operationId?: string;
  tags?: string[];
  parameters?: OpenApiParameter[];
  requestBody?: OpenApiRequestBody;
  security?: Record<string, string[]>[];
  servers?: OpenApiServer[];
}
interface OpenApiPathItem {
  parameters?: OpenApiParameter[];
  servers?: OpenApiServer[];
  get?: OpenApiOperation;
  post?: OpenApiOperation;
  put?: OpenApiOperation;
  patch?: OpenApiOperation;
  delete?: OpenApiOperation;
  head?: OpenApiOperation;
  options?: OpenApiOperation;
}
interface OpenApiDocument {
  openapi?: string;
  swagger?: string;
  info?: OpenApiInfo;
  servers?: OpenApiServer[];
  host?: string;
  basePath?: string;
  schemes?: string[];
  consumes?: string[];
  paths?: Record<string, OpenApiPathItem>;
  components?: OpenApiComponents;
  definitions?: Record<string, OpenApiSchema>;
  securityDefinitions?: Record<string, OpenApiSecurityScheme>;
  security?: Record<string, string[]>[];
}
interface OpenApiRequestBodyResult {
  bodyType: BodyType;
  bodyText: string;
  formItems: KeyValueItem[];
  multipartItems: KeyValueItem[];
  contentType: string;
}

export interface OpenApiImportResult {
  name: string;
  collections: CollectionNode[];
  requests: PersistedRequestModel[];
  requestCount: number;
  folderCount: number;
  warnings: string[];
  specification: string;
}

export class OpenApiCodec {
  private static idPrefix: string = '';
  private static nextId: number = 1;
  private static document: OpenApiDocument = {};

  private static id(kind: string): string {
    const value = `openapi-${OpenApiCodec.idPrefix}-${kind}-${OpenApiCodec.nextId}`;
    OpenApiCodec.nextId += 1;
    return value;
  }

  private static warning(warnings: string[], value: string): void {
    if (!warnings.includes(value)) warnings.push(value);
  }

  private static method(value: string): HttpMethod {
    return value.toUpperCase() as HttpMethod;
  }

  private static item(kind: string, key: string, value: string, description: string = '',
    enabled: boolean = true, type: 'text' | 'file' = 'text'): KeyValueItem {
    return { id: OpenApiCodec.id(kind), enabled, key, value, description, type, secret: false };
  }

  private static valueText(value: Object | undefined): string {
    if (value === undefined || value === null) return '';
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return `${value}`;
    return JSON.stringify(value);
  }

  private static refSchema(reference: string | undefined): OpenApiSchema | undefined {
    if (!reference) return undefined;
    const marker = reference.lastIndexOf('/');
    const name = marker < 0 ? reference : reference.substring(marker + 1);
    return OpenApiCodec.document.components?.schemas?.[name] ?? OpenApiCodec.document.definitions?.[name];
  }

  private static refName(reference: string): string {
    const marker = reference.lastIndexOf('/');
    return marker < 0 ? reference : reference.substring(marker + 1);
  }

  private static parameter(parameter: OpenApiParameter): OpenApiParameter {
    if (!parameter.$ref) return parameter;
    return OpenApiCodec.document.components?.parameters?.[OpenApiCodec.refName(parameter.$ref)] ?? parameter;
  }

  private static sample(schema: OpenApiSchema | undefined, depth: number = 0): Object {
    if (!schema || depth > 8) {
      const empty: Record<string, Object> = {};
      return empty;
    }
    if (schema.example !== undefined && schema.example !== null) return schema.example;
    if (schema.default !== undefined && schema.default !== null) return schema.default;
    if (schema.enum && schema.enum.length > 0) return schema.enum[0];
    const referenced = OpenApiCodec.refSchema(schema.$ref);
    if (referenced) return OpenApiCodec.sample(referenced, depth + 1);
    if (schema.allOf && schema.allOf.length > 0) {
      const combined: Record<string, Object> = {};
      schema.allOf.forEach((part: OpenApiSchema) => {
        const value = OpenApiCodec.sample(part, depth + 1);
        if (typeof value === 'object' && !Array.isArray(value)) {
          Object.keys(value).forEach((key: string) => { combined[key] = (value as Record<string, Object>)[key]; });
        }
      });
      return combined;
    }
    const alternative = schema.oneOf?.[0] ?? schema.anyOf?.[0];
    if (alternative) return OpenApiCodec.sample(alternative, depth + 1);
    if (schema.type === 'array' || schema.items) return [OpenApiCodec.sample(schema.items, depth + 1)];
    if (schema.type === 'object' || schema.properties) {
      const value: Record<string, Object> = {};
      const properties = schema.properties;
      if (properties) Object.keys(properties).forEach((key: string) => {
        value[key] = OpenApiCodec.sample(properties[key], depth + 1);
      });
      return value;
    }
    if (schema.type === 'integer' || schema.type === 'number') return 0;
    if (schema.type === 'boolean') return false;
    if (schema.format === 'date') return '2026-01-01';
    if (schema.format === 'date-time') return '2026-01-01T00:00:00Z';
    if (schema.format === 'email') return 'user@example.com';
    if (schema.format === 'uuid') return '00000000-0000-4000-8000-000000000000';
    return '';
  }

  private static parameterValue(parameter: OpenApiParameter): string {
    if (parameter.example !== undefined) return OpenApiCodec.valueText(parameter.example);
    const schema: OpenApiSchema = parameter.schema ?? {
      type: parameter.type, format: parameter.format, items: parameter.items
    };
    return OpenApiCodec.valueText(OpenApiCodec.sample(schema));
  }

  private static serverUrl(server: OpenApiServer | undefined): string {
    let url = server?.url ?? '';
    const variables = server?.variables;
    if (variables) Object.keys(variables).forEach((name: string) => {
      url = url.replaceAll(`{${name}}`, variables[name].default ?? `{${name}}`);
    });
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  private static baseUrl(document: OpenApiDocument): string {
    if (document.openapi) return OpenApiCodec.serverUrl(document.servers?.[0]);
    const scheme = document.schemes?.[0] ?? 'https';
    const host = document.host ?? '';
    const path = document.basePath ?? '';
    return host.length > 0 ? `${scheme}://${host}${path.endsWith('/') ? path.substring(0, path.length - 1) : path}` : '';
  }

  private static operation(path: OpenApiPathItem, method: HttpMethod): OpenApiOperation | undefined {
    if (method === 'GET') return path.get;
    if (method === 'POST') return path.post;
    if (method === 'PUT') return path.put;
    if (method === 'PATCH') return path.patch;
    if (method === 'DELETE') return path.delete;
    if (method === 'HEAD') return path.head;
    return path.options;
  }

  private static mediaExample(media: OpenApiMediaType): Object {
    if (media.example !== undefined && media.example !== null) return media.example;
    const examples = media.examples;
    const firstExample = examples ? Object.keys(examples)[0] : '';
    if (firstExample && examples) {
      const value = examples[firstExample].value;
      if (value !== undefined && value !== null) return value;
    }
    return OpenApiCodec.sample(media.schema);
  }

  private static objectFields(schema: OpenApiSchema | undefined, kind: string,
    multipart: boolean): KeyValueItem[] {
    const resolved = OpenApiCodec.refSchema(schema?.$ref) ?? schema;
    const properties = resolved?.properties ?? {};
    return Object.keys(properties).map((key: string) => {
      const field = properties[key];
      const file = multipart && (field.format === 'binary' || field.type === 'file');
      const value = file ? '' : OpenApiCodec.valueText(OpenApiCodec.sample(field));
      return OpenApiCodec.item(kind, key, value, '', value.length > 0, file ? 'file' : 'text');
    });
  }

  private static openApiBody(operation: OpenApiOperation): OpenApiRequestBodyResult {
    let requestBody = operation.requestBody;
    if (requestBody?.$ref) {
      requestBody = OpenApiCodec.document.components?.requestBodies?.[OpenApiCodec.refName(requestBody.$ref)] ?? requestBody;
    }
    const content = requestBody?.content;
    if (!content) return { bodyType: 'none', bodyText: '', formItems: [], multipartItems: [], contentType: '' };
    const contentTypes = Object.keys(content);
    const contentType = contentTypes.includes('application/json') ? 'application/json' :
      (contentTypes.includes('application/x-www-form-urlencoded') ? 'application/x-www-form-urlencoded' :
        (contentTypes.includes('multipart/form-data') ? 'multipart/form-data' : (contentTypes[0] ?? '')));
    const media = content[contentType];
    if (!media) return { bodyType: 'none', bodyText: '', formItems: [], multipartItems: [], contentType: '' };
    if (contentType.includes('json')) return { bodyType: 'json', bodyText: JSON.stringify(OpenApiCodec.mediaExample(media), null, 2),
      formItems: [], multipartItems: [], contentType };
    if (contentType === 'application/x-www-form-urlencoded') return { bodyType: 'form', bodyText: '',
      formItems: OpenApiCodec.objectFields(media.schema, 'form', false), multipartItems: [], contentType };
    if (contentType === 'multipart/form-data') return { bodyType: 'multipart', bodyText: '', formItems: [],
      multipartItems: OpenApiCodec.objectFields(media.schema, 'multipart', true), contentType };
    return { bodyType: 'text', bodyText: OpenApiCodec.valueText(OpenApiCodec.mediaExample(media)),
      formItems: [], multipartItems: [], contentType };
  }

  private static swaggerBody(operation: OpenApiOperation, document: OpenApiDocument): OpenApiRequestBodyResult {
    const parameters = operation.parameters ?? [];
    const body = parameters.find((parameter: OpenApiParameter) => parameter.in === 'body');
    const form = parameters.filter((parameter: OpenApiParameter) => parameter.in === 'formData');
    const contentType = document.consumes?.[0] ?? (form.length > 0 ? 'application/x-www-form-urlencoded' : 'application/json');
    if (body) return { bodyType: contentType.includes('json') ? 'json' : 'text',
      bodyText: JSON.stringify(OpenApiCodec.sample(body.schema), null, 2), formItems: [], multipartItems: [], contentType };
    if (form.length > 0) {
      const multipart = contentType === 'multipart/form-data' || form.some((parameter: OpenApiParameter) => parameter.type === 'file');
      const items = form.map((parameter: OpenApiParameter) => OpenApiCodec.item(multipart ? 'multipart' : 'form',
        parameter.name ?? '', OpenApiCodec.parameterValue(parameter), parameter.description ?? '', parameter.required === true,
        parameter.type === 'file' ? 'file' : 'text'));
      return { bodyType: multipart ? 'multipart' : 'form', bodyText: '',
        formItems: multipart ? [] : items, multipartItems: multipart ? items : [], contentType };
    }
    return { bodyType: 'none', bodyText: '', formItems: [], multipartItems: [], contentType: '' };
  }

  private static auth(operation: OpenApiOperation, document: OpenApiDocument, warnings: string[],
    name: string): AuthConfig {
    const empty: AuthConfig = { type: 'none', bearerToken: '', username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
    const requirement = (operation.security ?? document.security)?.[0];
    if (!requirement) return empty;
    const securityName = Object.keys(requirement)[0];
    if (!securityName) return empty;
    const scheme = document.components?.securitySchemes?.[securityName] ?? document.securityDefinitions?.[securityName];
    if (!scheme) return empty;
    if (scheme.type === 'http' && scheme.scheme?.toLowerCase() === 'bearer') {
      return { type: 'bearer', bearerToken: '', username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
    }
    if ((scheme.type === 'http' && scheme.scheme?.toLowerCase() === 'basic') || scheme.type === 'basic') {
      return { type: 'basic', bearerToken: '', username: '', password: '', apiKey: '', apiValue: '', apiLocation: 'header' };
    }
    if (scheme.type === 'apiKey') return { type: 'apiKey', bearerToken: '', username: '', password: '',
      apiKey: scheme.name ?? securityName, apiValue: '', apiLocation: scheme.in === 'query' ? 'query' : 'header' };
    OpenApiCodec.warning(warnings, `${name}: unsupported ${scheme.type ?? 'unknown'} authorization`);
    return empty;
  }

  private static parseRequest(document: OpenApiDocument, pathName: string, pathItem: OpenApiPathItem,
    operation: OpenApiOperation, method: HttpMethod, name: string, warnings: string[]): RequestDraft {
    const request = createEmptyRequest(method);
    const operationBase = OpenApiCodec.serverUrl(operation.servers?.[0] ?? pathItem.servers?.[0]);
    let requestPath = pathName;
    const parameters = [...(pathItem.parameters ?? []), ...(operation.parameters ?? [])];
    parameters.forEach((source: OpenApiParameter) => {
      const parameter = OpenApiCodec.parameter(source);
      const key = parameter.name ?? '';
      if (key.length === 0) return;
      const value = OpenApiCodec.parameterValue(parameter);
      if (parameter.in === 'path') {
        if (value.length > 0 && value !== '{}') requestPath = requestPath.replaceAll(`{${key}}`, encodeURIComponent(value));
        else OpenApiCodec.warning(warnings, `${name}: path parameter {${key}} needs a value`);
      } else if (parameter.in === 'query') {
        request.params.push(OpenApiCodec.item('query', key, value, parameter.description ?? '',
          parameter.required === true || value.length > 0));
      } else if (parameter.in === 'header') {
        request.headers.push(OpenApiCodec.item('header', key, value, parameter.description ?? '',
          parameter.required === true || value.length > 0));
      } else if (parameter.in === 'cookie') {
        OpenApiCodec.warning(warnings, `${name}: cookie parameter ${key} was not imported`);
      }
    });
    const baseUrl = operationBase.length > 0 ? operationBase : OpenApiCodec.baseUrl(document);
    if (baseUrl.length === 0) OpenApiCodec.warning(warnings, 'No server URL was provided; imported request URLs are relative.');
    request.url = `${baseUrl}${requestPath}`;
    request.auth = OpenApiCodec.auth(operation, document, warnings, name);
    const body = document.openapi ? OpenApiCodec.openApiBody(operation) : OpenApiCodec.swaggerBody(operation, document);
    request.bodyType = body.bodyType;
    request.bodyText = body.bodyText;
    request.formItems = body.formItems;
    request.multipartItems = body.multipartItems;
    if (body.contentType.length > 0 && !request.headers.some((item: KeyValueItem) => item.key.toLowerCase() === 'content-type')) {
      request.headers.push(OpenApiCodec.item('header', 'Content-Type', body.contentType));
    }
    return request;
  }

  static parse(text: string): OpenApiImportResult {
    let document: OpenApiDocument;
    try {
      document = JSON.parse(text) as OpenApiDocument;
    } catch (_error) {
      throw new Error('The selected file is not valid JSON. YAML import is not supported yet.');
    }
    const openApi = document.openapi ?? '';
    const swagger = document.swagger ?? '';
    if (!openApi.startsWith('3.0.') && !openApi.startsWith('3.1.') && swagger !== '2.0') {
      throw new Error('Only OpenAPI 3.0, OpenAPI 3.1, and Swagger 2.0 JSON documents are supported.');
    }
    if (!document.paths || Object.keys(document.paths).length === 0) throw new Error('The API document does not contain any paths.');
    OpenApiCodec.document = document;
    OpenApiCodec.idPrefix = Date.now().toString();
    OpenApiCodec.nextId = 1;
    const warnings: string[] = [];
    const requests: PersistedRequestModel[] = [];
    const rootChildren: CollectionNode[] = [];
    const methods: HttpMethod[] = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
    Object.keys(document.paths).forEach((pathName: string) => {
      const pathItem = document.paths?.[pathName];
      if (!pathItem) return;
      methods.forEach((method: HttpMethod) => {
        const operation = OpenApiCodec.operation(pathItem, method);
        if (!operation) return;
        const name = operation.summary ?? operation.operationId ?? `${method} ${pathName}`;
        const request = OpenApiCodec.parseRequest(document, pathName, pathItem, operation, method, name, warnings);
        const id = OpenApiCodec.id('request');
        requests.push({ id, name, method, request });
        const node: CollectionNode = { id, type: 'request', name, method, expanded: false, children: [] };
        const tag = operation.tags?.[0] ?? '';
        if (tag.length === 0) {
          rootChildren.push(node);
        } else {
          let folder = rootChildren.find((candidate: CollectionNode) => candidate.type === 'folder' && candidate.name === tag);
          if (!folder) {
            folder = { id: OpenApiCodec.id('folder'), type: 'folder', name: tag, expanded: true, children: [] };
            rootChildren.push(folder);
          }
          folder.children.push(node);
        }
      });
    });
    if (requests.length === 0) throw new Error('The API document does not contain supported HTTP operations.');
    const name = document.info?.title ?? (document.openapi ? 'Imported OpenAPI' : 'Imported Swagger');
    const collection: CollectionNode = { id: OpenApiCodec.id('collection'), type: 'collection', name,
      expanded: true, children: rootChildren };
    return { name, collections: [collection], requests, requestCount: requests.length,
      folderCount: rootChildren.filter((node: CollectionNode) => node.type === 'folder').length,
      warnings, specification: document.openapi ? `OpenAPI ${document.openapi}` : `Swagger ${document.swagger}` };
  }
}
