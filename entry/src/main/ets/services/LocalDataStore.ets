import { PersistedAppState } from '../models/PersistenceModels';

export class LocalDataStore {
  static readonly storageKey: string = 'nimbo.localData';
  static readonly schemaVersion: number = 1;

  static encode(state: PersistedAppState): string {
    return JSON.stringify(state);
  }

  static decode(raw: string): PersistedAppState | undefined {
    if (raw.length === 0) return undefined;
    try {
      const state = JSON.parse(raw) as PersistedAppState;
      if (state.schemaVersion !== LocalDataStore.schemaVersion) return undefined;
      if (!Array.isArray(state.collections) || !Array.isArray(state.requests) ||
        !Array.isArray(state.tabs) || !Array.isArray(state.environments) ||
        !Array.isArray(state.history)) return undefined;
      return state;
    } catch (_error) {
      return undefined;
    }
  }
}
