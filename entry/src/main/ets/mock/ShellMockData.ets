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
    contentType: '',
    size: '',
    duration: '',
    protocol: '',
    error: { type: 'unknown', title: '', message: '', code: '', details: '' },
    previewAvailable: false
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
    contentType: 'application/json',
    size: '12.4 KB',
    duration: '183 ms',
    protocol: 'HTTP/2',
    error: { type: 'unknown', title: '', message: '', code: '', details: '' },
    previewAvailable: true
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
    binaryFileName: ''
  };
}

export function createDemoRequest(): RequestDraft {
  const request = createEmptyRequest();
  request.url = 'https://jsonplaceholder.typicode.com/users';
  request.params = [
    { id: 'param-page', enabled: true, key: '_page', value: '1', description: 'Page number', type: 'text', secret: false },
    { id: 'param-limit', enabled: true, key: '_limit', value: '10', description: 'Items per page', type: 'text', secret: false }
  ];
  request.headers = [
    { id: 'header-accept', enabled: true, key: 'Accept', value: 'application/json', description: '', type: 'text', secret: false }
  ];
  return request;
}

export const INITIAL_TABS: RequestTabModel[] = [
  {
    id: 'get-users',
    name: 'Get Users',
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
    name: 'Demo API',
    expanded: true,
    children: [
      {
        id: 'users-folder',
        type: 'folder',
        name: 'Users',
        expanded: true,
        children: [
          {
            id: 'get-users-request',
            type: 'request',
            name: 'Get Users',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'create-user-request',
            type: 'request',
            name: 'Create User',
            method: 'POST',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'response-states-folder',
        type: 'folder',
        name: 'Response States',
        expanded: true,
        children: [
          {
            id: 'connection-error-request',
            type: 'request',
            name: 'Connection Error',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'large-response-request',
            type: 'request',
            name: 'Large Response',
            method: 'GET',
            expanded: false,
            children: []
          },
          {
            id: 'binary-response-request',
            type: 'request',
            name: 'Binary Response',
            method: 'GET',
            expanded: false,
            children: []
          }
        ]
      },
      {
        id: 'auth-folder',
        type: 'folder',
        name: 'Auth',
        expanded: false,
        children: [
          {
            id: 'login-request',
            type: 'request',
            name: 'Login',
            method: 'POST',
            expanded: false,
            children: []
          }
        ]
      }
    ]
  }
];
