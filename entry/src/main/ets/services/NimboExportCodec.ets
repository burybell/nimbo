import { PersistedAppState } from '../models/PersistenceModels';
import { KeyValueItem, RequestDraft } from '../models/ShellModels';

interface NimboExportDocument {
  format: string;
  formatVersion: number;
  exportedAt: string;
  includesSecrets: boolean;
  redaction: string;
  data: PersistedAppState;
}

export class NimboExportCodec {
  private static readonly redacted: string = '<redacted>';

  private static sensitiveKey(key: string): boolean {
    const value = key.toLowerCase().split('_').join('-');
    return value.includes('authorization') || value.includes('password') || value.includes('secret') ||
      value.includes('token') || value.includes('api-key') || value === 'cookie' || value === 'set-cookie';
  }

  private static redactItems(items: KeyValueItem[]): void {
    items.forEach((item: KeyValueItem) => {
      if (item.secret || NimboExportCodec.sensitiveKey(item.key)) item.value = NimboExportCodec.redacted;
    });
  }

  private static redactUrl(value: string): string {
    const queryIndex = value.indexOf('?');
    if (queryIndex < 0) return value;
    const fragmentIndex = value.indexOf('#', queryIndex);
    const queryEnd = fragmentIndex < 0 ? value.length : fragmentIndex;
    const query = value.substring(queryIndex + 1, queryEnd).split('&').map((part: string) => {
      const separator = part.indexOf('=');
      const key = separator < 0 ? part : part.substring(0, separator);
      let decodedKey = key;
      try { decodedKey = decodeURIComponent(key); } catch (_error) {}
      return NimboExportCodec.sensitiveKey(decodedKey) ? `${key}=${NimboExportCodec.redacted}` : part;
    }).join('&');
    return `${value.substring(0, queryIndex + 1)}${query}${value.substring(queryEnd)}`;
  }

  private static redactRequest(request: RequestDraft): void {
    request.url = NimboExportCodec.redactUrl(request.url);
    NimboExportCodec.redactItems(request.params);
    NimboExportCodec.redactItems(request.headers);
    NimboExportCodec.redactItems(request.formItems);
    NimboExportCodec.redactItems(request.multipartItems);
    request.auth.bearerToken = request.auth.bearerToken.length > 0 ? NimboExportCodec.redacted : '';
    request.auth.password = request.auth.password.length > 0 ? NimboExportCodec.redacted : '';
    request.auth.apiValue = request.auth.apiValue.length > 0 ? NimboExportCodec.redacted : '';
  }

  static encode(state: PersistedAppState, includeSecrets: boolean): string {
    const data = JSON.parse(JSON.stringify(state)) as PersistedAppState;
    if (!includeSecrets) {
      data.requests.forEach((item) => NimboExportCodec.redactRequest(item.request));
      data.tabs.forEach((item) => NimboExportCodec.redactRequest(item.request));
      data.environments.forEach((environment) => NimboExportCodec.redactItems(environment.variables));
      data.history.forEach((item) => { item.url = NimboExportCodec.redactUrl(item.url); });
    }
    const document: NimboExportDocument = {
      format: 'nimbo', formatVersion: 1, exportedAt: new Date().toISOString(), includesSecrets: includeSecrets,
      redaction: includeSecrets ? 'none' : 'marked and sensitive fields', data
    };
    return JSON.stringify(document, null, 2);
  }
}
