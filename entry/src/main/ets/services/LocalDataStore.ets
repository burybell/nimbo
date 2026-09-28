import {
  AppPreferencesModel,
  PersistedAppState,
  PersistedRequestModel,
  PersistedTabModel
} from '../models/PersistenceModels';
import { CollectionNode, EnvironmentModel, HistoryItemModel, RequestDraft } from '../models/ShellModels';
import { ShellState } from '../state/ShellState';

interface LegacyPreferencesModel {
  restoreWorkspace: boolean;
  language: 'en' | 'zh';
  followRedirects: boolean;
  sslVerification: boolean;
  defaultTimeoutMs: number;
  saveHistory: boolean;
  historyRetentionDays: number;
  maskSecrets: boolean;
}

interface LegacyPersistedAppState {
  schemaVersion: number;
  savedAt?: number;
  collections: CollectionNode[];
  requests: PersistedRequestModel[];
  tabs: PersistedTabModel[];
  activeTabId: string;
  environments: EnvironmentModel[];
  activeEnvironmentId: string;
  history: HistoryItemModel[];
  preferences: LegacyPreferencesModel;
}

export class LocalDataStore {
  static readonly storageKey: string = 'nimbo.localData';
  static readonly schemaVersion: number = 12;

  static encode(state: PersistedAppState): string {
    return JSON.stringify(state);
  }

  static decode(raw: string): PersistedAppState | undefined {
    if (raw.length === 0) return undefined;
    try {
      const versioned = JSON.parse(raw) as LegacyPersistedAppState;
      const sourceSchemaVersion = versioned.schemaVersion;
      let state: PersistedAppState;
      if (versioned.schemaVersion === 1 || versioned.schemaVersion === 2) {
        state = LocalDataStore.migrateLegacy(versioned);
      } else if (versioned.schemaVersion === 3 || versioned.schemaVersion === 4) {
        state = versioned as PersistedAppState;
        state.preferences.interfaceFont = 'harmony';
        state.schemaVersion = LocalDataStore.schemaVersion;
      } else if (versioned.schemaVersion === 5 || versioned.schemaVersion === 6 ||
        versioned.schemaVersion === 7 || versioned.schemaVersion === 8 || versioned.schemaVersion === 9) {
        state = versioned as PersistedAppState;
        state.schemaVersion = LocalDataStore.schemaVersion;
      } else if (versioned.schemaVersion === 10 || versioned.schemaVersion === 11) {
        state = versioned as PersistedAppState;
        state.schemaVersion = LocalDataStore.schemaVersion;
      } else {
        state = versioned as PersistedAppState;
      }
      if (sourceSchemaVersion < LocalDataStore.schemaVersion) {
        state.collections = ShellState.mergeExampleCatalog(state.collections);
      }
      if (state.schemaVersion !== LocalDataStore.schemaVersion) return undefined;
      if (!Array.isArray(state.collections) || !Array.isArray(state.requests) ||
        !Array.isArray(state.tabs) || !Array.isArray(state.environments) ||
        !Array.isArray(state.history)) return undefined;
      if (typeof state.savedAt !== 'number' || typeof state.activeTabId !== 'string' ||
        typeof state.activeEnvironmentId !== 'string' || !LocalDataStore.validPreferences(state.preferences)) {
        return undefined;
      }
      LocalDataStore.normalizeRequestState(state);
      LocalDataStore.normalizeExampleVariableReferences(state);
      return state;
    } catch (_error) {
      return undefined;
    }
  }

  private static normalizeRequest(request: RequestDraft): void {
    if (request.protocol !== 'websocket' && request.protocol !== 'sse') request.protocol = 'http';
    if (request.preRequestScript === undefined || typeof request.preRequestScript.enabled !== 'boolean' ||
      typeof request.preRequestScript.source !== 'string') {
      request.preRequestScript = { enabled: false, source: '' };
    }
    if (request.postResponseScript === undefined || typeof request.postResponseScript.enabled !== 'boolean' ||
      typeof request.postResponseScript.source !== 'string') {
      request.postResponseScript = { enabled: false, source: '' };
    }
    if (!Array.isArray(request.extractionRules)) request.extractionRules = [];
    if (!Array.isArray(request.testRules)) request.testRules = [];
  }

