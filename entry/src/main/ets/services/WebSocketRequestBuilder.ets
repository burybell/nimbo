import { util } from '@kit.ArkTS';
import { EnvironmentModel, KeyValueItem, RequestDraft } from '../models/ShellModels';

export interface WebSocketConnectionConfig {
  url: string;
  headers: Record<string, string>;
  unresolvedVariables: string[];
}

export class WebSocketRequestBuilder {
  private static variableNames(value: string): string[] {
    const names: string[] = [];
    const pattern = /\{\{\s*([^{}]+?)\s*\}\}/g;
    let match = pattern.exec(value);
    while (match !== null) {
      const name = match[1].trim();
      if (name.length > 0 && !names.includes(name)) names.push(name);
      match = pattern.exec(value);
    }
    return names;
  }

  static unresolved(value: string, environment: EnvironmentModel): string[] {
    const available = new Set<string>();
    environment.variables.forEach((item: KeyValueItem) => {
      if (item.enabled && item.key.trim().length > 0 && item.value.length > 0) available.add(item.key.trim());
    });
    return WebSocketRequestBuilder.variableNames(value).filter((name: string) => !available.has(name));
  }

  static resolve(value: string, environment: EnvironmentModel): string {
    let resolved = value;
    environment.variables.forEach((item: KeyValueItem) => {
      if (!item.enabled || item.key.trim().length === 0) return;
      resolved = resolved.split(`{{${item.key.trim()}}}`).join(item.value);
    });
    return resolved;
  }

  static build(request: RequestDraft, environment: EnvironmentModel): WebSocketConnectionConfig {
    const values: string[] = [request.url];
    request.headers.forEach((item: KeyValueItem) => {
      if (item.enabled) values.push(item.key, item.value);
    });
    if (request.auth.type === 'bearer') values.push(request.auth.bearerToken);
    if (request.auth.type === 'basic') values.push(request.auth.username, request.auth.password);
    if (request.auth.type === 'apiKey') values.push(request.auth.apiKey, request.auth.apiValue);
    const unresolved: string[] = [];
    values.forEach((value: string) => WebSocketRequestBuilder.unresolved(value, environment)
      .forEach((name: string) => { if (!unresolved.includes(name)) unresolved.push(name); }));

    let url = WebSocketRequestBuilder.resolve(request.url.trim(), environment);
    const headers: Record<string, string> = {};
    request.headers.forEach((item: KeyValueItem) => {
      if (!item.enabled || item.key.trim().length === 0) return;
      headers[WebSocketRequestBuilder.resolve(item.key, environment)] =
        WebSocketRequestBuilder.resolve(item.value, environment);
    });
    if (request.auth.type === 'bearer' && request.auth.bearerToken.length > 0) {
      headers['Authorization'] = `Bearer ${WebSocketRequestBuilder.resolve(request.auth.bearerToken, environment)}`;
    } else if (request.auth.type === 'basic') {
      const username = WebSocketRequestBuilder.resolve(request.auth.username, environment);
      const password = WebSocketRequestBuilder.resolve(request.auth.password, environment);
      const bytes = new util.TextEncoder().encodeInto(`${username}:${password}`);
      headers['Authorization'] = `Basic ${new util.Base64Helper().encodeToStringSync(bytes)}`;
    } else if (request.auth.type === 'apiKey' && request.auth.apiKey.length > 0) {
      const key = WebSocketRequestBuilder.resolve(request.auth.apiKey, environment);
      const value = WebSocketRequestBuilder.resolve(request.auth.apiValue, environment);
      if (request.auth.apiLocation === 'header') headers[key] = value;
      else url += `${url.includes('?') ? '&' : '?'}${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
    }
    return { url, headers, unresolvedVariables: unresolved };
  }
}
