export type NavigationDestination = 'workspace' | 'collections' | 'environments' | 'history' | 'settings';
export type CollectionNodeType = 'collection' | 'folder' | 'request';
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'HEAD' | 'OPTIONS';
export type RequestConfigTab = 'params' | 'headers' | 'auth' | 'body' | 'settings';
export type RequestLifecycle = 'idle' | 'sending';
export type KeyValueMode = 'params' | 'headers' | 'form' | 'multipart' | 'environment';
export type AuthType = 'none' | 'bearer' | 'basic' | 'apiKey';
export type BodyType = 'none' | 'json' | 'text' | 'form' | 'multipart' | 'binary';
export type ResponseStatus = 'empty' | 'sending' | 'success' | 'error' | 'large' | 'binary' | 'cancelled';
export type ResponseTab = 'body' | 'headers' | 'cookies' | 'timeline';
export type ResponseBodyMode = 'pretty' | 'raw';
export type ResponseErrorType = 'dns' | 'connectionRefused' | 'timeout' | 'tls' |
  'connectionReset' | 'invalidUrl' | 'proxy' | 'cancelled' | 'unknown';

export interface NavigationItemModel {
  id: NavigationDestination;
  label: ResourceStr;
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
  response: ResponseModel;
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

export interface RequestSettings {
  timeoutMs: number;
  followRedirects: boolean;
  sslVerification: boolean;
  useCookieJar: boolean;
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
  settings: RequestSettings;
}

export interface ResponseErrorModel {
  type: ResponseErrorType;
  title: string;
  message: string;
  code: string;
  details: string;
}

export interface ResponseModel {
  status: ResponseStatus;
  statusCode: number;
  statusText: string;
  headers: KeyValueItem[];
  cookies: KeyValueItem[];
  body: string;
  binaryBody: ArrayBuffer;
  contentType: string;
  size: string;
  duration: string;
  protocol: string;
  error: ResponseErrorModel;
  previewAvailable: boolean;
}

export type EnvironmentKind = 'development' | 'staging' | 'production';
export type HistoryGroup = 'Today' | 'Yesterday' | 'Previous 7 Days' | 'Older';
export type SettingsSection = 'General' | 'Appearance' | 'Network' | 'Data' | 'Privacy' | 'About';

export interface EnvironmentModel {
  id: string;
  name: string;
  kind: EnvironmentKind;
  variables: KeyValueItem[];
}

export interface HistoryItemModel {
  id: string;
  group: HistoryGroup;
  createdAt: number;
  time: string;
  method: HttpMethod;
  url: string;
  status: number;
  duration: string;
}

export interface SettingsSectionModel {
  id: SettingsSection;
  label: string;
  icon: string;
}

export interface ContextMenuItemModel {
  id: string;
  label: ResourceStr;
  icon: string;
  dangerous: boolean;
}
