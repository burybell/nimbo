export type NavigationDestination = 'workspace' | 'collections' | 'environments' | 'history' | 'settings';
export type CollectionNodeType = 'collection' | 'folder' | 'request';
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'HEAD' | 'OPTIONS';
export type RequestConfigTab = 'params' | 'headers' | 'auth' | 'body';
export type RequestLifecycle = 'idle' | 'sending';
export type KeyValueMode = 'params' | 'headers' | 'form' | 'multipart';
export type AuthType = 'none' | 'bearer' | 'basic' | 'apiKey';
export type BodyType = 'none' | 'json' | 'text' | 'form' | 'multipart' | 'binary';

export interface NavigationItemModel {
  id: NavigationDestination;
  label: string;
  icon: string;
}

export interface CollectionNode {
  id: string;
  type: CollectionNodeType;
  name: string;
  method?: string;
  expanded: boolean;
  children: CollectionNode[];
}

export interface RequestTabModel {
  id: string;
  name: string;
  method: HttpMethod;
  dirty: boolean;
  pinned: boolean;
  loading: boolean;
  request: RequestDraft;
}

export interface KeyValueItem {
  id: string;
  enabled: boolean;
  key: string;
  value: string;
  description: string;
  type: 'text' | 'file';
  secret: boolean;
}

export interface AuthConfig {
  type: AuthType;
  bearerToken: string;
  username: string;
  password: string;
  apiKey: string;
  apiValue: string;
  apiLocation: 'header' | 'query';
}

export interface RequestDraft {
  method: HttpMethod;
  url: string;
  lifecycle: RequestLifecycle;
  activeConfigTab: RequestConfigTab;
  params: KeyValueItem[];
  headers: KeyValueItem[];
  auth: AuthConfig;
  bodyType: BodyType;
  bodyText: string;
  formItems: KeyValueItem[];
  multipartItems: KeyValueItem[];
  binaryFileName: string;
}
