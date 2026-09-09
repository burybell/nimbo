import { CollectionNode, HttpMethod, RequestDraft, RequestTabModel } from '../models/ShellModels';

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
    request: createDemoRequest()
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