  private static normalizeRequestState(state: PersistedAppState): void {
    LocalDataStore.normalizeCollectionVariables(state.collections);
    state.requests.forEach((request: PersistedRequestModel) => LocalDataStore.normalizeRequest(request.request));
    state.tabs.forEach((tab: PersistedTabModel) => {
      LocalDataStore.normalizeRequest(tab.request);
    });
  }

  private static normalizeCollectionVariables(nodes: CollectionNode[]): void {
    nodes.forEach((node: CollectionNode) => {
      if (!Array.isArray(node.variables)) node.variables = [];
      LocalDataStore.normalizeCollectionVariables(node.children);
    });
  }

  private static normalizeExampleRequest(id: string, request: RequestDraft): void {
    if (id === 'openai-list-models-request' && request.url === 'https://api.openai.com/v1/models') {
      request.url = '{{OPENAI_BASE_URL}}/v1/models';
    } else if (id === 'openai-create-response-request') {
      if (request.url === 'https://api.openai.com/v1/responses') {
        request.url = '{{OPENAI_BASE_URL}}/v1/responses';
      }
      request.bodyText = request.bodyText.replace('"model": "gpt-5"', '"model": "{{OPENAI_MODEL}}"');
    } else if (id === 'deepseek-list-models-request' && request.url === 'https://api.deepseek.com/models') {
      request.url = '{{DEEPSEEK_BASE_URL}}/models';
    } else if (id === 'deepseek-chat-request') {
      if (request.url === 'https://api.deepseek.com/chat/completions') {
        request.url = '{{DEEPSEEK_BASE_URL}}/chat/completions';
      }
      request.bodyText = request.bodyText.replace('"model": "deepseek-flash"',
        '"model": "{{DEEPSEEK_MODEL}}"');
    }
  }

  private static normalizeExampleVariableReferences(state: PersistedAppState): void {
    state.requests.forEach((item: PersistedRequestModel) =>
      LocalDataStore.normalizeExampleRequest(item.id, item.request));
    state.tabs.forEach((item: PersistedTabModel) =>
      LocalDataStore.normalizeExampleRequest(item.id, item.request));
  }

  private static migrateLegacy(state: LegacyPersistedAppState): PersistedAppState {
    return {
      schemaVersion: LocalDataStore.schemaVersion,
      savedAt: state.savedAt ?? 0,
      collections: state.collections,
      requests: state.requests,
      tabs: state.tabs,
      activeTabId: state.activeTabId,
      environments: state.environments,
      activeEnvironmentId: state.activeEnvironmentId,
      history: state.history,
      preferences: {
        restoreWorkspace: state.preferences.restoreWorkspace,
        language: state.preferences.language,
        theme: 'system',
        interfaceFont: 'harmony',
        followRedirects: state.preferences.followRedirects,
        sslVerification: state.preferences.sslVerification,
        defaultTimeoutMs: state.preferences.defaultTimeoutMs,
        saveHistory: state.preferences.saveHistory,
        historyRetentionDays: state.preferences.historyRetentionDays,
        maskSecrets: state.preferences.maskSecrets
      }
    };
  }

  private static validPreferences(value: AppPreferencesModel | undefined): boolean {
    return value !== undefined && typeof value.restoreWorkspace === 'boolean' &&
      (value.language === 'en' || value.language === 'zh') && typeof value.followRedirects === 'boolean' &&
      (value.theme === 'system' || value.theme === 'light' || value.theme === 'dark') &&
      (value.interfaceFont === 'harmony' || value.interfaceFont === 'system' || value.interfaceFont === 'compact') &&
      typeof value.sslVerification === 'boolean' && typeof value.defaultTimeoutMs === 'number' &&
      value.defaultTimeoutMs > 0 && typeof value.saveHistory === 'boolean' &&
      typeof value.historyRetentionDays === 'number' && value.historyRetentionDays > 0 &&
      typeof value.maskSecrets === 'boolean';
  }
}
