export type NavigationDestination = 'workspace' | 'collections' | 'environments' | 'history' | 'settings';
export type CollectionNodeType = 'collection' | 'folder' | 'request';
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'HEAD' | 'OPTIONS';
export type RequestConfigTab = 'params' | 'headers' | 'auth' | 'body' | 'preRequest' | 'extract' | 'tests' | 'settings';
export type RequestLifecycle = 'idle' | 'sending';
export type KeyValueMode = 'params' | 'headers' | 'form' | 'multipart' | 'environment';
export type AuthType = 'none' | 'bearer' | 'basic' | 'apiKey';
export type BodyType = 'none' | 'json' | 'text' | 'form' | 'multipart' | 'binary';
export type ResponseStatus = 'empty' | 'sending' | 'success' | 'error' | 'large' | 'binary' | 'cancelled';
export type ResponseTab = 'body' | 'headers' | 'cookies' | 'tests' | 'timeline';
export type ResponseBodyMode = 'pretty' | 'raw';
export type ResponseMediaKind = 'none' | 'image' | 'video';
export type ResponseErrorType = 'dns' | 'connectionRefused' | 'timeout' | 'tls' |
  'connectionReset' | 'invalidUrl' | 'proxy' | 'script' | 'cancelled' | 'unknown';

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

export type ExtractionStatus = 'success' | 'notRun' | 'noMatch' | 'invalidJson' | 'invalidPath' |
  'targetMissing' | 'conflict';

export interface ExtractionRule {
  id: string;
  enabled: boolean;
  variableName: string;
  jsonPath: string;
  environmentId: string;
  secret: boolean;
  overwrite: boolean;
}

export interface ExtractionResult {
  ruleId: string;
  status: ExtractionStatus;
  value: string;
  message: string;
}

export type TestRuleKind = 'statusEquals' | 'durationLessThan' | 'headerExists' | 'headerEquals' |
  'jsonPathExists' | 'jsonPathEquals';
export type TestResultStatus = 'passed' | 'failed' | 'notRun';
export type TestResultMessage = 'configurationInvalid' | 'statusMatched' | 'statusMismatch' |
  'durationMatched' | 'durationMismatch' | 'durationUnavailable' | 'headerPresent' | 'headerMissing' |
  'headerMatched' | 'headerMismatch' | 'jsonPathMatched' | 'jsonPathMismatch' | 'jsonPathNoMatch' |
  'invalidJson' | 'invalidJsonPath' | 'responseUnavailable';

export interface TestRule {
  id: string;
  enabled: boolean;
  kind: TestRuleKind;
  target: string;
  expected: string;
}

export interface TestResult {
  ruleId: string;
  status: TestResultStatus;
  actual: string;
  expected: string;
  message: TestResultMessage;
}

export interface RequestScript {
  enabled: boolean;
  source: string;
}

export type ScriptPhase = 'preRequest' | 'postResponse';
export type ScriptExecutionStatus = 'success' | 'error' | 'timeout' | 'memoryLimit';

export interface ScriptExecutionResult {
  phase: ScriptPhase;
  status: ScriptExecutionStatus;
  error: string;
  durationMs: number;
  logs: string[];
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
  preRequestScript: RequestScript;
  extractionRules: ExtractionRule[];
  testRules: TestRule[];
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
  mediaKind: ResponseMediaKind;
  mediaUri: string;
  contentType: string;
  size: string;
  duration: string;
  protocol: string;
  error: ResponseErrorModel;
  previewAvailable: boolean;
  scriptResults: ScriptExecutionResult[];
  extractionResults: ExtractionResult[];
  testResults: TestResult[];
}

export type EnvironmentKind = 'development' | 'staging' | 'production' | 'custom';
export type HistoryGroup = 'Today' | 'Yesterday' | 'Previous 7 Days' | 'Older';
export type SettingsSection = 'General' | 'Appearance' | 'Network' | 'Data' | 'Privacy' | 'About';

export interface EnvironmentModel {
  id: string;
  name: string;
  kind: EnvironmentKind;
  variables: KeyValueItem[];
  system?: boolean;
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
