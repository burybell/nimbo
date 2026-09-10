import {
  CollectionNode,
  EnvironmentModel,
  HistoryItemModel,
  HttpMethod,
  RequestDraft
} from './ShellModels';

export type NimboLanguage = 'en' | 'zh';
export type NimboTheme = 'system' | 'light' | 'dark';
export type NimboFont = 'harmony' | 'system' | 'compact';

export interface AppPreferencesModel {
  restoreWorkspace: boolean;
  language: NimboLanguage;
  theme: NimboTheme;
  interfaceFont: NimboFont;
  followRedirects: boolean;
  sslVerification: boolean;
  defaultTimeoutMs: number;
  saveHistory: boolean;
  historyRetentionDays: number;
  maskSecrets: boolean;
}

export interface PersistedRequestModel {
  id: string;
  name: string;
  method: HttpMethod;
  request: RequestDraft;
}

export interface PersistedTabModel {
  id: string;
  name: string;
  method: HttpMethod;
  dirty: boolean;
  pinned: boolean;
  request: RequestDraft;
}

export interface PersistedAppState {
  schemaVersion: number;
  savedAt: number;
  collections: CollectionNode[];
  requests: PersistedRequestModel[];
  tabs: PersistedTabModel[];
  activeTabId: string;
  environments: EnvironmentModel[];
  activeEnvironmentId: string;
  history: HistoryItemModel[];
  preferences: AppPreferencesModel;
}
