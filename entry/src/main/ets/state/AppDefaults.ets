import { AppPreferencesModel } from '../models/PersistenceModels';

export function createDefaultPreferences(): AppPreferencesModel {
  return {
    restoreWorkspace: true,
    language: 'en',
    theme: 'system',
    followRedirects: true,
    sslVerification: true,
    defaultTimeoutMs: 30000,
    saveHistory: true,
    historyRetentionDays: 30,
    maskSecrets: true
  };
}
