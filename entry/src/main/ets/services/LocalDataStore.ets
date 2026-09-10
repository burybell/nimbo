import {
  AppPreferencesModel,
  PersistedAppState,
  PersistedRequestModel,
  PersistedTabModel
} from '../models/PersistenceModels';
import { CollectionNode, EnvironmentModel, HistoryItemModel } from '../models/ShellModels';

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
  static readonly schemaVersion: number = 5;

  static encode(state: PersistedAppState): string {
    return JSON.stringify(state);
  }

  static decode(raw: string): PersistedAppState | undefined {
    if (raw.length === 0) return undefined;
    try {
      const versioned = JSON.parse(raw) as LegacyPersistedAppState;
      let state: PersistedAppState;
      if (versioned.schemaVersion === 1 || versioned.schemaVersion === 2) {
        state = LocalDataStore.migrateLegacy(versioned);
      } else if (versioned.schemaVersion === 3 || versioned.schemaVersion === 4) {
        state = versioned as PersistedAppState;
        state.preferences.interfaceFont = 'harmony';
        state.schemaVersion = LocalDataStore.schemaVersion;
      } else {
        state = versioned as PersistedAppState;
      }
      if (state.schemaVersion !== LocalDataStore.schemaVersion) return undefined;
      if (!Array.isArray(state.collections) || !Array.isArray(state.requests) ||
        !Array.isArray(state.tabs) || !Array.isArray(state.environments) ||
        !Array.isArray(state.history)) return undefined;
      if (typeof state.savedAt !== 'number' || typeof state.activeTabId !== 'string' ||
        typeof state.activeEnvironmentId !== 'string' || !LocalDataStore.validPreferences(state.preferences)) {
        return undefined;
      }
      return state;
    } catch (_error) {
      return undefined;
    }
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
