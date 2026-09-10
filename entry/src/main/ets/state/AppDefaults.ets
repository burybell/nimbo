import { AppPreferencesModel } from '../models/PersistenceModels';
import { EnvironmentModel } from '../models/ShellModels';

export function createDefaultEnvironments(): EnvironmentModel[] {
  return [
    { id: 'development', name: '开发环境', kind: 'development', variables: [], system: true },
    { id: 'staging', name: '预发布环境', kind: 'staging', variables: [], system: true },
    { id: 'production', name: '生产环境', kind: 'production', variables: [], system: true }
  ];
}

export function normalizeEnvironments(environments: EnvironmentModel[]): EnvironmentModel[] {
  const defaults = createDefaultEnvironments();
  const normalized: EnvironmentModel[] = defaults.map((fallback: EnvironmentModel) => {
    const existing = environments.find((item: EnvironmentModel) => item.id === fallback.id);
    if (!existing) return fallback;
    return {
      id: fallback.id,
      name: fallback.name,
      kind: fallback.kind,
      variables: existing.variables,
      system: true
    };
  });
  environments.forEach((environment: EnvironmentModel) => {
    if (!defaults.some((item: EnvironmentModel) => item.id === environment.id)) {
      normalized.push(environment);
    }
  });
  return normalized;
}

export function createDefaultPreferences(): AppPreferencesModel {
  return {
    restoreWorkspace: true,
    language: 'en',
    theme: 'system',
    interfaceFont: 'harmony',
    followRedirects: true,
    sslVerification: true,
    defaultTimeoutMs: 30000,
    saveHistory: true,
    historyRetentionDays: 30,
    maskSecrets: true
  };
}
