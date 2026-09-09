import { CollectionNode, RequestTabModel } from '../models/ShellModels';

export const INITIAL_TABS: RequestTabModel[] = [
  {
    id: 'get-users',
    name: 'Get Users',
    method: 'GET',
    dirty: false,
    pinned: false,
    loading: false
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

