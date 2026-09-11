import { CollectionNode, HttpMethod, RequestDraft, RequestTabModel, ResponseModel } from '../models/ShellModels';

const SUCCESS_BODY: string = `[
  {
    "id": 1,
    "name": "Leanne Graham",
    "username": "Bret",
    "email": "Sincere@april.biz",
    "phone": "1-770-736-8031 x56442",
    "website": "hildegard.org"
  },
  {
    "id": 2,
    "name": "Ervin Howell",
    "username": "Antonette",
    "email": "Shanna@melissa.tv"
  }
]`;

export function createEmptyResponse(): ResponseModel {
  return {
    status: 'empty',
    statusCode: 0,
    statusText: '',
    headers: [],
    cookies: [],
    body: '',
    binaryBody: new ArrayBuffer(0),
    mediaKind: 'none',
    mediaUri: '',
    contentType: '',
    size: '',
    duration: '',
    protocol: '',
    error: { type: 'unknown', title: '', message: '', code: '', details: '' },
    previewAvailable: false,
    scriptResults: [],
    extractionResults: [],
    testResults: []
  };
}

export function createSuccessResponse(): ResponseModel {
  return {
    status: 'success',
    statusCode: 200,
    statusText: 'OK',
    headers: [
      { id: 'response-content-type', enabled: true, key: 'content-type', value: 'application/json; charset=utf-8', description: '', type: 'text', secret: false },
      { id: 'response-cache-control', enabled: true, key: 'cache-control', value: 'max-age=43200', description: '', type: 'text', secret: false },
      { id: 'response-server', enabled: true, key: 'server', value: 'cloudflare', description: '', type: 'text', secret: false }
    ],
    cookies: [],
    body: SUCCESS_BODY,
    binaryBody: new ArrayBuffer(0),
    mediaKind: 'none',
    mediaUri: '',
    contentType: 'application/json',
    size: '12.4 KB',
    duration: '183 ms',
    protocol: 'HTTP/2',
    error: { type: 'unknown', title: '', message: '', code: '', details: '' },
    previewAvailable: true,
    scriptResults: [],
    extractionResults: [],
    testResults: []
  };
}

export function createErrorResponse(): ResponseModel {
  const response = createEmptyResponse();
  response.status = 'error';
  response.error = {
    type: 'connectionRefused',
    title: 'Connection failed',
    message: 'Connection refused — localhost:8080',
    code: 'ECONNREFUSED',
    details: 'TCP connection to 127.0.0.1:8080 failed.'
  };
  return response;
}

export function createLargeResponse(): ResponseModel {
  const response = createEmptyResponse();
  response.status = 'large';
  response.contentType = 'application/json';
  response.size = '42.8 MB';
  response.previewAvailable = true;
  return response;
}

export function createBinaryResponse(): ResponseModel {
  const response = createEmptyResponse();
  response.status = 'binary';
  response.contentType = 'application/zip';
  response.size = '6.2 MB';
  return response;
}

export function createCancelledResponse(): ResponseModel {
  const response = createEmptyResponse();
  response.status = 'cancelled';
  response.error = {
    type: 'cancelled',
    title: 'Request cancelled',
    message: 'The request was cancelled before it completed.',
    code: 'CANCELLED',
    details: 'Cancelled by the user.'
  };
  return response;
}

export function createEmptyRequest(method: HttpMethod = 'GET'): RequestDraft {
  return {
    method,
    url: '',
    lifecycle: 'idle',
    activeConfigTab: 'params',
    params: [],
    headers: [],
    auth: {
      type: 'none',
      bearerToken: '',
      username: '',
      password: '',
      apiKey: '',
      apiValue: '',
      apiLocation: 'header'
    },
    bodyType: 'none',
    bodyText: '',
    formItems: [],
    multipartItems: [],
    binaryFileName: '',
    preRequestScript: { enabled: false, source: '' },
    extractionRules: [],
    testRules: [],
    settings: {
      timeoutMs: 30000,
      followRedirects: true,
      sslVerification: true,
      useCookieJar: true
    }
  };
}

export function createDemoRequest(): RequestDraft {
  const request = createEmptyRequest();
  request.url = 'https://jsonplaceholder.typicode.com/users';
  request.params = [
    { id: 'param-page', enabled: true, key: '_page', value: '1', description: '页码', type: 'text', secret: false },
    { id: 'param-limit', enabled: true, key: '_limit', value: '10', description: '每页数量', type: 'text', secret: false }
  ];
  request.headers = [
    { id: 'header-accept', enabled: true, key: 'Accept', value: 'application/json', description: '', type: 'text', secret: false }
  ];
  return request;
}

export const INITIAL_TABS: RequestTabModel[] = [
  {
    id: 'get-users',
    name: '获取用户',
    method: 'GET',
    dirty: false,
    pinned: false,
    loading: false,
    request: createDemoRequest(),
    response: createSuccessResponse()
  }
];

export const DEMO_COLLECTIONS: CollectionNode[] = [
  {
    id: 'demo-api',
    type: 'collection',
    name: 'Nimbo 示例接口',
    expanded: true,
    children: [
      {
        id: 'users-folder',
        type: 'folder',
        name: '用户服务',
        expanded: true,
        children: [
          {
            id: 'get-users-request',
            type: 'request',
            name: '获取用户',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'create-user-request',
            type: 'request',
            name: '创建用户',
            method: 'POST',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'content-folder',
        type: 'folder',
        name: '内容服务',
        expanded: true,
        children: [
          {
            id: 'get-posts-request',
            type: 'request',
            name: '获取文章列表',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'create-post-request',
            type: 'request',
            name: '创建文章',
            method: 'POST',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'media-folder',
        type: 'folder',
        name: '媒体资源',
        expanded: true,
        children: [
          {
            id: 'preview-image-request',
            type: 'request',
            name: '预览示例图片',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'download-file-request',
            type: 'request',
            name: '下载二进制文件',
            method: 'GET',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'response-states-folder',
        type: 'folder',
        name: '响应示例',
        expanded: true,
        children: [
          {
            id: 'connection-error-request',
            type: 'request',
            name: '连接错误',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'large-response-request',
            type: 'request',
            name: '大响应',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'binary-response-request',
            type: 'request',
            name: '二进制响应',
            method: 'GET',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'auth-folder',
        type: 'folder',
        name: '身份认证',
        expanded: false,
        children: [
          {
            id: 'login-request',
            type: 'request',
            name: '登录',
            method: 'POST',
            expanded: false,
            children: []
          }
        ]
      }
    ]
  }
];
