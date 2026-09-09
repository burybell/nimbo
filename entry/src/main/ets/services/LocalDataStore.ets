import {
  AppPreferencesModel,
  PersistedAppState,
  PersistedRequestModel,
  PersistedTabModel
} from '../models/PersistenceModels';
import { CollectionNode, EnvironmentModel, HistoryItemModel } from '../models/ShellModels';

interface PersistedAppStateV1 {
  schemaVersion: number;
  collections: CollectionNode[];
  requests: PersistedRequestModel[];
  tabs: PersistedTabModel[];
  activeTabId: string;
  environments: EnvironmentModel[];
  activeEnvironmentId: string;
  history: HistoryItemModel[];
  preferences: AppPreferencesModel;
}

export class LocalDataStore {
  static readonly storageKey: string = 'nimbo.localData';
  static readonly schemaVersion: number = 2;

  static encode(state: PersistedAppState): string {
    return JSON.stringify(state);
  }

  static decode(raw: string): PersistedAppState | undefined {
    if (raw.length === 0) return undefined;
    try {
      const versioned = JSON.parse(raw) as PersistedAppStateV1;
      let state: PersistedAppState;
      if (versioned.schemaVersion === 1) {
        state = LocalDataStore.migrateV1(versioned);
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

  private static migrateV1(state: PersistedAppStateV1): PersistedAppState {
    return {
      schemaVersion: LocalDataStore.schemaVersion,
      savedAt: 0,
      collections: state.collections,
      requests: state.requests,
      tabs: state.tabs,
      activeTabId: state.activeTabId,
      environments: state.environments,
      activeEnvironmentId: state.activeEnvironmentId,
      history: state.history,
      preferences: state.preferences
    };
  }

  private static validPreferences(value: AppPreferencesModel | undefined): boolean {
    return value !== undefined && typeof value.restoreWorkspace === 'boolean' &&
      (value.language === 'en' || value.language === 'zh') && typeof value.followRedirects === 'boolean' &&
      typeof value.sslVerification === 'boolean' && typeof value.defaultTimeoutMs === 'number' &&
      value.defaultTimeoutMs > 0 && typeof value.saveHistory === 'boolean' &&
      typeof value.historyRetentionDays === 'number' && value.historyRetentionDays > 0 &&
      typeof value.maskSecrets === 'boolean';
  }
}
