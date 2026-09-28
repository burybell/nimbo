import {
  BodyType,
  CollectionNode,
  EffectiveVariableModel,
  ExtractionResult,
  ExtractionRule,
  ExtractionStatus,
  HttpMethod,
  NavigationDestination,
  RequestDraft,
  RequestProtocol,
  RequestTabModel,
  RunnerItemModel,
  ScriptExecutionResult,
  ResponseErrorModel,
  ResponseModel,
  ResponseStatus,
  SseEventModel,
  SseSessionModel,
  TestResult,
  VariableSourceKind,
  VariableSourceModel,
  WebSocketConnectionRecord,
  WebSocketMessageModel,
  WebSocketSessionModel
} from '../models/ShellModels';
import { EnvironmentModel, HistoryItemModel, KeyValueItem } from '../models/ShellModels';
import {
  AppPreferencesModel,
  NimboFont,
  NimboTheme,
  PersistedAppState,
  PersistedRequestModel,
  PersistedTabModel
} from '../models/PersistenceModels';
import { ShellState } from '../state/ShellState';
import { createDefaultEnvironments, createDefaultPreferences, normalizeEnvironments } from '../state/AppDefaults';
import { LocalDataStore } from '../services/LocalDataStore';
import { JsonPathResult, JsonPathService } from '../services/JsonPathService';
import { ResponseTestService } from '../services/ResponseTestService';
import {
  PostResponseExecution,
  PreRequestExecution,
  ScriptEnvironmentSnapshot,
  ScriptRequestSnapshot,
  ScriptResponseSnapshot,
  ScriptResult,
  ScriptRuntimeService
} from '../services/ScriptRuntimeService';
import { CurlCodec, CurlImportResult } from '../services/CurlCodec';
import { PostmanImportResult } from '../services/PostmanCodec';
import { OpenApiImportResult } from '../services/OpenApiCodec';
import { LocalFileExporter } from '../services/LocalFileExporter';
import { MediaPreviewStore } from '../services/MediaPreviewStore';
import { NimboExportCodec } from '../services/NimboExportCodec';
import { RequestController } from '../controller/RequestController';
import { WebSocketController, WebSocketEvent } from '../controller/WebSocketController';
import { SseController, SseControllerEvent } from '../controller/SseController';
import { WindowChromeController } from '../services/WindowChromeController';
import { WebSocketRequestBuilder } from '../services/WebSocketRequestBuilder';
import { RunnerDataSet, RunnerDataService } from '../services/RunnerDataService';
import {
  createBinaryResponse,
  createCancelledResponse,
  createEmptyRequest,
  createEmptyResponse,
  createErrorResponse,
  createLargeResponse,
  createSuccessResponse
} from '../mock/ShellMockData';
import { DEMO_HISTORY } from '../mock/SupportingMockData';
import { CollectionSidebar } from '../ui/components/collection/CollectionSidebar';
import { CollectionNameDialog } from '../ui/components/collection/CollectionNameDialog';
import { CollectionRunnerDialog } from '../ui/components/collection/CollectionRunnerDialog';
import { CollectionVariablesDialog } from '../ui/components/collection/CollectionVariablesDialog';
import { CollectionTarget, SaveRequestDialog } from '../ui/components/collection/SaveRequestDialog';
import { GlobalToolbar } from '../ui/components/common/GlobalToolbar';
import { MobileNavigation } from '../ui/components/common/MobileNavigation';
import { NimboDialog } from '../ui/components/common/NimboDialog';
import { NimboToast } from '../ui/components/common/NimboToast';
import { PrimarySidebar } from '../ui/components/common/PrimarySidebar';
import { EnvironmentPage } from '../ui/components/environment/EnvironmentPage';
import { HistoryPage } from '../ui/components/history/HistoryPage';
import { HelpPage } from '../ui/components/help/HelpPage';
import { ApiFileImportDialog } from '../ui/components/importer/ApiFileImportDialog';
import { Workspace } from '../ui/components/request/Workspace';
import { SettingsPage } from '../ui/components/settings/SettingsPage';
import { GlobalSearchDialog, GlobalSearchItem } from '../ui/components/search/GlobalSearchDialog';
import { ColorTokens } from '../ui/tokens/ColorTokens';
import { BreakpointTokens, SizeTokens, SpacingTokens } from '../ui/tokens/LayoutTokens';
import { MotionTokens } from '../ui/tokens/MotionTokens';
import { i18n } from '@kit.LocalizationKit';
import { common, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

interface RequestPipelineResult {
  response: ResponseModel;
  executedRequest: RequestDraft;
}

interface CollectionRequestSeed {
  request: RequestDraft;
  response: ResponseModel;
}

interface RunnerReportSummary {
  total: number;
  passed: number;
  failed: number;
  cancelled: number;
}

interface RunnerReportItem {
  name: string;
  method: HttpMethod;
  iteration: number;
  status: string;
  statusCode: number;
  duration: string;
  passedTests: number;
  failedTests: number;
  message: string;
  details: string[];
}

interface RunnerReportDocument {
  format: string;
  generatedAt: string;
  startedAt: string;
  scope: string;
  environment: string;
  dataFile: string;
  dataRows: number;
  summary: RunnerReportSummary;
  items: RunnerReportItem[];
}

@Component
export struct NimboWindow {
  @StorageLink('nimbo.localData') persistedData: string = '';
  @StorageLink('collection.sidebarWidth') collectionSidebarWidth: number = SizeTokens.collectionSidebarWidth;
  @State windowWidth: number = 1440;
  @State activeDestination: NavigationDestination = 'collections';
  @State collections: CollectionNode[] = ShellState.createInitialCollections();
  @State tabs: RequestTabModel[] = ShellState.createInitialTabs();
  @State activeTabId: string = 'get-users';
  @State environments: EnvironmentModel[] = createDefaultEnvironments();
  @State historyItems: HistoryItemModel[] = DEMO_HISTORY;
  @State activeOverlay: string = '';
  @State toastMessage: ResourceStr = '';
  @State toastVisible: boolean = false;
  @State toastActionVisible: boolean = false;
  @State lastDeletedHistory: HistoryItemModel[] = [];
  @State selectedEnvironmentId: string = 'development';
  @State savedRequests: PersistedRequestModel[] = [];
  @State preferences: AppPreferencesModel = createDefaultPreferences();
  @State collectionDrawerOpen: boolean = false;
  @State collectionParentId: string = '';
  @State pendingSaveTabId: string = '';
  @State collectionSplitterHovered: boolean = false;
  @State collectionSplitterResizing: boolean = false;
  @State collectionSplitterDragStart: number = SizeTokens.collectionSidebarWidth;
  @State renamingFolderId: string = '';
  @State renamingRequestId: string = '';
  @State deletingCollectionNodeId: string = '';
  @State deletingEnvironmentId: string = '';
  @State editingCollectionVariablesId: string = '';
  @State editingCollectionVariablesName: string = '';
  @State editingCollectionVariables: KeyValueItem[] = [];
  @State runnerTargetId: string = '';
  @State runnerTargetName: string = '';
  @State runnerEnvironmentName: string = '';
  @State runnerItems: RunnerItemModel[] = [];
  @State runnerRunning: boolean = false;
  @State runnerDataFileName: string = '';
  @State runnerDataRowCount: number = 0;
  @State runnerDataColumns: string = '';
  @State runnerDataError: string = '';
  @State webSocketSessions: WebSocketSessionModel[] = [];
  @State sseSessions: SseSessionModel[] = [];
  private nextTabNumber: number = 1;
  private nextCollectionNodeNumber: number = 1;
  private requestController: RequestController = new RequestController();
  private webSocketController: WebSocketController = new WebSocketController();
  private sseController: SseController = new SseController();
  private webSocketMessageSerial: number = 0;
  private sseEventSerial: number = 0;
  private requestPersistenceTimer: number = -1;
  private requestSerials: Map<string, number> = new Map<string, number>();
  private realtimeHistoryIds: Map<string, string> = new Map<string, string>();
  private runnerSerial: number = 0;
  private runnerExecutionId: string = '';
  private runnerStartedAt: string = '';
  private runnerDataSet: RunnerDataSet | undefined = undefined;
  private runnerRunDataFileName: string = '';
  private runnerRunDataRowCount: number = 0;
  private stateReady: boolean = false;

  aboutToAppear(): void {
    this.restoreLocalData();
  }

  aboutToDisappear(): void {
    this.webSocketController.disconnectAll();
    this.sseController.stopAll();
  }

  private idleRequest(request: RequestDraft): RequestDraft {
    return this.requestWithLifecycle(request, 'idle');
  }

  private restoredTab(tab: PersistedTabModel): RequestTabModel {
    return {
      id: tab.id,
      name: tab.name,
      method: tab.method,
      dirty: tab.dirty,
      pinned: tab.pinned,
      loading: false,
      request: this.idleRequest(tab.request),
      response: createEmptyResponse()
    };
  }

  private restoreNextTabNumber(): void {
    let next = 1;
    this.savedRequests.forEach((item: PersistedRequestModel) => {
      if (!item.id.startsWith('untitled-')) return;
      const value = Number.parseInt(item.id.substring('untitled-'.length));
      if (!Number.isNaN(value) && value >= next) next = value + 1;
    });
    this.nextTabNumber = next;
  }

  private persistedTab(tab: RequestTabModel): PersistedTabModel {
    return {
      id: tab.id,
      name: tab.name,
      method: tab.method,
      dirty: tab.dirty,
      pinned: tab.pinned,
      request: this.idleRequest(tab.request)
    };
  }

  private normalizedHistoryItem(item: HistoryItemModel): HistoryItemModel {
    return {
      id: item.id,
      group: this.historyGroup(item.createdAt),
      createdAt: item.createdAt,
      time: item.time,
      method: item.method,
      url: item.url,
      status: item.status,
      duration: item.duration,
      protocol: item.protocol ?? 'http'
    };
  }

  private restoreLocalData(): void {
    const state = LocalDataStore.decode(this.persistedData);
    if (state) {
      this.collections = state.collections;
      this.savedRequests = state.requests;
      this.restoreNextTabNumber();
      this.environments = normalizeEnvironments(state.environments);
      this.selectedEnvironmentId = this.environments.some((item: EnvironmentModel) =>
        item.id === state.activeEnvironmentId) ? state.activeEnvironmentId : 'development';
      this.preferences = state.preferences;
      this.historyItems = this.normalizeHistory(state.history);
      if (state.preferences.restoreWorkspace) {
        this.tabs = state.tabs.map((tab: PersistedTabModel) => this.restoredTab(tab));
        this.activeTabId = this.tabs.some((tab: RequestTabModel) => tab.id === state.activeTabId) ?
          state.activeTabId : (this.tabs.length > 0 ? this.tabs[0].id : '');
      } else {
        this.tabs = [];
        this.activeTabId = '';
      }
    } else if (this.persistedData.length > 0) {
      this.applySafeDefaults();
    }
    this.applyTheme(this.preferences.theme);
    this.applyFont(this.preferences.interfaceFont);
    this.webSocketSessions = this.tabs.filter((tab: RequestTabModel) =>
      tab.request.protocol === 'websocket').map((tab: RequestTabModel) => this.emptyWebSocketSession(tab.id));
    this.sseSessions = this.tabs.filter((tab: RequestTabModel) =>
      tab.request.protocol === 'sse').map((tab: RequestTabModel) => this.emptySseSession(tab.id));
    this.stateReady = true;
    this.persistLocalData();
  }

  private applySafeDefaults(): void {
    const preferences = createDefaultPreferences();
    const request = createEmptyRequest();
    request.settings = {
      timeoutMs: preferences.defaultTimeoutMs,
      followRedirects: preferences.followRedirects,
      sslVerification: preferences.sslVerification,
      useCookieJar: true
    };
    const tab: RequestTabModel = {
      id: 'untitled-1', name: 'Untitled Request 1', method: 'GET', dirty: false,
      pinned: false, loading: false, request, response: createEmptyResponse()
    };
    this.collections = [];
    this.tabs = [tab];
    this.activeTabId = tab.id;
    this.environments = createDefaultEnvironments();
    this.historyItems = [];
    this.lastDeletedHistory = [];
    this.selectedEnvironmentId = 'development';
    this.savedRequests = [{ id: tab.id, name: tab.name, method: tab.method, request: this.idleRequest(request) }];
    this.preferences = preferences;
    this.nextTabNumber = 2;
  }

  private historyGroup(createdAt: number): 'Today' | 'Yesterday' | 'Previous 7 Days' | 'Older' {
    const age = Date.now() - createdAt;
    if (age < 86400000) return 'Today';
    if (age < 2 * 86400000) return 'Yesterday';
    if (age < 7 * 86400000) return 'Previous 7 Days';
    return 'Older';
  }

  private normalizeHistory(items: HistoryItemModel[]): HistoryItemModel[] {
    const cutoff = Date.now() - this.preferences.historyRetentionDays * 86400000;
    return items.filter((item: HistoryItemModel) => item.createdAt >= cutoff)
      .map((item: HistoryItemModel) => this.normalizedHistoryItem(item));
  }

  private rememberRequest(id: string, name: string, request: RequestDraft): void {
    const saved: PersistedRequestModel = { id, name, method: request.method, request: this.idleRequest(request) };
    const exists = this.savedRequests.some((item: PersistedRequestModel) => item.id === id);
    this.savedRequests = exists ? this.savedRequests.map((item: PersistedRequestModel) =>
      item.id === id ? saved : item) : [...this.savedRequests, saved];
  }

  private persistedState(): PersistedAppState {
    const tabs: PersistedTabModel[] = this.preferences.restoreWorkspace ?
      this.tabs.map((tab: RequestTabModel) => this.persistedTab(tab)) : [];
    return {
      schemaVersion: LocalDataStore.schemaVersion,
      savedAt: Date.now(),
      collections: this.collections,
      requests: this.savedRequests,
      tabs,
      activeTabId: this.activeTabId,
      environments: this.environments,
      activeEnvironmentId: this.selectedEnvironmentId,
      history: this.normalizeHistory(this.historyItems),
      preferences: this.preferences
    };
  }

  private persistLocalData(): void {
    if (!this.stateReady) return;
    if (this.requestPersistenceTimer >= 0) {
      clearTimeout(this.requestPersistenceTimer);
      this.requestPersistenceTimer = -1;
    }
    this.persistedData = LocalDataStore.encode(this.persistedState());
  }

  private scheduleRequestPersistence(): void {
    if (this.requestPersistenceTimer >= 0) clearTimeout(this.requestPersistenceTimer);
    this.requestPersistenceTimer = setTimeout(() => {
      this.requestPersistenceTimer = -1;
      this.persistLocalData();
    }, 180);
  }

  private isCompact(): boolean {
    return this.windowWidth < BreakpointTokens.desktop;
  }

  private isPhone(): boolean {
    return this.windowWidth < BreakpointTokens.tablet;
  }

  private layoutClass(width: number): number {
    if (width < BreakpointTokens.tablet) return 0;
    if (width < BreakpointTokens.desktop) return 1;
    return 2;
  }

  private createRequest(method: HttpMethod = 'GET'): RequestDraft {
    const request = createEmptyRequest(method);
    request.settings = {
      timeoutMs: this.preferences.defaultTimeoutMs,
      followRedirects: this.preferences.followRedirects,
      sslVerification: this.preferences.sslVerification,
      useCookieJar: true
    };
    return request;
  }

  private collectionWidth(): number {
    if (this.isPhone()) return SizeTokens.collectionSidebarCompactWidth;
    return Math.max(SizeTokens.collectionSidebarMinWidth,
      Math.min(SizeTokens.collectionSidebarMaxWidth, this.collectionSidebarWidth));
  }

  private resizeCollectionSidebar(width: number): void {
    this.collectionSidebarWidth = Math.max(SizeTokens.collectionSidebarMinWidth,
      Math.min(SizeTokens.collectionSidebarMaxWidth, width));
  }

  private showCollectionSidebar(): boolean {
    return this.activeDestination === 'collections' && this.windowWidth >= BreakpointTokens.tablet;
  }

  private showCollectionDrawer(): boolean {
    return this.activeDestination === 'collections' && this.isPhone() &&
      this.collectionDrawerOpen;
  }

  private animateState(change: () => void, duration: number = MotionTokens.normal): void {
    this.getUIContext().animateTo({ duration, curve: MotionTokens.standardCurve }, change);
  }

  private showOverlay(name: string): void {
    this.animateState(() => { this.activeOverlay = name; });
  }

  private appendCollectionSearchItems(nodes: CollectionNode[], items: GlobalSearchItem[]): void {
    nodes.forEach((node: CollectionNode) => {
      if (node.type === 'request') {
        items.push({ id: `request:${node.id}`, title: node.name,
          subtitle: node.method ?? 'GET', keywords: `${node.name} ${node.method ?? ''} request 请求`, icon: '□' });
      } else {
        items.push({ id: `collection:${node.id}`, title: node.name,
          subtitle: node.type === 'collection' ? $r('app.string.nav_collections') : $r('app.string.folders'),
          keywords: `${node.name} collection folder 集合 文件夹`, icon: node.type === 'collection' ? '▣' : '◇' });
        this.appendCollectionSearchItems(node.children, items);
      }
    });
  }

  private globalSearchItems(): GlobalSearchItem[] {
    const items: GlobalSearchItem[] = [
      { id: 'command:new', title: $r('app.string.search_new_request'),
        subtitle: $r('app.string.search_command'), keywords: 'new request create 新建 请求', icon: '+' },
      { id: 'command:import', title: $r('app.string.import_title'),
        subtitle: $r('app.string.search_command'),
        keywords: 'import curl postman openapi swagger collection schema 导入 集合 接口 文档', icon: '⇧' },
      { id: 'command:environments', title: $r('app.string.search_manage_environments'),
        subtitle: $r('app.string.search_command'), keywords: 'environment manage 环境 管理', icon: '◎' },
      { id: 'command:settings', title: $r('app.string.nav_settings'),
        subtitle: $r('app.string.search_command'), keywords: 'settings preferences 设置 偏好', icon: '⚙' },
      { id: 'command:help', title: $r('app.string.nav_help'),
        subtitle: $r('app.string.search_command'), keywords: 'help guide docs documentation 帮助 指南 文档', icon: '?' }
    ];
    this.appendCollectionSearchItems(this.collections, items);
    this.savedRequests.forEach((request: PersistedRequestModel) => {
      if (!this.findCollectionNode(this.collections, request.id)) {
        items.push({ id: `request:${request.id}`, title: request.name,
          subtitle: request.request.url.length > 0 ? request.request.url : request.method,
          keywords: `${request.name} ${request.method} ${request.request.url} request 请求`, icon: '□' });
      }
    });
    this.historyItems.forEach((history: HistoryItemModel) => {
      items.push({ id: `history:${history.id}`, title: `${history.method} ${history.url}`,
        subtitle: $r('app.string.nav_history'), keywords: `${history.method} ${history.url} history 历史`, icon: '◷' });
    });
    this.environments.forEach((environment: EnvironmentModel) => {
      items.push({ id: `environment:${environment.id}`, title: environment.name,
        subtitle: $r('app.string.nav_environments'),
        keywords: `${environment.name} ${environment.id} environment 环境`, icon: '◎' });
    });
    return items;
  }

  private containsCollectionNode(nodes: CollectionNode[], id: string): boolean {
    return nodes.some((node: CollectionNode) => node.id === id || this.containsCollectionNode(node.children, id));
  }

  private revealCollectionNode(nodes: CollectionNode[], id: string): CollectionNode[] {
    return nodes.map((node: CollectionNode): CollectionNode => ({
      id: node.id,
      type: node.type,
      name: node.name,
      method: node.method,
      expanded: node.id === id || this.containsCollectionNode(node.children, id) ? true : node.expanded,
      variables: node.variables ?? [],
      children: this.revealCollectionNode(node.children, id)
    }));
  }

  private selectSearchItem(item: GlobalSearchItem): void {
    this.activeOverlay = '';
    if (item.id === 'command:new') {
      this.createTab();
      return;
    }
    if (item.id === 'command:import') {
      this.showOverlay('import');
      return;
    }
    if (item.id === 'command:settings') {
      this.selectDestination('settings');
      return;
    }
    if (item.id === 'command:help') {
      this.selectDestination('help');
      return;
    }
    if (item.id === 'command:environments') {
      this.selectDestination('environments');
      return;
    }
    if (item.id.startsWith('environment:')) {
      this.selectedEnvironmentId = item.id.substring('environment:'.length);
      this.selectDestination('environments');
      this.persistLocalData();
      return;
    }
    if (item.id.startsWith('history:')) {
      const id = item.id.substring('history:'.length);
      const history = this.historyItems.find((candidate: HistoryItemModel) => candidate.id === id);
      if (history) this.openHistoryItem(history);
      return;
    }
    if (item.id.startsWith('request:')) {
      const id = item.id.substring('request:'.length);
      const node = this.findCollectionNode(this.collections, id);
      if (node) {
        this.openCollectionRequest(node);
      } else {
        const saved = this.savedRequests.find((candidate: PersistedRequestModel) => candidate.id === id);
        if (saved) {
          this.openCollectionRequest({ id: saved.id, type: 'request', name: saved.name,
            method: saved.method, expanded: false, variables: [], children: [] });
        }
      }
      this.selectDestination('workspace');
      return;
    }
    if (item.id.startsWith('collection:')) {
      const id = item.id.substring('collection:'.length);
      this.collections = this.revealCollectionNode(this.collections, id);
      this.selectDestination('collections');
      this.persistLocalData();
    }
  }

  private findCollectionNode(nodes: CollectionNode[], id: string): CollectionNode | undefined {
    for (let index = 0; index < nodes.length; index += 1) {
      if (nodes[index].id === id) return nodes[index];
      const nested = this.findCollectionNode(nodes[index].children, id);
      if (nested) return nested;
    }
    return undefined;
  }

  private collectionNodePath(nodes: CollectionNode[], id: string,
    ancestors: CollectionNode[] = []): CollectionNode[] | undefined {
    for (let index = 0; index < nodes.length; index += 1) {
      const path = [...ancestors, nodes[index]];
      if (nodes[index].id === id) return path;
      const nested = this.collectionNodePath(nodes[index].children, id, path);
      if (nested) return nested;
    }
    return undefined;
  }

  private variableResolutions(requestId: string, environment: EnvironmentModel,
    runtimeValues: Record<string, string> | undefined = undefined): EffectiveVariableModel[] {
    let resolved: EffectiveVariableModel[] = [];
    const applyLayer = (variables: KeyValueItem[], source: VariableSourceModel): void => {
      variables.forEach((item: KeyValueItem) => {
        const key = item.key.trim();
        if (!item.enabled || key.length === 0) return;
        const index = resolved.findIndex((candidate: EffectiveVariableModel) => candidate.key === key);
        const previous = index >= 0 ? resolved[index] : undefined;
        const next: EffectiveVariableModel = {
          key, value: item.value, secret: item.secret, source,
          overriddenSources: previous ? [previous.source, ...previous.overriddenSources] : []
        };
        if (index >= 0) {
          resolved = resolved.map((candidate: EffectiveVariableModel, itemIndex: number) =>
            itemIndex === index ? next : candidate);
        } else {
          resolved = [...resolved, next];
        }
      });
    };
    applyLayer(environment.variables, {
      kind: 'environment', id: environment.id, name: environment.name
    });
    const path = this.collectionNodePath(this.collections, requestId) ?? [];
    path.forEach((node: CollectionNode) => {
      if (node.type === 'request') return;
      applyLayer(node.variables ?? [], {
        kind: node.type === 'collection' ? 'collection' : 'folder', id: node.id, name: node.name
      });
    });
    if (runtimeValues !== undefined) {
      const variables: KeyValueItem[] = Object.keys(runtimeValues).map(
        (key: string, index: number): KeyValueItem => ({
          id: `runner-data-${index}`, enabled: true, key, value: runtimeValues[key], description: '',
          type: 'text', secret: false
        }));
      applyLayer(variables, { kind: 'runner', id: 'runner-data', name: 'Runner data' });
    }
    return resolved;
  }

  private scopedEnvironment(requestId: string, environment: EnvironmentModel,
    runtimeValues: Record<string, string> | undefined = undefined): EnvironmentModel {
    const variables = this.variableResolutions(requestId, environment, runtimeValues).map(
      (item: EffectiveVariableModel, index: number): KeyValueItem => ({
        id: `effective-${index}`, enabled: true, key: item.key, value: item.value,
        description: item.source.name, type: 'text', secret: item.secret
      }));
    return {
      id: environment.id, name: environment.name, kind: environment.kind,
      variables, system: environment.system
    };
  }

  private activeScopedVariables(): KeyValueItem[] {
    return this.scopedEnvironment(this.activeTabId, this.activeEnvironment()).variables;
  }

  private activeVariableResolutions(): EffectiveVariableModel[] {
    return this.variableResolutions(this.activeTabId, this.activeEnvironment());
  }

  private appendVariableNames(value: string, names: string[]): void {
    const pattern = /\{\{\s*([^{}]+?)\s*\}\}/g;
    let match = pattern.exec(value);
    while (match !== null) {
      const name = match[1].trim();
      if (name.length > 0 && !names.includes(name)) names.push(name);
      match = pattern.exec(value);
    }
  }

  private requestVariableNames(request: RequestDraft): string[] {
    const names: string[] = [];
    this.appendVariableNames(request.url, names);
    request.params.forEach((item: KeyValueItem) => {
      if (item.enabled) {
        this.appendVariableNames(item.key, names);
        this.appendVariableNames(item.value, names);
      }
    });
    request.headers.forEach((item: KeyValueItem) => {
      if (item.enabled) {
        this.appendVariableNames(item.key, names);
        this.appendVariableNames(item.value, names);
      }
    });
    if (request.auth.type === 'bearer') this.appendVariableNames(request.auth.bearerToken, names);
    if (request.auth.type === 'basic') {
      this.appendVariableNames(request.auth.username, names);
      this.appendVariableNames(request.auth.password, names);
    }
    if (request.auth.type === 'apiKey') {
      this.appendVariableNames(request.auth.apiKey, names);
      this.appendVariableNames(request.auth.apiValue, names);
    }
    if (request.bodyType === 'json' || request.bodyType === 'text') {
      this.appendVariableNames(request.bodyText, names);
    } else if (request.bodyType === 'form') {
      request.formItems.forEach((item: KeyValueItem) => {
        if (item.enabled) {
          this.appendVariableNames(item.key, names);
          this.appendVariableNames(item.value, names);
        }
      });
    } else if (request.bodyType === 'multipart') {
      request.multipartItems.forEach((item: KeyValueItem) => {
        if (!item.enabled) return;
        this.appendVariableNames(item.key, names);
        if (item.type !== 'file') this.appendVariableNames(item.value, names);
      });
    }
    return names;
  }

  private activeMissingVariables(): string[] {
    const tab = this.tabs.find((item: RequestTabModel) => item.id === this.activeTabId);
    if (!tab) return [];
    const names = this.requestVariableNames(tab.request);
    if (tab.request.protocol === 'websocket') {
      const session = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === tab.id);
      if (session) this.appendVariableNames(session.composer, names);
    }
    const available = new Set<string>();
    this.activeVariableResolutions().forEach((item: EffectiveVariableModel) => {
      if (item.value.length > 0) available.add(item.key);
    });
    return names.filter((name: string) => !available.has(name));
  }

  private editVariableSource(kind: VariableSourceKind, id: string): void {
    if (kind === 'environment') {
      if (id.length > 0) this.selectedEnvironmentId = id;
      this.selectDestination('environments');
      this.persistLocalData();
      return;
    }
    if (kind === 'collection' || kind === 'folder') {
      const node = this.findCollectionNode(this.collections, id);
      if (node) this.beginEditCollectionVariables(node);
    }
  }

  private configureMissingVariables(requestId: string): void {
    const path = this.collectionNodePath(this.collections, requestId) ?? [];
    for (let index = path.length - 1; index >= 0; index -= 1) {
      if (path[index].type !== 'request') {
        this.beginEditCollectionVariables(path[index]);
        return;
      }
    }
    this.selectDestination('environments');
  }

  private updateCollectionNode(nodes: CollectionNode[], id: string,
    change: (node: CollectionNode) => CollectionNode): CollectionNode[] {
    let changed = false;
    const updated = nodes.map((node: CollectionNode) => {
      if (node.id === id) {
        changed = true;
        return change(node);
      }
      const children = this.updateCollectionNode(node.children, id, change);
      if (children === node.children) return node;
      changed = true;
      return { id: node.id, type: node.type, name: node.name, method: node.method,
        expanded: node.expanded, variables: node.variables ?? [], children };
    });
    return changed ? updated : nodes;
  }

  private toggleCollectionNode(id: string): void {
    this.animateState(() => {
      this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
        id: node.id, type: node.type, name: node.name, method: node.method,
        expanded: !node.expanded, variables: node.variables ?? [], children: node.children
      }));
    });
    this.persistLocalData();
  }

  private newCollectionNodeId(prefix: string): string {
    const id = `${prefix}-${Date.now()}-${this.nextCollectionNodeNumber}`;
    this.nextCollectionNodeNumber += 1;
    return id;
  }

  private beginCreateCollection(forPendingSave: boolean = false): void {
    if (!forPendingSave) this.pendingSaveTabId = '';
    this.collectionParentId = '';
    this.showOverlay('create-collection');
  }

  private beginCreateFolder(parentId: string): void {
    this.pendingSaveTabId = '';
    this.collectionParentId = parentId;
    this.showOverlay('create-folder');
  }

  private createCollection(name: string): void {
    const collection: CollectionNode = {
      id: this.newCollectionNodeId('collection'), type: 'collection', name,
      expanded: true, variables: [], children: []
    };
    this.collections = [...this.collections, collection];
    this.persistLocalData();
    if (this.pendingSaveTabId.length > 0) {
      this.activeOverlay = 'save-request';
    } else {
      this.hideOverlay();
      this.showToast($r('app.string.toast_collection_created'));
    }
  }

  private createFolder(name: string): void {
    const parentId = this.collectionParentId;
    const folder: CollectionNode = {
      id: this.newCollectionNodeId('folder'), type: 'folder', name, expanded: true, variables: [], children: []
    };
    this.collections = this.updateCollectionNode(this.collections, parentId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, variables: node.variables ?? [], children: [...node.children, folder]
    }));
    this.collectionParentId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_folder_created'));
  }

  private createRequestInCollection(parentId: string, protocol: RequestProtocol = 'http'): void {
    const number = this.nextTabNumber;
    const id = `untitled-${number}`;
    let name = this.preferences.language === 'zh' ? `未命名请求 ${number}` : `Untitled Request ${number}`;
    if (protocol === 'websocket') {
      name = this.preferences.language === 'zh' ? `未命名 WebSocket ${number}` : `Untitled WebSocket ${number}`;
    } else if (protocol === 'sse') {
      name = this.preferences.language === 'zh' ? `未命名 SSE ${number}` : `Untitled SSE ${number}`;
    }
    const request = this.createRequest();
    request.protocol = protocol;
    if (protocol === 'websocket') request.url = 'wss://';
    if (protocol === 'sse') request.url = 'https://';
    const requestNode: CollectionNode = {
      id, type: 'request', name,
      method: protocol === 'websocket' ? 'WS' : (protocol === 'sse' ? 'SSE' : 'GET'),
      expanded: false, variables: [], children: []
    };
    this.collections = this.updateCollectionNode(this.collections, parentId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, variables: node.variables ?? [], children: [...node.children, requestNode]
    }));
    this.tabs = [...this.tabs, {
      id, name, method: 'GET', dirty: false, pinned: false, loading: false,
      request, response: createEmptyResponse()
    }];
    if (protocol === 'websocket') {
      this.webSocketSessions = [...this.webSocketSessions, this.emptyWebSocketSession(id)];
    } else if (protocol === 'sse') {
      this.sseSessions = [...this.sseSessions, this.emptySseSession(id)];
    }
    this.nextTabNumber += 1;
    this.activeTabId = id;
    this.rememberRequest(id, name, request);
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.persistLocalData();
  }

  private beginRenameFolder(node: CollectionNode): void {
    this.renamingFolderId = node.id;
    this.showOverlay('rename-folder');
  }

  private beginEditCollectionVariables(node: CollectionNode): void {
    this.editingCollectionVariablesId = node.id;
    this.editingCollectionVariablesName = node.name;
    this.editingCollectionVariables = node.variables ?? [];
    this.showOverlay('collection-variables');
  }

  private saveCollectionVariables(variables: KeyValueItem[]): void {
    const id = this.editingCollectionVariablesId;
    if (id.length === 0) return;
    this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: node.expanded, variables, children: node.children
    }));
    this.editingCollectionVariablesId = '';
    this.editingCollectionVariablesName = '';
    this.editingCollectionVariables = [];
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_collection_variables_saved'));
  }

  private renameFolder(name: string): void {
    const id = this.renamingFolderId;
    if (id.length === 0) return;
    this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
      id: node.id, type: node.type, name, method: node.method,
      expanded: node.expanded, variables: node.variables ?? [], children: node.children
    }));
    this.renamingFolderId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_folder_renamed'));
  }

  private beginRenameRequest(node: CollectionNode): void {
    this.renamingRequestId = node.id;
    this.showOverlay('rename-request');
  }

  private renameRequest(name: string): void {
    const id = this.renamingRequestId;
    if (id.length === 0) return;
    this.applyRequestName(id, name);
    this.renamingRequestId = '';
    this.hideOverlay();
  }

  private applyRequestName(id: string, value: string): void {
    const name = value.trim();
    if (id.length === 0 || name.length === 0) return;
    this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
      id: node.id, type: node.type, name, method: node.method,
      expanded: node.expanded, variables: node.variables ?? [], children: node.children
    }));
    this.savedRequests = this.savedRequests.map((item: PersistedRequestModel) => item.id === id ? {
      id: item.id, name, method: item.method, request: item.request
    } : item);
    this.tabs = this.tabs.map((tab: RequestTabModel) => tab.id === id ? {
      id: tab.id, name, method: tab.method, dirty: tab.dirty,
      pinned: tab.pinned, loading: tab.loading, request: tab.request, response: tab.response
    } : tab);
    this.persistLocalData();
    this.showToast($r('app.string.toast_saved'));
  }

  private insertAfterCollectionNode(nodes: CollectionNode[], targetId: string,
    inserted: CollectionNode): CollectionNode[] {
    const updated: CollectionNode[] = [];
    let changed = false;
    nodes.forEach((node: CollectionNode) => {
      updated.push(node);
      if (node.id === targetId) {
        updated.push(inserted);
        changed = true;
        return;
      }
      const children = this.insertAfterCollectionNode(node.children, targetId, inserted);
      if (children !== node.children) {
        updated[updated.length - 1] = {
          id: node.id, type: node.type, name: node.name, method: node.method,
          expanded: node.expanded, variables: node.variables ?? [], children
        };
        changed = true;
      }
    });
    return changed ? updated : nodes;
  }

  private collectionNodeMethod(method: string): HttpMethod {
    if (method === 'POST') return 'POST';
    if (method === 'PUT') return 'PUT';
    if (method === 'PATCH') return 'PATCH';
    if (method === 'DELETE') return 'DELETE';
    if (method === 'HEAD') return 'HEAD';
    if (method === 'OPTIONS') return 'OPTIONS';
    return 'GET';
  }

  private duplicateCollectionRequest(node: CollectionNode): void {
    const sourceTab = this.tabs.find((tab: RequestTabModel) => tab.id === node.id);
    const sourceSaved = this.savedRequests.find((item: PersistedRequestModel) => item.id === node.id);
    const method = this.collectionNodeMethod(node.method ?? 'GET');
    const request = sourceTab ? this.idleRequest(sourceTab.request) :
      (sourceSaved ? this.idleRequest(sourceSaved.request) : this.createRequest(method));
    const id = this.newCollectionNodeId('request');
    const name = this.preferences.language === 'zh' ? `${node.name} 副本` : `${node.name} Copy`;
    const duplicated: CollectionNode = {
      id, type: 'request', name,
      method: request.protocol === 'websocket' ? 'WS' : (request.protocol === 'sse' ? 'SSE' : request.method),
      expanded: false, variables: [], children: []
    };
    this.collections = this.insertAfterCollectionNode(this.collections, node.id, duplicated);
    this.tabs = [...this.tabs, {
      id, name, method: request.method, dirty: false, pinned: false, loading: false,
      request, response: createEmptyResponse()
    }];
    if (request.protocol === 'websocket') {
      this.webSocketSessions = [...this.webSocketSessions, this.emptyWebSocketSession(id)];
    } else if (request.protocol === 'sse') {
      this.sseSessions = [...this.sseSessions, this.emptySseSession(id)];
    }
    this.activeTabId = id;
    this.rememberRequest(id, name, request);
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.persistLocalData();
    this.showToast($r('app.string.toast_request_duplicated'));
  }

  private collectCollectionRequestIds(node: CollectionNode, ids: string[]): void {
    if (node.type === 'request') {
      ids.push(node.id);
      return;
    }
    node.children.forEach((child: CollectionNode) => this.collectCollectionRequestIds(child, ids));
  }

  private removeCollectionNode(nodes: CollectionNode[], id: string): CollectionNode[] {
    const kept: CollectionNode[] = [];
    let changed = false;
    nodes.forEach((node: CollectionNode) => {
      if (node.id === id) {
        changed = true;
        return;
      }
      const children = this.removeCollectionNode(node.children, id);
      if (children !== node.children) {
        kept.push({ id: node.id, type: node.type, name: node.name, method: node.method,
          expanded: node.expanded, variables: node.variables ?? [], children });
        changed = true;
      } else {
        kept.push(node);
      }
    });
    return changed ? kept : nodes;
  }

  private beginDeleteCollectionNode(node: CollectionNode): void {
    this.deletingCollectionNodeId = node.id;
    this.showOverlay('delete-collection-node');
  }

  private deleteCollectionNode(): void {
    const node = this.findCollectionNode(this.collections, this.deletingCollectionNodeId);
    if (!node) return;
    const requestIds: string[] = [];
    this.collectCollectionRequestIds(node, requestIds);
    requestIds.forEach((id: string) => {
      this.requestSerials.set(id, (this.requestSerials.get(id) ?? 0) + 1);
      this.requestController.cancel(id);
      this.webSocketController.disconnect(id, false);
      this.sseController.stop(id);
    });
    const activeIndex = this.tabs.findIndex((tab: RequestTabModel) => tab.id === this.activeTabId);
    this.collections = this.removeCollectionNode(this.collections, node.id);
    this.savedRequests = this.savedRequests.filter((item: PersistedRequestModel) =>
      !requestIds.includes(item.id));
    this.tabs = this.tabs.filter((tab: RequestTabModel) => !requestIds.includes(tab.id));
    this.webSocketSessions = this.webSocketSessions.filter((item: WebSocketSessionModel) =>
      !requestIds.includes(item.requestId));
    this.sseSessions = this.sseSessions.filter((item: SseSessionModel) => !requestIds.includes(item.requestId));
    if (!this.tabs.some((tab: RequestTabModel) => tab.id === this.activeTabId)) {
      const nextIndex = Math.min(Math.max(activeIndex, 0), this.tabs.length - 1);
      this.activeTabId = nextIndex >= 0 ? this.tabs[nextIndex].id : '';
    }
    this.deletingCollectionNodeId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_deleted'));
  }

  private appendCollectionTargets(nodes: CollectionNode[], depth: number,
    targets: CollectionTarget[]): void {
    nodes.forEach((node: CollectionNode) => {
      if (node.type === 'request') return;
      targets.push({ id: node.id, name: node.name, depth });
      this.appendCollectionTargets(node.children, depth + 1, targets);
    });
  }

  private collectionTargets(): CollectionTarget[] {
    const targets: CollectionTarget[] = [];
    this.appendCollectionTargets(this.collections, 0, targets);
    return targets;
  }

  private pendingSaveName(): string {
    const tab = this.tabs.find((item: RequestTabModel) => item.id === this.pendingSaveTabId);
    return tab ? tab.name : '';
  }

  private requestIsCollected(id: string, nodes: CollectionNode[] = this.collections): boolean {
    return nodes.some((node: CollectionNode) => node.type === 'request' ? node.id === id :
      this.requestIsCollected(id, node.children));
  }

  private beginSaveRequest(id: string): void {
    const tab = this.tabs.find((item: RequestTabModel) => item.id === id);
    if (!tab) return;
    if (this.requestIsCollected(id)) {
      this.rememberRequest(tab.id, tab.name, tab.request);
      this.tabs = this.tabs.map((item: RequestTabModel) => item.id === id ? {
        id: item.id, name: item.name, method: item.method, dirty: false,
        pinned: item.pinned, loading: item.loading, request: item.request, response: item.response
      } : item);
      this.persistLocalData();
      this.showToast($r('app.string.toast_saved'));
      return;
    }
    this.pendingSaveTabId = id;
    if (this.collectionTargets().length === 0) {
      this.beginCreateCollection(true);
    } else {
      this.showOverlay('save-request');
    }
  }

  private saveRequestToCollection(name: string, targetId: string): void {
    const id = this.pendingSaveTabId;
    const tab = this.tabs.find((item: RequestTabModel) => item.id === id);
    if (!tab) return;
    const requestNode: CollectionNode = {
      id, type: 'request', name,
      method: tab.request.protocol === 'websocket' ? 'WS' :
        (tab.request.protocol === 'sse' ? 'SSE' : tab.request.method),
      expanded: false, variables: [], children: []
    };
    this.collections = this.updateCollectionNode(this.collections, targetId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, variables: node.variables ?? [], children: [...node.children, requestNode]
    }));
    this.tabs = this.tabs.map((item: RequestTabModel) => item.id === id ? {
      id: item.id, name, method: item.request.method, dirty: false,
      pinned: item.pinned, loading: item.loading, request: item.request, response: item.response
    } : item);
    this.rememberRequest(id, name, tab.request);
    this.pendingSaveTabId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_request_saved_collection'));
  }

  private hideOverlay(): void {
    this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
      this.activeOverlay = '';
    });
  }

  private selectDestination(destination: NavigationDestination): void {
    this.animateState(() => {
      if (destination === 'collections' && this.isPhone()) {
        if (this.activeDestination === 'collections') {
          this.collectionDrawerOpen = !this.collectionDrawerOpen;
        } else {
          this.activeDestination = destination;
          this.collectionDrawerOpen = true;
        }
      } else {
        this.collectionDrawerOpen = false;
        this.activeDestination = destination;
      }
    }, MotionTokens.slow);
  }

  private requestContentChanged(previous: RequestDraft, next: RequestDraft): boolean {
    return previous.method !== next.method || previous.url !== next.url ||
      previous.params !== next.params || previous.headers !== next.headers || previous.auth !== next.auth ||
      previous.bodyType !== next.bodyType || previous.bodyText !== next.bodyText ||
      previous.formItems !== next.formItems || previous.multipartItems !== next.multipartItems ||
      previous.binaryFileName !== next.binaryFileName || previous.preRequestScript !== next.preRequestScript ||
      previous.postResponseScript !== next.postResponseScript ||
      previous.extractionRules !== next.extractionRules ||
      previous.testRules !== next.testRules ||
      previous.settings !== next.settings;
  }

  private responseWithStatus(response: ResponseModel, status: ResponseStatus): ResponseModel {
    return {
      status,
      statusCode: response.statusCode,
      statusText: response.statusText,
      headers: response.headers,
      cookies: response.cookies,
      body: response.body,
      binaryBody: response.binaryBody,
      mediaKind: response.mediaKind,
      mediaUri: response.mediaUri,
      contentType: response.contentType,
      size: response.size,
      duration: response.duration,
      timing: response.timing,
      protocol: response.protocol,
      error: response.error,
      previewAvailable: response.previewAvailable,
      scriptResults: response.scriptResults,
      extractionResults: response.extractionResults,
      testResults: response.testResults
    };
  }

  private requestWithLifecycle(request: RequestDraft, lifecycle: 'idle' | 'sending'): RequestDraft {
    return {
      protocol: request.protocol,
      method: request.method,
      url: request.url,
      lifecycle,
      activeConfigTab: request.activeConfigTab,
      params: request.params,
      headers: request.headers,
      auth: request.auth,
      bodyType: request.bodyType,
      bodyText: request.bodyText,
      formItems: request.formItems,
      multipartItems: request.multipartItems,
      binaryFileName: request.binaryFileName,
      preRequestScript: request.preRequestScript,
      postResponseScript: request.postResponseScript,
      extractionRules: request.extractionRules,
      testRules: request.testRules,
      settings: request.settings
    };
  }

  private applyRealResponse(id: string, response: ResponseModel,
    executedRequest: RequestDraft | undefined = undefined): void {
    let completedRequest: RequestTabModel | undefined = undefined;
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id || tab.request.lifecycle !== 'sending') return tab;
      const completed: RequestTabModel = {
        id: tab.id,
        name: tab.name,
        method: tab.method,
        dirty: tab.dirty,
        pinned: tab.pinned,
        loading: false,
        request: this.requestWithLifecycle(tab.request, 'idle'),
        response
      };
      completedRequest = completed;
      return completed;
    });
    if (completedRequest && response.status !== 'cancelled' && this.preferences.saveHistory) {
      const completed = completedRequest as RequestTabModel;
      const historyRequest = executedRequest ?? completed.request;
      const now = new Date();
      const hours = now.getHours().toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      this.historyItems = [{
        id: `history-${Date.now()}`,
        group: 'Today',
        createdAt: Date.now(),
        time: `${hours}:${minutes}`,
        method: historyRequest.method,
        url: historyRequest.url,
        status: response.statusCode,
        duration: response.duration.length > 0 ? response.duration : '—'
      }, ...this.historyItems];
    }
    this.persistLocalData();
  }

  private extractionResult(rule: ExtractionRule, status: ExtractionStatus,
    value: string, message: string): ExtractionResult {
    return { ruleId: rule.id, status, value, message };
  }

  private applyResponseExtractions(request: RequestDraft, response: ResponseModel): ResponseModel {
    const enabled = request.extractionRules.filter((rule: ExtractionRule) => rule.enabled);
    if (enabled.length === 0) return response;
    const results: ExtractionResult[] = [];
    if ((response.status !== 'success' && response.status !== 'large') ||
      response.statusCode < 200 || response.statusCode >= 400) {
      enabled.forEach((rule: ExtractionRule) => results.push(this.extractionResult(rule, 'notRun', '',
        'Extraction only runs for successful JSON responses')));
      return this.responseWithExtractionResults(response, results);
    }
    let environments = this.environments;
    enabled.forEach((rule: ExtractionRule) => {
      const variableName = rule.variableName.trim();
      if (variableName.length === 0) {
        results.push(this.extractionResult(rule, 'conflict', '', 'Variable name is required'));
        return;
      }
      const environmentIndex = environments.findIndex((environment: EnvironmentModel) =>
        environment.id === rule.environmentId);
      if (environmentIndex < 0) {
        results.push(this.extractionResult(rule, 'targetMissing', '', 'Target environment no longer exists'));
        return;
      }
      const evaluated: JsonPathResult = JsonPathService.evaluate(response.body, rule.jsonPath);
      if (!evaluated.success) {
        results.push(this.extractionResult(rule, evaluated.status, '', evaluated.message));
        return;
      }
      const environment = environments[environmentIndex];
      const variableIndex = environment.variables.findIndex((variable: KeyValueItem) =>
        variable.key === variableName);
      let variables = environment.variables;
      if (variableIndex >= 0 && !rule.overwrite) {
        results.push(this.extractionResult(rule, 'conflict', evaluated.value,
          'Variable already exists; enable overwrite to replace it'));
        return;
      }
      if (variableIndex >= 0) {
        variables = variables.map((variable: KeyValueItem, index: number) => index === variableIndex ? {
          id: variable.id, enabled: true, key: variableName, value: evaluated.value,
          description: variable.description, type: 'text', secret: rule.secret
        } : variable);
      } else {
        variables = [...variables, {
          id: `extracted-${Date.now()}-${results.length}`, enabled: true, key: variableName,
          value: evaluated.value, description: '', type: 'text', secret: rule.secret
        }];
      }
      environments = environments.map((item: EnvironmentModel, index: number) => index === environmentIndex ? {
        id: item.id, name: item.name, kind: item.kind, variables, system: item.system
      } : item);
      results.push(this.extractionResult(rule, 'success', evaluated.value, 'Variable saved'));
    });
    this.environments = environments;
    return this.responseWithExtractionResults(response, results);
  }

  private responseWithExtractionResults(response: ResponseModel, results: ExtractionResult[]): ResponseModel {
    return {
      status: response.status, statusCode: response.statusCode, statusText: response.statusText,
      headers: response.headers, cookies: response.cookies, body: response.body,
      binaryBody: response.binaryBody, mediaKind: response.mediaKind, mediaUri: response.mediaUri,
      contentType: response.contentType, size: response.size, duration: response.duration,
      timing: response.timing, protocol: response.protocol, error: response.error,
      previewAvailable: response.previewAvailable,
      scriptResults: response.scriptResults, extractionResults: results, testResults: response.testResults
    };
  }

  private applyResponseTests(request: RequestDraft, response: ResponseModel): ResponseModel {
    const results: TestResult[] = ResponseTestService.run(request.testRules, response);
    return {
      status: response.status, statusCode: response.statusCode, statusText: response.statusText,
      headers: response.headers, cookies: response.cookies, body: response.body,
      binaryBody: response.binaryBody, mediaKind: response.mediaKind, mediaUri: response.mediaUri,
      contentType: response.contentType, size: response.size, duration: response.duration,
      timing: response.timing, protocol: response.protocol, error: response.error,
      previewAvailable: response.previewAvailable,
      scriptResults: response.scriptResults, extractionResults: response.extractionResults, testResults: results
    };
  }

  private activeEnvironment(): EnvironmentModel {
    return this.environmentForId(this.selectedEnvironmentId);
  }

  private scriptRequestSnapshot(request: RequestDraft): ScriptRequestSnapshot {
    const headers: Record<string, string> = {};
    request.headers.forEach((item: KeyValueItem) => {
      if (item.enabled && item.key.trim().length > 0) headers[item.key] = item.value;
    });
    return {
      method: request.method,
      url: request.url,
      bodyType: request.bodyType,
      body: request.bodyText,
      headers
    };
  }

  private scriptEnvironmentSnapshot(environment: EnvironmentModel): ScriptEnvironmentSnapshot {
    const values: Record<string, string> = {};
    environment.variables.forEach((item: KeyValueItem) => {
      if (item.enabled && item.key.trim().length > 0) values[item.key] = item.value;
    });
    return { available: environment.id.length > 0, values };
  }

  private scriptResponseSnapshot(response: ResponseModel): ScriptResponseSnapshot {
    const headers: Record<string, string> = {};
    response.headers.forEach((item: KeyValueItem) => {
      if (item.key.trim().length > 0) headers[item.key] = item.value;
    });
    return {
      statusCode: response.statusCode,
      statusText: response.statusText,
      body: response.body,
      headers,
      contentType: response.contentType,
      size: response.size,
      duration: response.duration,
      protocol: response.protocol
    };
  }

  private scriptBodyType(value: string, fallback: BodyType): BodyType {
    if (value === 'none' || value === 'json' || value === 'text' || value === 'form' ||
      value === 'multipart' || value === 'binary') return value;
    return fallback;
  }

  private requestWithScriptChanges(request: RequestDraft, snapshot: ScriptRequestSnapshot): RequestDraft {
    const headers: KeyValueItem[] = Object.keys(snapshot.headers).map((key: string, index: number): KeyValueItem => {
      const previous = request.headers.find((item: KeyValueItem) => item.key.toLowerCase() === key.toLowerCase());
      return {
        id: previous?.id ?? `script-header-${Date.now()}-${index}`,
        enabled: true,
        key,
        value: snapshot.headers[key],
        description: previous?.description ?? '',
        type: 'text',
        secret: previous?.secret ?? false
      };
    });
    return {
      protocol: request.protocol,
      method: this.collectionNodeMethod(snapshot.method),
      url: snapshot.url,
      lifecycle: request.lifecycle,
      activeConfigTab: request.activeConfigTab,
      params: request.params,
      headers,
      auth: request.auth,
      bodyType: this.scriptBodyType(snapshot.bodyType, request.bodyType),
      bodyText: snapshot.body,
      formItems: request.formItems,
      multipartItems: request.multipartItems,
      binaryFileName: request.binaryFileName,
      preRequestScript: request.preRequestScript,
      postResponseScript: request.postResponseScript,
      extractionRules: request.extractionRules,
      testRules: request.testRules,
      settings: request.settings
    };
  }

  private applyScriptEnvironmentWrites(environment: EnvironmentModel,
    writes: Record<string, string>): EnvironmentModel {
    if (environment.id.length === 0 || Object.keys(writes).length === 0) return environment;
    let variables = environment.variables;
    Object.keys(writes).forEach((name: string, index: number) => {
      const variableIndex = variables.findIndex((item: KeyValueItem) => item.key === name);
      if (variableIndex >= 0) {
        variables = variables.map((item: KeyValueItem, itemIndex: number) => itemIndex === variableIndex ? {
          id: item.id, enabled: true, key: item.key, value: writes[name], description: item.description,
          type: 'text', secret: item.secret
        } : item);
      } else {
        variables = [...variables, {
          id: `script-variable-${Date.now()}-${index}`, enabled: true, key: name, value: writes[name],
          description: '', type: 'text', secret: false
        }];
      }
    });
    const updated: EnvironmentModel = {
      id: environment.id, name: environment.name, kind: environment.kind, variables, system: environment.system
    };
    this.environments = this.environments.map((item: EnvironmentModel) => item.id === updated.id ? updated : item);
    return updated;
  }

  private scriptExecution(result: ScriptResult,
    phase: 'preRequest' | 'postResponse' = 'preRequest'): ScriptExecutionResult {
    return {
      phase, status: result.status, error: result.error,
      durationMs: result.durationMs, logs: result.logs
    };
  }

  private responseWithScriptResults(response: ResponseModel,
    scriptResults: ScriptExecutionResult[]): ResponseModel {
    return {
      status: response.status, statusCode: response.statusCode, statusText: response.statusText,
      headers: response.headers, cookies: response.cookies, body: response.body,
      binaryBody: response.binaryBody, mediaKind: response.mediaKind, mediaUri: response.mediaUri,
      contentType: response.contentType, size: response.size, duration: response.duration,
      timing: response.timing, protocol: response.protocol, error: response.error,
      previewAvailable: response.previewAvailable,
      scriptResults, extractionResults: response.extractionResults, testResults: response.testResults
    };
  }

  private scriptFailureResponse(result: ScriptResult, request: RequestDraft): ResponseModel {
    const response = createEmptyResponse();
    response.status = 'error';
    response.error = {
      type: 'script',
      title: this.preferences.language === 'zh' ? '前置脚本执行失败' : 'Pre-request script failed',
      message: result.status === 'timeout' ?
        (this.preferences.language === 'zh' ? '脚本执行超时，请检查循环或减少计算量。' :
          'The script timed out. Check loops or reduce its work.') :
        (this.preferences.language === 'zh' ? '请求未发送，脚本修改未应用。' :
          'The request was not sent and script changes were not applied.'),
      code: result.status,
      details: result.error,
      stage: 'script',
      method: request.method,
      host: this.diagnosticHost(request.url),
      durationMs: result.durationMs,
      timeoutMs: request.settings.timeoutMs,
      sslVerification: request.settings.sslVerification,
      followRedirects: request.settings.followRedirects
    };
    return this.responseWithScriptResults(response, [this.scriptExecution(result)]);
  }

  private environmentForId(id: string): EnvironmentModel {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === id);
    if (environment) return environment;
    return { id: '', name: 'No Environment', kind: 'development', variables: [] };
  }

  private async executeRequestPipeline(executionId: string, request: RequestDraft, environmentId: string,
    isActive: () => boolean,
    runtimeValues: Record<string, string> | undefined = undefined,
    scopeRequestId: string = executionId): Promise<RequestPipelineResult | undefined> {
    let executedRequest = request;
    let environment = this.environmentForId(environmentId);
    let effectiveEnvironment = this.scopedEnvironment(scopeRequestId, environment, runtimeValues);
    const scriptResults: ScriptExecutionResult[] = [];
    if (request.preRequestScript.enabled && request.preRequestScript.source.trim().length > 0) {
      const execution: PreRequestExecution = await ScriptRuntimeService.runPreRequest(
        request.preRequestScript.source, this.scriptRequestSnapshot(request),
        this.scriptEnvironmentSnapshot(effectiveEnvironment));
      if (!isActive()) return undefined;
      scriptResults.push(this.scriptExecution(execution.result));
      if (execution.result.status !== 'success') {
        let failure = this.scriptFailureResponse(execution.result, request);
        failure = this.applyResponseTests(request, failure);
        return { response: failure, executedRequest: request };
      }
      executedRequest = this.requestWithScriptChanges(request, execution.request);
      environment = this.applyScriptEnvironmentWrites(environment, execution.environmentWrites);
      effectiveEnvironment = this.scopedEnvironment(scopeRequestId, environment, runtimeValues);
      if (Object.keys(execution.environmentWrites).length > 0) this.persistLocalData();
    }
    let response = await this.requestController.send(executionId, executedRequest, effectiveEnvironment);
    if (!isActive()) return undefined;
    if (response.status === 'binary' && response.mediaKind !== 'none' && response.binaryBody.byteLength > 0) {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const mediaUri = await MediaPreviewStore.create(context.cacheDir, executionId,
          response.contentType, response.binaryBody);
        response = {
          status: 'success',
          statusCode: response.statusCode,
          statusText: response.statusText,
          headers: response.headers,
          cookies: response.cookies,
          body: response.body,
          binaryBody: response.binaryBody,
          mediaKind: response.mediaKind,
          mediaUri,
          contentType: response.contentType,
          size: response.size,
          duration: response.duration,
          timing: response.timing,
          protocol: response.protocol,
          error: response.error,
          previewAvailable: true,
          scriptResults: response.scriptResults,
          extractionResults: response.extractionResults,
          testResults: response.testResults
        };
      } catch (_error) {
        // Fall back to the existing binary download view if preview preparation fails.
      }
    }
    if (!isActive()) return undefined;
    if (request.postResponseScript.enabled && request.postResponseScript.source.trim().length > 0 &&
      response.status !== 'error' && response.status !== 'cancelled') {
      const execution: PostResponseExecution = await ScriptRuntimeService.runPostResponse(
        request.postResponseScript.source, this.scriptResponseSnapshot(response),
        this.scriptEnvironmentSnapshot(effectiveEnvironment));
      if (!isActive()) return undefined;
      scriptResults.push(this.scriptExecution(execution.result, 'postResponse'));
      if (execution.result.status === 'success') {
        environment = this.applyScriptEnvironmentWrites(environment, execution.environmentWrites);
        if (Object.keys(execution.environmentWrites).length > 0) this.persistLocalData();
      }
    }
    response = this.responseWithScriptResults(response, scriptResults);
    response = this.applyResponseExtractions(request, response);
    response = this.applyResponseTests(executedRequest, response);
    return { response, executedRequest };
  }

  private async sendRealRequest(id: string, request: RequestDraft, serial: number): Promise<void> {
    const result = await this.executeRequestPipeline(id, request, this.selectedEnvironmentId,
      (): boolean => this.requestSerials.get(id) === serial, undefined, id);
    if (result) this.applyRealResponse(id, result.response, result.executedRequest);
  }

  private updateRequest(id: string, request: RequestDraft): void {
    let shouldComplete = false;
    let requestSerial = 0;
    const collected = this.requestIsCollected(id);
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id) return tab;
      const started = tab.request.lifecycle !== 'sending' && request.lifecycle === 'sending';
      const cancelled = tab.request.lifecycle === 'sending' && request.lifecycle === 'idle';
      shouldComplete = started;
      if (started) {
        requestSerial = (this.requestSerials.get(id) ?? 0) + 1;
        this.requestSerials.set(id, requestSerial);
      }
      if (cancelled) {
        this.requestSerials.set(id, (this.requestSerials.get(id) ?? 0) + 1);
        this.requestController.cancel(id);
      }
      return {
        id: tab.id,
        name: tab.name,
        method: request.method,
        dirty: collected ? false : tab.dirty || this.requestContentChanged(tab.request, request),
        pinned: tab.pinned,
        loading: request.lifecycle === 'sending',
        request,
        response: started ? this.responseWithStatus(tab.response, 'sending') :
          (cancelled ? createCancelledResponse() : tab.response)
      };
    });
    const current = this.tabs.find((tab: RequestTabModel) => tab.id === id);
    if (current) this.rememberRequest(current.id, current.name, current.request);
    if (collected && current) {
      this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
        id: node.id, type: node.type, name: node.name,
        method: current.request.protocol === 'websocket' ? 'WS' :
          (current.request.protocol === 'sse' ? 'SSE' : current.request.method),
        expanded: node.expanded, variables: node.variables ?? [], children: node.children
      }));
    }
    if (shouldComplete) this.persistLocalData();
    else this.scheduleRequestPersistence();
    if (shouldComplete) {
      this.sendRealRequest(id, request, requestSerial);
    }
  }

  private previewLargeResponse(id: string): void {
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id) return tab;
      const response = tab.response;
      const preview: ResponseModel = {
        status: 'success',
        statusCode: response.statusCode,
        statusText: response.statusText,
        headers: response.headers,
        cookies: response.cookies,
        body: response.body.substring(0, 1024 * 1024),
        binaryBody: new ArrayBuffer(0),
        mediaKind: 'none',
        mediaUri: '',
        contentType: response.contentType,
        size: `${response.size} · 1.0 MB preview`,
        duration: response.duration,
        timing: response.timing,
        protocol: response.protocol,
        error: response.error,
        previewAvailable: false,
        scriptResults: response.scriptResults,
        extractionResults: response.extractionResults,
        testResults: response.testResults
      };
      return {
        id: tab.id,
        name: tab.name,
        method: tab.method,
        dirty: tab.dirty,
        pinned: tab.pinned,
        loading: tab.loading,
        request: tab.request,
        response: preview
      };
    });
  }

  private createTab(): void {
    const id = `untitled-${this.nextTabNumber}`;
    const request = this.createRequest();
    this.tabs = [...this.tabs, {
      id,
      name: `Untitled Request ${this.nextTabNumber}`,
      method: 'GET',
      dirty: true,
      pinned: false,
      loading: false,
      request,
      response: createEmptyResponse()
    }];
    this.nextTabNumber += 1;
    this.activeTabId = id;
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.rememberRequest(id, `Untitled Request ${this.nextTabNumber - 1}`, request);
    this.persistLocalData();
  }

  private emptyWebSocketSession(id: string): WebSocketSessionModel {
    return {
      requestId: id,
      status: 'disconnected',
      composer: '',
      messages: [],
      errorCode: '',
      errorMessage: ''
    };
  }

  private currentWebSocketSession(): WebSocketSessionModel {
    const session = this.webSocketSessions.find((item: WebSocketSessionModel) =>
      item.requestId === this.activeTabId);
    return session ?? this.emptyWebSocketSession(this.activeTabId);
  }

  private createWebSocketTab(): void {
    const id = `untitled-${this.nextTabNumber}`;
    const request = this.createRequest();
    request.protocol = 'websocket';
    request.url = 'wss://';
    const name = `Untitled WebSocket ${this.nextTabNumber}`;
    this.tabs = [...this.tabs, {
      id,
      name,
      method: 'GET',
      dirty: true,
      pinned: false,
      loading: false,
      request,
      response: createEmptyResponse()
    }];
    this.webSocketSessions = [...this.webSocketSessions, this.emptyWebSocketSession(id)];
    this.nextTabNumber += 1;
    this.activeTabId = id;
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.rememberRequest(id, name, request);
    this.persistLocalData();
  }

  private emptySseSession(id: string): SseSessionModel {
    return {
      requestId: id, status: 'disconnected', events: [], errorCode: '', errorMessage: '',
      statusCode: 0, contentType: ''
    };
  }

  private currentSseSession(): SseSessionModel {
    const session = this.sseSessions.find((item: SseSessionModel) => item.requestId === this.activeTabId);
    return session ?? this.emptySseSession(this.activeTabId);
  }

  private createSseTab(): void {
    const id = `untitled-${this.nextTabNumber}`;
    const request = this.createRequest();
    request.protocol = 'sse';
    request.url = 'https://';
    const name = `Untitled SSE ${this.nextTabNumber}`;
    this.tabs = [...this.tabs, {
      id, name, method: 'GET', dirty: true, pinned: false, loading: false,
      request, response: createEmptyResponse()
    }];
    this.sseSessions = [...this.sseSessions, this.emptySseSession(id)];
    this.nextTabNumber += 1;
    this.activeTabId = id;
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.rememberRequest(id, name, request);
    this.persistLocalData();
  }

  private webSocketTimestamp(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:` +
      `${now.getMinutes().toString().padStart(2, '0')}:` +
      now.getSeconds().toString().padStart(2, '0');
  }

  private beginRealtimeHistory(requestId: string, protocol: RequestProtocol, method: HttpMethod,
    url: string): void {
    if (!this.preferences.saveHistory) return;
    const now = new Date();
    const historyId = `history-${protocol}-${Date.now()}`;
    this.realtimeHistoryIds.set(requestId, historyId);
    this.historyItems = [{
      id: historyId,
      group: 'Today',
      createdAt: Date.now(),
      time: `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`,
      method,
      url,
      status: 0,
      duration: protocol === 'websocket' ? 'Connecting' : 'Streaming',
      protocol
    }, ...this.historyItems];
    this.persistLocalData();
  }

  private updateRealtimeHistory(requestId: string, status: number, duration: string, completed: boolean): void {
    const historyId = this.realtimeHistoryIds.get(requestId);
    if (!historyId) return;
    this.historyItems = this.historyItems.map((item: HistoryItemModel): HistoryItemModel =>
      item.id === historyId ? {
        id: item.id, group: item.group, createdAt: item.createdAt, time: item.time,
        method: item.method, url: item.url, status, duration, protocol: item.protocol
      } : item);
    if (completed) this.realtimeHistoryIds.delete(requestId);
    this.persistLocalData();
  }

  private updateLatestWebSocketHistory(history: WebSocketConnectionRecord[],
    status: 'connecting' | 'connected' | 'closed' | 'failed', errorCode: string = ''): WebSocketConnectionRecord[] {
    if (history.length === 0) return history;
    return history.map((item: WebSocketConnectionRecord, index: number): WebSocketConnectionRecord =>
      index === history.length - 1 ? {
        id: item.id, url: item.url, startedAt: item.startedAt,
        endedAt: status === 'closed' || status === 'failed' ? this.webSocketTimestamp() : '',
        status, errorCode
      } : item);
  }

  private webSocketMessage(direction: 'sent' | 'received' | 'system', text: string): WebSocketMessageModel {
    this.webSocketMessageSerial += 1;
    return {
      id: `ws-message-${Date.now()}-${this.webSocketMessageSerial}`,
      direction,
      text,
      timestamp: this.webSocketTimestamp()
    };
  }

  private replaceWebSocketSession(next: WebSocketSessionModel): void {
    const exists = this.webSocketSessions.some((item: WebSocketSessionModel) =>
      item.requestId === next.requestId);
    this.webSocketSessions = exists ? this.webSocketSessions.map((item: WebSocketSessionModel) =>
      item.requestId === next.requestId ? next : item) : [...this.webSocketSessions, next];
  }

  private webSocketEvent(id: string, event: WebSocketEvent): void {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id) ??
      this.emptyWebSocketSession(id);
    let status = current.status;
    let errorCode = current.errorCode;
    let errorMessage = current.errorMessage;
    let message: WebSocketMessageModel | undefined = undefined;
    let connectionHistory = current.connectionHistory ?? [];
    const eventText = event.text ?? '';
    const replacePreviousError = event.kind === 'error' && current.status === 'error' &&
      current.messages.length > 0 && current.messages[current.messages.length - 1].direction === 'system';
    if (event.kind === 'open') {
      status = 'connected';
      errorCode = '';
      errorMessage = '';
      message = this.webSocketMessage('system', this.preferences.language === 'zh' ? '连接已建立' :
        'Connection established');
      connectionHistory = this.updateLatestWebSocketHistory(connectionHistory, 'connected');
    } else if (event.kind === 'message') {
      message = this.webSocketMessage('received', eventText);
    } else if (event.kind === 'close') {
      status = 'disconnected';
      const reason = eventText.length > 0 ? ` · ${eventText}` : '';
      message = this.webSocketMessage('system', `${this.preferences.language === 'zh' ? '连接已关闭' :
        'Connection closed'} (${event.code})${reason}`);
      connectionHistory = this.updateLatestWebSocketHistory(connectionHistory, 'closed', event.code);
    } else {
      status = 'error';
      errorCode = event.code;
      errorMessage = eventText;
      message = this.webSocketMessage('system', eventText.length > 0 ? eventText :
        (this.preferences.language === 'zh' ? 'WebSocket 连接失败' : 'WebSocket connection failed'));
      connectionHistory = this.updateLatestWebSocketHistory(connectionHistory, 'failed', event.code);
    }
    this.replaceWebSocketSession({
      requestId: id,
      status,
      composer: current.composer,
      messages: message ? (replacePreviousError ?
        [...current.messages.slice(0, current.messages.length - 1), message] : [...current.messages, message]) :
        current.messages,
      errorCode,
      errorMessage,
      connectionHistory
    });
    if (event.kind === 'open') {
      this.updateRealtimeHistory(id, 101, 'Connected', false);
    } else if (event.kind === 'close') {
      this.updateRealtimeHistory(id, 101, 'Closed', true);
    } else if (event.kind === 'error') {
      this.updateRealtimeHistory(id, 0, 'Failed', true);
    }
  }

  private webSocketUrlChange(id: string, value: string): void {
    const current = this.tabs.find((tab: RequestTabModel) => tab.id === id);
    if (!current || current.request.url === value) return;
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id) return tab;
      const request = this.requestWithLifecycle(tab.request, 'idle');
      request.url = value;
      return {
        id: tab.id, name: tab.name, method: tab.method, dirty: true,
        pinned: tab.pinned, loading: false, request, response: tab.response
      };
    });
    const tab = this.tabs.find((item: RequestTabModel) => item.id === id);
    if (tab) this.rememberRequest(tab.id, tab.name, tab.request);
    this.scheduleRequestPersistence();
  }

  private webSocketOperationError(id: string, code: string, text: string): void {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id) ??
      this.emptyWebSocketSession(id);
    this.replaceWebSocketSession({
      requestId: id, status: current.status, composer: current.composer,
      messages: [...current.messages, this.webSocketMessage('system', text)],
      errorCode: code, errorMessage: text, connectionHistory: current.connectionHistory
    });
  }

  private async connectWebSocket(id: string): Promise<void> {
    const tab = this.tabs.find((item: RequestTabModel) => item.id === id);
    if (!tab) return;
    this.beginRealtimeHistory(id, 'websocket', tab.request.method, tab.request.url);
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id) ??
      this.emptyWebSocketSession(id);
    const record: WebSocketConnectionRecord = {
      id: `ws-connection-${Date.now()}-${this.webSocketMessageSerial + 1}`,
      url: tab.request.url,
      startedAt: this.webSocketTimestamp(),
      endedAt: '',
      status: 'connecting',
      errorCode: ''
    };
    this.replaceWebSocketSession({
      requestId: id, status: 'connecting', composer: current.composer, messages: current.messages,
      errorCode: '', errorMessage: '', connectionHistory: [...(current.connectionHistory ?? []), record]
    });
    const environment = this.scopedEnvironment(id, this.activeEnvironment());
    const config = WebSocketRequestBuilder.build(tab.request, environment);
    if (config.unresolvedVariables.length > 0) {
      this.webSocketEvent(id, { kind: 'error', code: 'UNRESOLVED_VARIABLE',
        text: `${this.preferences.language === 'zh' ? '缺少变量' : 'Missing variables'}: ` +
          config.unresolvedVariables.map((name: string) => `{{${name}}}`).join(', ') });
      return;
    }
    const url = config.url;
    const validUrl = (url.startsWith('ws://') && url.length > 5) ||
      (url.startsWith('wss://') && url.length > 6);
    if (!validUrl) {
      this.webSocketEvent(id, { kind: 'error', code: 'INVALID_URL',
        text: this.preferences.language === 'zh' ? 'WebSocket 地址必须以 ws:// 或 wss:// 开头。' :
          'The WebSocket URL must start with ws:// or wss://.' });
      return;
    }
    await this.webSocketController.connect(id, url, config.headers,
      (event: WebSocketEvent) => this.webSocketEvent(id, event));
  }

  private async disconnectWebSocket(id: string): Promise<void> {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id);
    if (!current) return;
    this.replaceWebSocketSession({
      requestId: id, status: 'closing', composer: current.composer, messages: current.messages,
      errorCode: '', errorMessage: '', connectionHistory: current.connectionHistory
    });
    await this.webSocketController.disconnect(id);
  }

  private webSocketComposerChange(id: string, value: string): void {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id) ??
      this.emptyWebSocketSession(id);
    if (current.composer === value) return;
    this.replaceWebSocketSession({
      requestId: id, status: current.status, composer: value, messages: current.messages,
      errorCode: current.errorCode, errorMessage: current.errorMessage,
      connectionHistory: current.connectionHistory
    });
  }

  private async sendWebSocketMessage(id: string): Promise<void> {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id);
    if (!current || current.status !== 'connected' || current.composer.length === 0) return;
    const environment = this.scopedEnvironment(id, this.activeEnvironment());
    const unresolved = WebSocketRequestBuilder.unresolved(current.composer, environment);
    if (unresolved.length > 0) {
      this.webSocketOperationError(id, 'UNRESOLVED_VARIABLE',
        `${this.preferences.language === 'zh' ? '消息中缺少变量' :
          'Missing variables in message'}: ` + unresolved.map((name: string) => `{{${name}}}`).join(', '));
      return;
    }
    const source = current.composer;
    const value = WebSocketRequestBuilder.resolve(source, environment);
    const sent = await this.webSocketController.send(id, value);
    const latest = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id) ?? current;
    if (sent) {
      this.replaceWebSocketSession({
        requestId: id, status: latest.status, composer: '',
        messages: [...latest.messages, this.webSocketMessage('sent', value)], errorCode: '', errorMessage: '',
        connectionHistory: latest.connectionHistory
      });
    } else {
      this.webSocketOperationError(id, 'SEND_FAILED', this.preferences.language === 'zh' ?
        '消息发送失败，请检查连接状态。' : 'The message could not be sent. Check the connection state.');
    }
  }

  private clearWebSocketMessages(id: string): void {
    const current = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id);
    if (!current) return;
    this.replaceWebSocketSession({
      requestId: id, status: current.status, composer: current.composer, messages: [],
      errorCode: current.errorCode, errorMessage: current.errorMessage,
      connectionHistory: current.connectionHistory
    });
  }

  private webSocketTranscript(session: WebSocketSessionModel): string {
    return session.messages.map((item: WebSocketMessageModel) =>
      `[${item.timestamp}] ${item.direction.toUpperCase()}\n${item.text}`).join('\n\n');
  }

  private async copyWebSocketMessages(id: string): Promise<void> {
    const session = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id);
    if (!session || session.messages.length === 0) return;
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.webSocketTranscript(session));
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private async exportWebSocketMessages(id: string): Promise<void> {
    const session = this.webSocketSessions.find((item: WebSocketSessionModel) => item.requestId === id);
    if (!session || session.messages.length === 0) return;
    try {
      const date = new Date().toISOString().substring(0, 10);
      if (await LocalFileExporter.saveText(`nimbo-websocket-${date}.txt`, this.webSocketTranscript(session))) {
        this.showToast($r('app.string.toast_exported'));
      }
    } catch (_error) {
      this.showToast($r('app.string.toast_export_failed'));
    }
  }

  private sseTimestamp(): string {
    return this.webSocketTimestamp();
  }

  private replaceSseSession(next: SseSessionModel): void {
    const exists = this.sseSessions.some((item: SseSessionModel) => item.requestId === next.requestId);
    this.sseSessions = exists ? this.sseSessions.map((item: SseSessionModel) =>
      item.requestId === next.requestId ? next : item) : [...this.sseSessions, next];
  }

  private handleSseEvent(id: string, event: SseControllerEvent): void {
    const current = this.sseSessions.find((item: SseSessionModel) => item.requestId === id) ??
      this.emptySseSession(id);
    if (event.kind === 'event' && event.event) {
      this.sseEventSerial += 1;
      const item: SseEventModel = {
        id: `sse-event-${Date.now()}-${this.sseEventSerial}`,
        event: event.event.event,
        data: event.event.data,
        eventId: event.event.eventId,
        retry: event.event.retry,
        timestamp: this.sseTimestamp()
      };
      this.replaceSseSession({
        requestId: id, status: current.status === 'connecting' ? 'connected' : current.status,
        events: [...current.events, item], errorCode: '', errorMessage: '',
        statusCode: event.statusCode || current.statusCode,
        contentType: event.contentType || current.contentType
      });
      if (event.statusCode > 0) this.updateRealtimeHistory(id, event.statusCode, 'Streaming', false);
      return;
    }
    if (event.kind === 'open') {
      this.replaceSseSession({
        requestId: id, status: 'connected', events: current.events, errorCode: '', errorMessage: '',
        statusCode: event.statusCode, contentType: event.contentType
      });
      this.updateRealtimeHistory(id, event.statusCode, 'Streaming', false);
    } else if (event.kind === 'end') {
      this.replaceSseSession({
        requestId: id, status: 'completed', events: current.events, errorCode: '', errorMessage: '',
        statusCode: event.statusCode || current.statusCode,
        contentType: event.contentType || current.contentType
      });
      this.updateRealtimeHistory(id, event.statusCode || current.statusCode, 'Completed', true);
    } else if (event.kind === 'error') {
      this.replaceSseSession({
        requestId: id, status: 'error', events: current.events, errorCode: event.code,
        errorMessage: event.message, statusCode: event.statusCode || current.statusCode,
        contentType: event.contentType || current.contentType
      });
      this.updateRealtimeHistory(id, event.statusCode || current.statusCode, 'Failed', true);
    }
  }

  private async connectSse(id: string): Promise<void> {
    const tab = this.tabs.find((item: RequestTabModel) => item.id === id);
    if (!tab) return;
    this.beginRealtimeHistory(id, 'sse', tab.request.method, tab.request.url);
    const environment = this.scopedEnvironment(id, this.activeEnvironment());
    const config = WebSocketRequestBuilder.build(tab.request, environment);
    const body = tab.request.bodyType === 'json' || tab.request.bodyType === 'text' ?
      WebSocketRequestBuilder.resolve(tab.request.bodyText, environment) : '';
    if (body.length > 0) {
      WebSocketRequestBuilder.unresolved(tab.request.bodyText, environment).forEach((name: string) => {
        if (!config.unresolvedVariables.includes(name)) config.unresolvedVariables.push(name);
      });
    }
    const current = this.sseSessions.find((item: SseSessionModel) => item.requestId === id) ??
      this.emptySseSession(id);
    if (config.unresolvedVariables.length > 0) {
      this.replaceSseSession({
        requestId: id, status: 'error', events: current.events, errorCode: 'UNRESOLVED_VARIABLE',
        errorMessage: `${this.preferences.language === 'zh' ? '缺少变量' : 'Missing variables'}: ` +
          config.unresolvedVariables.map((name: string) => `{{${name}}}`).join(', '),
        statusCode: 0, contentType: ''
      });
      this.updateRealtimeHistory(id, 0, 'Failed', true);
      return;
    }
    const validUrl = (config.url.startsWith('http://') && config.url.length > 7) ||
      (config.url.startsWith('https://') && config.url.length > 8);
    if (!validUrl) {
      this.replaceSseSession({
        requestId: id, status: 'error', events: current.events, errorCode: 'INVALID_URL',
        errorMessage: this.preferences.language === 'zh' ? 'SSE 地址必须以 http:// 或 https:// 开头。' :
          'The SSE URL must start with http:// or https://.', statusCode: 0, contentType: ''
      });
      this.updateRealtimeHistory(id, 0, 'Failed', true);
      return;
    }
    this.replaceSseSession({
      requestId: id, status: 'connecting', events: current.events, errorCode: '', errorMessage: '',
      statusCode: 0, contentType: ''
    });
    await this.sseController.connect(id, config.url, tab.request.method, config.headers, body,
      Math.max(300000, tab.request.settings.timeoutMs),
      (event: SseControllerEvent) => this.handleSseEvent(id, event));
  }

  private stopSse(id: string): void {
    const current = this.sseSessions.find((item: SseSessionModel) => item.requestId === id);
    if (!current) return;
    this.replaceSseSession({
      requestId: id, status: 'stopping', events: current.events, errorCode: '', errorMessage: '',
      statusCode: current.statusCode, contentType: current.contentType
    });
    this.updateRealtimeHistory(id, current.statusCode, 'Stopped', true);
    this.sseController.stop(id);
    this.replaceSseSession({
      requestId: id, status: 'disconnected', events: current.events, errorCode: '', errorMessage: '',
      statusCode: current.statusCode, contentType: current.contentType
    });
  }

  private clearSseEvents(id: string): void {
    const current = this.sseSessions.find((item: SseSessionModel) => item.requestId === id);
    if (!current) return;
    this.replaceSseSession({
      requestId: id, status: current.status, events: [], errorCode: current.errorCode,
      errorMessage: current.errorMessage, statusCode: current.statusCode, contentType: current.contentType
    });
  }

  private sseTranscript(session: SseSessionModel): string {
    return session.events.map((item: SseEventModel) => {
      const metadata = [item.eventId.length > 0 ? `id=${item.eventId}` : '',
        item.retry.length > 0 ? `retry=${item.retry}` : ''].filter((value: string) => value.length > 0).join(' ');
      return `[${item.timestamp}] ${item.event}${metadata.length > 0 ? ` (${metadata})` : ''}\n${item.data}`;
    }).join('\n\n');
  }

  private async copySseEvents(id: string): Promise<void> {
    const session = this.sseSessions.find((item: SseSessionModel) => item.requestId === id);
    if (!session || session.events.length === 0) return;
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.sseTranscript(session));
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private async exportSseEvents(id: string): Promise<void> {
    const session = this.sseSessions.find((item: SseSessionModel) => item.requestId === id);
    if (!session || session.events.length === 0) return;
    try {
      const date = new Date().toISOString().substring(0, 10);
      if (await LocalFileExporter.saveText(`nimbo-sse-${date}.txt`, this.sseTranscript(session))) {
        this.showToast($r('app.string.toast_exported'));
      }
    } catch (_error) {
      this.showToast($r('app.string.toast_export_failed'));
    }
  }

  private showToast(message: ResourceStr, actionVisible: boolean = false): void {
    this.toastMessage = message;
    this.toastActionVisible = actionVisible;
    this.animateState(() => { this.toastVisible = true; });
    setTimeout(() => {
      if (this.toastMessage === message) {
        this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
          this.toastVisible = false;
        });
        setTimeout(() => {
          if (!this.toastVisible && this.toastMessage === message) {
            this.toastMessage = '';
            this.toastActionVisible = false;
          }
        }, MotionTokens.fast);
      }
    }, 1800);
  }

  private updateEnvironment(id: string, variables: KeyValueItem[]): void {
    this.environments = this.environments.map((environment: EnvironmentModel) => {
      if (environment.id !== id) return environment;
      return { id: environment.id, name: environment.name, kind: environment.kind, variables,
        system: environment.system };
    });
    this.persistLocalData();
  }

  private createEnvironment(name: string): void {
    const id = `environment-${Date.now()}`;
    const environment: EnvironmentModel = {
      id,
      name,
      kind: 'custom',
      variables: [],
      system: false
    };
    this.environments = [...this.environments, environment];
    this.selectedEnvironmentId = id;
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_environment_created'));
  }

  private beginDeleteEnvironment(id: string): void {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === id);
    if (!environment || environment.system) return;
    this.deletingEnvironmentId = id;
    this.showOverlay('delete-environment');
  }

  private deleteEnvironment(): void {
    const id = this.deletingEnvironmentId;
    this.environments = this.environments.filter((item: EnvironmentModel) => item.id !== id || item.system);
    if (this.selectedEnvironmentId === id) this.selectedEnvironmentId = 'development';
    this.deletingEnvironmentId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_deleted'));
  }

  private restartForLanguage(): void {
    setTimeout(() => {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const want: Want = { bundleName: 'com.nimbo.app', abilityName: 'EntryAbility' };
        context.getApplicationContext().restartApp(want);
      } catch (_error) {
        this.showToast($r('app.string.toast_restart_language'));
      }
    }, 200);
  }

  private applyTheme(theme: NimboTheme): void {
    try {
      let mode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
      if (theme === 'light') mode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      if (theme === 'dark') mode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.getApplicationContext().setColorMode(mode);
    } catch (_error) {
      this.showToast($r('app.string.toast_theme_failed'));
    }
  }

  private applyFont(font: NimboFont): void {
    try {
      const family = font === 'system' ? '' :
        (font === 'compact' ? 'HarmonyOS Sans Condensed' : 'HarmonyOS Sans SC');
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.getApplicationContext().setFont(family);
    } catch (_error) {
      this.showToast($r('app.string.toast_font_failed'));
    }
  }

  private updatePreferences(preferences: AppPreferencesModel): void {
    const languageChanged = this.preferences.language !== preferences.language;
    const themeChanged = this.preferences.theme !== preferences.theme;
    const fontChanged = this.preferences.interfaceFont !== preferences.interfaceFont;
    this.preferences = preferences;
    if (languageChanged) {
      try {
        i18n.System.setAppPreferredLanguage(preferences.language === 'zh' ? 'zh' : 'en');
      } catch (_error) {
        this.showToast($r('app.string.toast_language_failed'));
      }
    }
    this.historyItems = this.normalizeHistory(this.historyItems);
    this.persistLocalData();
    if (themeChanged) this.applyTheme(preferences.theme);
    if (fontChanged) this.applyFont(preferences.interfaceFont);
    if (languageChanged) {
      this.restartForLanguage();
    } else {
      this.showToast($r('app.string.toast_saved'));
    }
  }

  private createImportedRequest(result: CurlImportResult, name: string): void {
    const id = `imported-${Date.now()}`;
    const request = this.createRequest(result.method);
    request.url = result.url;
    request.params = result.params;
    request.headers = result.headers;
    request.auth = result.auth;
    request.bodyType = result.bodyType;
    request.bodyText = result.bodyText;
    request.formItems = result.formItems;
    request.multipartItems = result.multipartItems;
    this.tabs = [...this.tabs, {
      id,
      name,
      method: result.method,
      dirty: true,
      pinned: false,
      loading: false,
      request,
      response: createEmptyResponse()
    }];
    this.activeTabId = id;
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.rememberRequest(id, name, request);
    this.persistLocalData();
  }

  private applyPostmanImport(result: PostmanImportResult): void {
    const nextCollections = [...this.collections, ...result.collections];
    const nextRequests = [...this.savedRequests, ...result.requests];
    const nextEnvironments = [...this.environments, ...result.environments];
    this.collections = nextCollections;
    this.savedRequests = nextRequests;
    this.environments = nextEnvironments;
    this.persistLocalData();
  }

  private applyOpenApiImport(result: OpenApiImportResult): void {
    this.collections = [...this.collections, ...result.collections];
    this.savedRequests = [...this.savedRequests, ...result.requests];
    this.persistLocalData();
  }

  private openHistoryItem(item: HistoryItemModel): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === item.id);
    if (existing) {
      this.activeTabId = existing.id;
    } else {
      const request = this.createRequest(item.method);
      request.url = item.url;
      request.protocol = item.protocol ?? 'http';
      const label = request.protocol === 'websocket' ? 'WebSocket' :
        (request.protocol === 'sse' ? 'SSE' : item.method);
      this.tabs = [...this.tabs, {
        id: item.id,
        name: `${label} Request`,
        method: item.method,
        dirty: false,
        pinned: false,
        loading: false,
        request,
        response: createEmptyResponse()
      }];
      if (request.protocol === 'websocket') {
        this.webSocketSessions = [...this.webSocketSessions, this.emptyWebSocketSession(item.id)];
      } else if (request.protocol === 'sse') {
        this.sseSessions = [...this.sseSessions, this.emptySseSession(item.id)];
      }
      this.activeTabId = item.id;
    }
    this.animateState(() => { this.activeDestination = 'workspace'; });
    this.persistLocalData();
  }

  private deleteHistoryItem(id: string): void {
    this.lastDeletedHistory = this.historyItems.filter((item: HistoryItemModel) => item.id === id);
    this.animateState(() => {
      this.historyItems = this.historyItems.filter((item: HistoryItemModel) => item.id !== id);
    });
    this.persistLocalData();
    this.showToast($r('app.string.toast_deleted'), true);
  }

  private undoHistoryDelete(): void {
    if (this.lastDeletedHistory.length === 0) return;
    this.animateState(() => {
      this.historyItems = [...this.lastDeletedHistory, ...this.historyItems];
    });
    this.lastDeletedHistory = [];
    this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
      this.toastVisible = false;
    });
    this.toastMessage = '';
    this.toastActionVisible = false;
    this.persistLocalData();
  }

  private async copyHistoryItem(item: HistoryItemModel, asCurl: boolean): Promise<void> {
    let value = item.url;
    if (asCurl && (item.protocol ?? 'http') === 'http') {
      const request = this.createRequest(item.method);
      request.url = item.url;
      value = CurlCodec.encode(request);
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, value);
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private async copyGeneratedCode(value: string): Promise<void> {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, value);
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private diagnosticHost(url: string): string {
    const trimmed = url.trim();
    const scheme = trimmed.indexOf('://');
    const start = scheme >= 0 ? scheme + 3 : 0;
    let end = trimmed.length;
    const separators = [trimmed.indexOf('/', start), trimmed.indexOf('?', start), trimmed.indexOf('#', start)];
    separators.forEach((position: number) => {
      if (position >= 0 && position < end) end = position;
    });
    let authority = trimmed.substring(start, end);
    const at = authority.lastIndexOf('@');
    if (at >= 0) authority = authority.substring(at + 1);
    return authority;
  }

  private diagnosticStage(stage: string): string {
    const chinese = this.preferences.language === 'zh';
    if (stage === 'validation') return chinese ? '请求校验' : 'Validation';
    if (stage === 'dns') return chinese ? 'DNS 解析' : 'DNS lookup';
    if (stage === 'connect') return chinese ? '建立连接' : 'Connection';
    if (stage === 'tls') return chinese ? 'TLS 握手' : 'TLS handshake';
    if (stage === 'send') return chinese ? '发送请求' : 'Request upload';
    if (stage === 'receive') return chinese ? '等待或接收响应' : 'Response wait/download';
    if (stage === 'script') return chinese ? '前置脚本' : 'Pre-request script';
    if (stage === 'file') return chinese ? '读取或传输文件' : 'File read/transfer';
    return chinese ? '未知阶段' : 'Unknown stage';
  }

  private async copyErrorDiagnostic(error: ResponseErrorModel): Promise<void> {
    const chinese = this.preferences.language === 'zh';
    const lines: string[] = [
      chinese ? 'Nimbo 请求诊断' : 'Nimbo request diagnostic',
      `${chinese ? '类型' : 'Type'}: ${error.type}`,
      `${chinese ? '错误码' : 'Code'}: ${error.code || '-'}`,
      `${chinese ? '阶段' : 'Stage'}: ${this.diagnosticStage(error.stage ?? 'unknown')}`,
      `${chinese ? '请求' : 'Request'}: ${error.method ?? '-'} ${error.host ?? '-'}`,
      `${chinese ? '耗时' : 'Elapsed'}: ${error.durationMs ?? 0} ms`,
      `${chinese ? '超时设置' : 'Timeout'}: ${error.timeoutMs ?? 0} ms`,
      `${chinese ? '证书校验' : 'TLS verification'}: ${error.sslVerification === false ? 'off' : 'on'}`,
      `${chinese ? '自动重定向' : 'Follow redirects'}: ${error.followRedirects === false ? 'off' : 'on'}`
    ];
    if ((error.unresolvedVariables?.length ?? 0) > 0) {
      lines.push(`${chinese ? '缺失变量' : 'Missing variables'}: ${error.unresolvedVariables?.join(', ')}`);
    }
    if (error.type !== 'script' && error.details.length > 0) {
      lines.push(`${chinese ? '系统信息' : 'System message'}: ${error.details}`);
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, lines.join('\n'));
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.error_diagnostic_copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private async exportNimbo(includeSecrets: boolean): Promise<void> {
    try {
      const date = new Date().toISOString().substring(0, 10);
      const content = NimboExportCodec.encode(this.persistedState(), includeSecrets);
      if (await LocalFileExporter.saveText(`nimbo-backup-${date}.nimbo.json`, content)) {
        this.showToast($r('app.string.toast_exported'));
      }
    } catch (_error) {
      this.showToast($r('app.string.toast_export_failed'));
    }
  }

  private binaryExtension(contentType: string): string {
    const value = contentType.toLowerCase();
    if (value.includes('zip')) return 'zip';
    if (value.includes('pdf')) return 'pdf';
    if (value.includes('png')) return 'png';
    if (value.includes('jpeg') || value.includes('jpg')) return 'jpg';
    if (value.includes('gif')) return 'gif';
    if (value.includes('webp')) return 'webp';
    if (value.includes('svg')) return 'svg';
    if (value.includes('webm')) return 'webm';
    if (value.includes('quicktime')) return 'mov';
    if (value.includes('video/ogg')) return 'ogv';
    if (value.includes('video/mpeg')) return 'mpeg';
    if (value.includes('video/mp4')) return 'mp4';
    return 'bin';
  }

  private textExtension(contentType: string): string {
    const value = contentType.toLowerCase();
    if (value.includes('json')) return 'json';
    if (value.includes('xml')) return 'xml';
    if (value.includes('html')) return 'html';
    if (value.includes('css')) return 'css';
    if (value.includes('javascript')) return 'js';
    if (value.includes('yaml') || value.includes('yml')) return 'yaml';
    if (value.includes('csv')) return 'csv';
    return 'txt';
  }

  private async copyResponseBody(response: ResponseModel): Promise<void> {
    if (response.body.length === 0) {
      this.showToast($r('app.string.toast_no_response_body'));
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, response.body);
      await pasteboard.getSystemPasteboard().setData(data);
      this.showToast($r('app.string.response_body_copied'));
    } catch (_error) {
      this.showToast($r('app.string.toast_copy_failed'));
    }
  }

  private async downloadResponseBody(response: ResponseModel): Promise<void> {
    if (response.body.length === 0) {
      this.showToast($r('app.string.toast_no_response_body'));
      return;
    }
    try {
      const name = `nimbo-response.${this.textExtension(response.contentType)}`;
      if (await LocalFileExporter.saveText(name, response.body)) {
        this.showToast($r('app.string.toast_saved'));
      }
    } catch (_error) {
      this.showToast($r('app.string.toast_save_failed'));
    }
  }

  private async saveBinaryResponse(response: ResponseModel): Promise<void> {
    if (response.binaryBody.byteLength === 0) {
      this.showToast($r('app.string.toast_no_binary'));
      return;
    }
    try {
      const name = `nimbo-response.${this.binaryExtension(response.contentType)}`;
      if (await LocalFileExporter.saveBytes(name, response.binaryBody)) {
        this.showToast($r('app.string.toast_saved'));
      }
    } catch (_error) {
      this.showToast($r('app.string.toast_save_failed'));
    }
  }

  @Builder
  mainContent() {
    if (this.activeDestination === 'environments') {
      EnvironmentPage({
        environments: this.environments,
        phone: this.isPhone(),
        selectedId: this.selectedEnvironmentId,
        onSelect: (id: string) => {
          this.selectedEnvironmentId = id;
          this.persistLocalData();
        },
        onCreate: () => this.showOverlay('create-environment'),
        onDelete: (id: string) => this.beginDeleteEnvironment(id),
        onChange: (id: string, variables: KeyValueItem[]) => this.updateEnvironment(id, variables),
        onSaved: () => this.showToast($r('app.string.toast_saved'))
      })
      .layoutWeight(1)
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    } else if (this.activeDestination === 'history') {
      HistoryPage({
        items: this.historyItems,
        phone: this.isPhone(),
        onOpen: (item: HistoryItemModel) => this.openHistoryItem(item),
        onCopy: (item: HistoryItemModel, asCurl: boolean) => this.copyHistoryItem(item, asCurl),
        onDelete: (id: string) => this.deleteHistoryItem(id),
        onClear: () => this.showOverlay('clear-history')
      })
      .layoutWeight(1)
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    } else if (this.activeDestination === 'settings') {
      SettingsPage({
        preferences: this.preferences,
        phone: this.isPhone(),
        onChange: (preferences: AppPreferencesModel) => this.updatePreferences(preferences),
        onExport: () => this.exportNimbo(false),
        onExportSecrets: () => this.showOverlay('export-secrets'),
        onReset: () => this.showOverlay('reset-app'),
        onHelp: () => this.selectDestination('help')
      })
      .layoutWeight(1)
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    } else if (this.activeDestination === 'help') {
      HelpPage({ phone: this.isPhone() })
        .layoutWeight(1)
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
          .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    } else {
      Stack({ alignContent: Alignment.TopStart }) {
        Row() {
          if (this.showCollectionSidebar()) {
            CollectionSidebar({
              widthValue: this.collectionWidth(),
              borderedEnd: false,
              nodes: $collections,
              onOpenRequest: (node: CollectionNode) => this.openCollectionRequest(node),
              onToggleNode: (id: string) => this.toggleCollectionNode(id),
              onCreateCollection: () => this.beginCreateCollection(),
              onCreateRequest: (parentId: string) => this.createRequestInCollection(parentId),
              onCreateWebSocket: (parentId: string) => this.createRequestInCollection(parentId, 'websocket'),
              onCreateSse: (parentId: string) => this.createRequestInCollection(parentId, 'sse'),
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId),
              onEditVariables: (node: CollectionNode) => this.beginEditCollectionVariables(node),
              onRenameFolder: (node: CollectionNode) => this.beginRenameFolder(node),
              onRenameRequest: (node: CollectionNode) => this.beginRenameRequest(node),
              onDuplicateRequest: (node: CollectionNode) => this.duplicateCollectionRequest(node),
              onRunNode: (node: CollectionNode) => this.beginRunCollectionNode(node),
              onDeleteNode: (node: CollectionNode) => this.beginDeleteCollectionNode(node)
            })
            Row() {
              Row()
                .width(this.collectionSplitterHovered || this.collectionSplitterResizing ? 2 : 1)
                .height('100%')
                .backgroundColor(this.collectionSplitterHovered || this.collectionSplitterResizing ?
                  ColorTokens.borderFocus : ColorTokens.borderSubtle)
            }
            .width(8)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(ColorTokens.bgWorkspace)
            .onHover((hovered: boolean) => { this.collectionSplitterHovered = hovered; })
            .gesture(
              GestureGroup(GestureMode.Exclusive,
                TapGesture({ count: 2 }).onAction(() =>
                  this.resizeCollectionSidebar(SizeTokens.collectionSidebarWidth)),
                PanGesture({ direction: PanDirection.Horizontal, distance: 1 })
                  .onActionStart(() => {
                    this.collectionSplitterDragStart = this.collectionWidth();
                    this.collectionSplitterResizing = true;
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.resizeCollectionSidebar(this.collectionSplitterDragStart + event.offsetX);
                  })
                  .onActionEnd(() => { this.collectionSplitterResizing = false; })
                  .onActionCancel(() => { this.collectionSplitterResizing = false; })
              )
            )
          }

          Workspace({
            tabs: $tabs,
            activeTabId: $activeTabId,
            phone: this.isPhone(),
            environments: this.environments,
            selectedEnvironmentId: this.selectedEnvironmentId,
            resolvedVariables: this.activeScopedVariables(),
            variableResolutions: this.activeVariableResolutions(),
            missingVariables: this.activeMissingVariables(),
            webSocketSession: this.currentWebSocketSession(),
            sseSession: this.currentSseSession(),
            onSelectTab: (id: string) => {
              this.activeTabId = id;
              this.persistLocalData();
            },
            onCloseTab: (id: string) => this.closeTab(id),
            onCloseAllTabs: () => this.closeAllTabs(),
            onCreateTab: () => this.createTab(),
            onRenameRequest: (id: string, name: string) => this.applyRequestName(id, name),
            onUpdateRequest: (id: string, request: RequestDraft) => this.updateRequest(id, request),
            onSaveRequest: (id: string) => this.beginSaveRequest(id),
            onCopyGeneratedCode: (value: string) => this.copyGeneratedCode(value),
            onCopyErrorDiagnostic: (error: ResponseErrorModel) => this.copyErrorDiagnostic(error),
            onEditVariableSource: (kind: VariableSourceKind, id: string) => this.editVariableSource(kind, id),
            onConfigureVariables: (id: string) => this.configureMissingVariables(id),
            onWebSocketUrlChange: (id: string, value: string) => this.webSocketUrlChange(id, value),
            onWebSocketConnect: (id: string) => this.connectWebSocket(id),
            onWebSocketDisconnect: (id: string) => this.disconnectWebSocket(id),
            onWebSocketComposerChange: (id: string, value: string) => this.webSocketComposerChange(id, value),
            onWebSocketSend: (id: string) => this.sendWebSocketMessage(id),
            onWebSocketClear: (id: string) => this.clearWebSocketMessages(id),
            onWebSocketCopy: (id: string) => this.copyWebSocketMessages(id),
            onWebSocketExport: (id: string) => this.exportWebSocketMessages(id),
            onSseConnect: (id: string) => this.connectSse(id),
            onSseStop: (id: string) => this.stopSse(id),
            onSseClear: (id: string) => this.clearSseEvents(id),
            onSseCopy: (id: string) => this.copySseEvents(id),
            onSseExport: (id: string) => this.exportSseEvents(id),
            onPreviewLargeResponse: (id: string) => this.previewLargeResponse(id),
            onSaveBinary: (response: ResponseModel) => this.saveBinaryResponse(response),
            onCopyResponseBody: (response: ResponseModel) => this.copyResponseBody(response),
            onDownloadResponseBody: (response: ResponseModel) => this.downloadResponseBody(response)
          })
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')

        if (this.showCollectionDrawer()) {
          Row() {
            CollectionSidebar({
              widthValue: SizeTokens.collectionSidebarCompactWidth,
              nodes: $collections,
              dismissible: true,
              onOpenRequest: (node: CollectionNode) => {
                this.animateState(() => {
                  this.collectionDrawerOpen = false;
                  this.activeDestination = 'workspace';
                }, MotionTokens.slow);
                this.openCollectionRequest(node);
              },
              onToggleNode: (id: string) => this.toggleCollectionNode(id),
              onCreateCollection: () => this.beginCreateCollection(),
              onCreateRequest: (parentId: string) => this.createRequestInCollection(parentId),
              onCreateWebSocket: (parentId: string) => this.createRequestInCollection(parentId, 'websocket'),
              onCreateSse: (parentId: string) => this.createRequestInCollection(parentId, 'sse'),
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId),
              onEditVariables: (node: CollectionNode) => this.beginEditCollectionVariables(node),
              onRenameFolder: (node: CollectionNode) => this.beginRenameFolder(node),
              onRenameRequest: (node: CollectionNode) => this.beginRenameRequest(node),
              onDuplicateRequest: (node: CollectionNode) => this.duplicateCollectionRequest(node),
              onRunNode: (node: CollectionNode) => this.beginRunCollectionNode(node),
              onDeleteNode: (node: CollectionNode) => this.beginDeleteCollectionNode(node),
              onDismiss: () => this.animateState(() => { this.collectionDrawerOpen = false; }, MotionTokens.slow)
            })
            Column()
              .layoutWeight(1)
              .height('100%')
              .backgroundColor(ColorTokens.overlayScrim)
              .onClick(() => this.animateState(() => { this.collectionDrawerOpen = false; }, MotionTokens.slow))
          }
          .width('100%')
          .height('100%')
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: -24 }))
            .animation({ duration: MotionTokens.slow, curve: MotionTokens.standardCurve }))
        }
      }
      .layoutWeight(1)
      .height('100%')
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
  }

  private closeTab(id: string): void {
    this.requestSerials.set(id, (this.requestSerials.get(id) ?? 0) + 1);
    this.requestController.cancel(id);
    this.webSocketController.disconnect(id, false);
    this.webSocketSessions = this.webSocketSessions.filter((item: WebSocketSessionModel) => item.requestId !== id);
    this.sseController.stop(id);
    this.sseSessions = this.sseSessions.filter((item: SseSessionModel) => item.requestId !== id);
    const closingIndex = this.tabs.findIndex((tab: RequestTabModel) => tab.id === id);
    this.tabs = this.tabs.filter((tab: RequestTabModel) => tab.id !== id);
    if (this.activeTabId === id) {
      if (this.tabs.length === 0) {
        this.activeTabId = '';
      } else {
        const nextIndex = Math.min(closingIndex, this.tabs.length - 1);
        this.activeTabId = this.tabs[nextIndex].id;
      }
    }
    this.persistLocalData();
  }

  private closeAllTabs(): void {
    this.webSocketController.disconnectAll();
    this.webSocketSessions = [];
    this.sseController.stopAll();
    this.sseSessions = [];
    this.tabs.forEach((tab: RequestTabModel) => {
      this.requestSerials.set(tab.id, (this.requestSerials.get(tab.id) ?? 0) + 1);
      this.requestController.cancel(tab.id);
    });
    this.tabs = [];
    this.activeTabId = '';
    this.persistLocalData();
  }

  private collectRunnerNodes(node: CollectionNode, requests: CollectionNode[]): void {
    if (node.type === 'request') {
      const saved = this.savedRequests.find((item: PersistedRequestModel) => item.id === node.id);
      if (!saved || saved.request.protocol === 'http' || saved.request.protocol === undefined) requests.push(node);
      return;
    }
    node.children.forEach((child: CollectionNode) => this.collectRunnerNodes(child, requests));
  }

  private runnerQueue(nodes: CollectionNode[], iterations: number): RunnerItemModel[] {
    const items: RunnerItemModel[] = [];
    for (let iteration = 1; iteration <= iterations; iteration += 1) {
      nodes.forEach((node: CollectionNode, index: number) => {
        const seed = this.requestSeedForNode(node);
        items.push({
          id: `${node.id}-${iteration}-${index}`,
          requestId: node.id,
          name: node.name,
          method: seed.request.method,
          iteration,
          status: 'queued',
          statusCode: 0,
          duration: '',
          passedTests: 0,
          failedTests: 0,
          message: '',
          details: []
        });
      });
    }
    return items;
  }

  private beginRunCollectionNode(node: CollectionNode): void {
    const requests: CollectionNode[] = [];
    this.collectRunnerNodes(node, requests);
    this.runnerTargetId = node.id;
    this.runnerTargetName = node.name;
    this.runnerEnvironmentName = this.activeEnvironment().name;
    this.runnerItems = this.runnerQueue(requests, 1);
    this.runnerRunning = false;
    this.runnerDataSet = undefined;
    this.runnerDataFileName = '';
    this.runnerDataRowCount = 0;
    this.runnerDataColumns = '';
    this.runnerDataError = '';
    this.showOverlay('collection-runner');
  }

  private async selectRunnerData(): Promise<void> {
    try {
      const selected = await RunnerDataService.select();
      if (selected === undefined) return;
      this.runnerDataSet = selected;
      this.runnerDataFileName = selected.fileName;
      this.runnerDataRowCount = selected.rows.length;
      this.runnerDataColumns = selected.columns.join(', ');
      this.runnerDataError = '';
    } catch (error) {
      this.runnerDataSet = undefined;
      this.runnerDataFileName = '';
      this.runnerDataRowCount = 0;
      this.runnerDataColumns = '';
      this.runnerDataError = `${error}`.replace('Error: ', '');
    }
  }

  private clearRunnerData(): void {
    if (this.runnerRunning) return;
    this.runnerDataSet = undefined;
    this.runnerDataFileName = '';
    this.runnerDataRowCount = 0;
    this.runnerDataColumns = '';
    this.runnerDataError = '';
  }

  private updateRunnerItem(id: string, change: (item: RunnerItemModel) => RunnerItemModel): void {
    this.runnerItems = this.runnerItems.map((item: RunnerItemModel) => item.id === id ? change(item) : item);
  }

  private runnerResult(item: RunnerItemModel, request: RequestDraft, response: ResponseModel): RunnerItemModel {
    const passedTests = response.testResults.filter((result: TestResult) => result.status === 'passed').length;
    const failedTests = response.testResults.filter((result: TestResult) => result.status === 'failed').length;
    const details: string[] = [];
    response.scriptResults.forEach((result: ScriptExecutionResult) => {
      if (result.status !== 'success') details.push(`${result.phase}: ${result.status}`);
    });
    response.extractionResults.forEach((result: ExtractionResult) => {
      if (result.status !== 'success' && result.status !== 'notRun') {
        details.push(`extraction ${result.ruleId}: ${result.status}`);
      }
    });
    response.testResults.forEach((result: TestResult) => {
      if (result.status !== 'failed') return;
      const rule = request.testRules.find(candidate => candidate.id === result.ruleId);
      details.push(`test ${rule?.kind ?? result.ruleId}: ${result.message}`);
    });
    if (response.status === 'error') {
      details.unshift(`${response.error.type}${response.error.code.length > 0 ? ` (${response.error.code})` : ''}`);
    }
    const failedResponse = response.status === 'error' || response.status === 'cancelled' ||
      response.statusCode === 0 || response.statusCode >= 400;
    const failed = failedResponse || failedTests > 0 || details.length > 0;
    let message = response.statusCode > 0 ? `${response.statusCode} ${response.statusText}` : response.error.type;
    if (failedTests > 0) {
      message = this.preferences.language === 'zh' ? `${failedTests} 项断言失败` : `${failedTests} tests failed`;
    } else if (details.length > 0) {
      message = details[0];
    }
    return {
      id: item.id, requestId: item.requestId, name: item.name, method: item.method,
      iteration: item.iteration, status: failed ? 'failed' : 'passed', statusCode: response.statusCode,
      duration: response.duration, passedTests, failedTests, message, details
    };
  }

  private async waitForRunner(delayMs: number, serial: number): Promise<void> {
    if (delayMs <= 0) return;
    let remaining = delayMs;
    while (remaining > 0 && this.runnerSerial === serial) {
      const slice = Math.min(remaining, 100);
      await new Promise<void>((resolve: () => void) => setTimeout(resolve, slice));
      remaining -= slice;
    }
  }

  private async startRunner(iterations: number, delayMs: number): Promise<void> {
    const target = this.findCollectionNode(this.collections, this.runnerTargetId);
    if (!target || this.runnerRunning || this.runnerDataError.length > 0) return;
    const nodes: CollectionNode[] = [];
    this.collectRunnerNodes(target, nodes);
    if (nodes.length === 0) return;
    const runIterations = this.runnerDataSet === undefined ? iterations : this.runnerDataSet.rows.length;
    const queue = this.runnerQueue(nodes, runIterations);
    const serial = this.runnerSerial + 1;
    const environmentId = this.selectedEnvironmentId;
    this.runnerSerial = serial;
    this.runnerStartedAt = new Date().toISOString();
    this.runnerRunDataFileName = this.runnerDataFileName;
    this.runnerRunDataRowCount = this.runnerDataRowCount;
    this.runnerEnvironmentName = this.environmentForId(environmentId).name;
    this.runnerItems = queue;
    this.runnerRunning = true;
    for (let index = 0; index < queue.length; index += 1) {
      if (this.runnerSerial !== serial) break;
      const item = queue[index];
      const node = nodes[index % nodes.length];
      const seed = this.requestSeedForNode(node);
      const runtimeValues = this.runnerDataSet === undefined ? undefined :
        this.runnerDataSet.rows[item.iteration - 1].values;
      this.updateRunnerItem(item.id, (current: RunnerItemModel): RunnerItemModel => ({
        id: current.id, requestId: current.requestId, name: current.name, method: current.method,
        iteration: current.iteration, status: 'running', statusCode: 0, duration: '',
        passedTests: 0, failedTests: 0, message: '', details: []
      }));
      const executionId = `runner-${serial}-${index}-${item.requestId}`;
      this.runnerExecutionId = executionId;
      const result = await this.executeRequestPipeline(executionId, seed.request, environmentId,
        (): boolean => this.runnerSerial === serial, runtimeValues, node.id);
      if (this.runnerSerial !== serial) break;
      if (result) {
        this.updateRunnerItem(item.id, (current: RunnerItemModel): RunnerItemModel =>
          this.runnerResult(current, result.executedRequest, result.response));
      }
      if (index < queue.length - 1) await this.waitForRunner(delayMs, serial);
    }
    if (this.runnerSerial === serial) {
      this.runnerExecutionId = '';
      this.runnerRunning = false;
      this.persistLocalData();
    }
  }

  private stopRunner(): void {
    if (!this.runnerRunning) return;
    this.runnerSerial += 1;
    if (this.runnerExecutionId.length > 0) this.requestController.cancel(this.runnerExecutionId);
    this.runnerExecutionId = '';
    this.runnerRunning = false;
    this.runnerItems = this.runnerItems.map((item: RunnerItemModel): RunnerItemModel => {
      if (item.status !== 'queued' && item.status !== 'running') return item;
      return {
        id: item.id, requestId: item.requestId, name: item.name, method: item.method,
        iteration: item.iteration, status: 'cancelled', statusCode: item.statusCode,
        duration: item.duration, passedTests: item.passedTests, failedTests: item.failedTests,
        message: '', details: item.details
      };
    });
  }

  private async exportRunnerReport(): Promise<void> {
    const passed = this.runnerItems.filter((item: RunnerItemModel) => item.status === 'passed').length;
    const failed = this.runnerItems.filter((item: RunnerItemModel) => item.status === 'failed').length;
    const cancelled = this.runnerItems.filter((item: RunnerItemModel) => item.status === 'cancelled').length;
    const items: RunnerReportItem[] = this.runnerItems.map((item: RunnerItemModel): RunnerReportItem => ({
      name: item.name,
      method: item.method,
      iteration: item.iteration,
      status: item.status,
      statusCode: item.statusCode,
      duration: item.duration,
      passedTests: item.passedTests,
      failedTests: item.failedTests,
      message: item.message,
      details: item.details
    }));
    const report: RunnerReportDocument = {
      format: 'nimbo.runner.v1',
      generatedAt: new Date().toISOString(),
      startedAt: this.runnerStartedAt,
      scope: this.runnerTargetName,
      environment: this.runnerEnvironmentName,
      dataFile: this.runnerRunDataFileName,
      dataRows: this.runnerRunDataRowCount,
      summary: { total: items.length, passed, failed, cancelled },
      items
    };
    try {
      const date = new Date().toISOString().substring(0, 10);
      const saved = await LocalFileExporter.saveText(`nimbo-run-${date}.json`, JSON.stringify(report, null, 2));
      if (saved) this.showToast($r('app.string.toast_exported'));
    } catch (_error) {
      this.showToast($r('app.string.toast_export_failed'));
    }
  }

  private closeRunner(): void {
    if (this.runnerRunning) this.stopRunner();
    this.hideOverlay();
  }

  private requestSeedForNode(node: CollectionNode): CollectionRequestSeed {
    let method: HttpMethod = 'GET';
    if (node.method === 'POST') method = 'POST';
    if (node.method === 'PUT') method = 'PUT';
    if (node.method === 'PATCH') method = 'PATCH';
    if (node.method === 'DELETE') method = 'DELETE';
    if (node.method === 'HEAD') method = 'HEAD';
    if (node.method === 'OPTIONS') method = 'OPTIONS';
    const opened = this.tabs.find((tab: RequestTabModel) => tab.id === node.id);
    const saved = this.savedRequests.find((item: PersistedRequestModel) => item.id === node.id);
    const request = opened ? this.idleRequest(opened.request) :
      (saved ? this.idleRequest(saved.request) : this.createRequest(method));
    let response = createEmptyResponse();
    if (opened) {
      response = opened.response;
    } else if (saved) {
      response = createEmptyResponse();
    } else if (node.id === 'get-users-request') {
      request.url = '{{DEMO_HTTP_BASE_URL}}/users';
      response = createSuccessResponse();
    } else if (node.id === 'create-user-request') {
      request.url = '{{DEMO_HTTP_BASE_URL}}/posts';
      request.activeConfigTab = 'body';
      request.bodyType = 'json';
      request.bodyText = '{\n  "title": "Nimbo",\n  "body": "HarmonyOS request",\n  "userId": 1\n}';
    } else if (node.id === 'get-posts-request') {
      request.url = '{{DEMO_HTTP_BASE_URL}}/posts';
      request.params = [
        { id: 'param-post-limit', enabled: true, key: '_limit', value: '10', description: '返回数量',
          type: 'text', secret: false }
      ];
    } else if (node.id === 'create-post-request') {
      request.url = '{{DEMO_HTTP_BASE_URL}}/posts';
      request.activeConfigTab = 'body';
      request.bodyType = 'json';
      request.bodyText = '{\n  "title": "Nimbo 示例文章",\n  "body": "来自鸿蒙电脑的 API 请求",\n  "userId": 1\n}';
    } else if (node.id === 'preview-image-request') {
      request.url = 'https://httpbin.org/image/png';
    } else if (node.id === 'download-file-request') {
      request.url = 'https://httpbin.org/bytes/1024';
    } else if (node.id === 'connection-error-request') {
      request.url = 'https://localhost:8080/api/users';
      response = createErrorResponse();
    } else if (node.id === 'large-response-request') {
      request.url = 'https://api.example.com/large';
      response = createLargeResponse();
    } else if (node.id === 'binary-response-request') {
      request.url = 'https://api.example.com/download';
      response = createBinaryResponse();
    } else if (node.id === 'websocket-echo-request') {
      request.protocol = 'websocket';
      request.url = '{{DEMO_WEBSOCKET_URL}}';
    } else if (node.id === 'sse-events-request') {
      request.protocol = 'sse';
      request.url = '{{DEMO_SSE_URL}}';
    } else if (node.id === 'openai-list-models-request') {
      request.url = '{{OPENAI_BASE_URL}}/v1/models';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{OPENAI_API_KEY}}';
    } else if (node.id === 'openai-create-response-request') {
      request.url = '{{OPENAI_BASE_URL}}/v1/responses';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{OPENAI_API_KEY}}';
      request.activeConfigTab = 'body';
      request.bodyType = 'json';
      request.bodyText = '{\n  "model": "{{OPENAI_MODEL}}",\n  "input": "用一句话介绍 Nimbo API 调试工具"\n}';
      request.headers = [{
        id: 'openai-content-type', enabled: true, key: 'Content-Type', value: 'application/json',
        description: 'JSON 请求正文', type: 'text', secret: false
      }];
      request.settings.timeoutMs = 120000;
    } else if (node.id === 'openai-stream-response-request') {
      request.protocol = 'sse';
      request.method = 'POST';
      request.url = '{{OPENAI_BASE_URL}}/v1/responses';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{OPENAI_API_KEY}}';
      request.bodyType = 'json';
      request.bodyText = '{\n  "model": "{{OPENAI_MODEL}}",\n' +
        '  "input": "用一句话介绍 Nimbo API 调试工具",\n  "stream": true\n}';
      request.headers = [{
        id: 'openai-stream-content-type', enabled: true, key: 'Content-Type', value: 'application/json',
        description: 'JSON 请求正文', type: 'text', secret: false
      }];
      request.settings.timeoutMs = 300000;
    } else if (node.id === 'deepseek-list-models-request') {
      request.url = '{{DEEPSEEK_BASE_URL}}/models';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{DEEPSEEK_API_KEY}}';
    } else if (node.id === 'deepseek-chat-request') {
      request.url = '{{DEEPSEEK_BASE_URL}}/chat/completions';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{DEEPSEEK_API_KEY}}';
      request.activeConfigTab = 'body';
      request.bodyType = 'json';
      request.bodyText = '{\n  "model": "{{DEEPSEEK_MODEL}}",\n  "messages": [\n    {\n' +
        '      "role": "system",\n      "content": "你是一名简洁、专业的开发助手。"\n    },\n' +
        '    {\n      "role": "user",\n      "content": "用一句话介绍 Nimbo API 调试工具"\n    }\n' +
        '  ],\n  "stream": false\n}';
      request.headers = [{
        id: 'deepseek-content-type', enabled: true, key: 'Content-Type', value: 'application/json',
        description: 'JSON 请求正文', type: 'text', secret: false
      }];
      request.settings.timeoutMs = 120000;
    } else if (node.id === 'deepseek-stream-chat-request') {
      request.protocol = 'sse';
      request.method = 'POST';
      request.url = '{{DEEPSEEK_BASE_URL}}/chat/completions';
      request.auth.type = 'bearer';
      request.auth.bearerToken = '{{DEEPSEEK_API_KEY}}';
      request.bodyType = 'json';
      request.bodyText = '{\n  "model": "{{DEEPSEEK_MODEL}}",\n  "messages": [\n    {\n' +
        '      "role": "system",\n      "content": "你是一名简洁、专业的开发助手。"\n    },\n' +
        '    {\n      "role": "user",\n      "content": "用一句话介绍 Nimbo API 调试工具"\n    }\n' +
        '  ],\n  "stream": true,\n  "stream_options": { "include_usage": true }\n}';
      request.headers = [{
        id: 'deepseek-stream-content-type', enabled: true, key: 'Content-Type', value: 'application/json',
        description: 'JSON 请求正文', type: 'text', secret: false
      }];
      request.settings.timeoutMs = 300000;
    }
    return { request, response };
  }

  private openCollectionRequest(node: CollectionNode): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === node.id);
    if (existing) {
      this.activeTabId = existing.id;
      this.persistLocalData();
      return;
    }
    const seed = this.requestSeedForNode(node);
    const tab: RequestTabModel = {
      id: node.id,
      name: node.name,
      method: seed.request.method,
      dirty: false,
      pinned: false,
      loading: false,
      request: seed.request,
      response: seed.response
    };
    this.tabs = [...this.tabs, tab];
    if (seed.request.protocol === 'websocket' &&
      !this.webSocketSessions.some((session: WebSocketSessionModel) => session.requestId === tab.id)) {
      this.webSocketSessions = [...this.webSocketSessions, this.emptyWebSocketSession(tab.id)];
    } else if (seed.request.protocol === 'sse' &&
      !this.sseSessions.some((session: SseSessionModel) => session.requestId === tab.id)) {
      this.sseSessions = [...this.sseSessions, this.emptySseSession(tab.id)];
    }
    this.activeTabId = tab.id;
    this.rememberRequest(tab.id, tab.name, tab.request);
    this.persistLocalData();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        GlobalToolbar({
          compact: this.isCompact(),
          phone: this.isPhone(),
          selectedEnvironmentId: this.selectedEnvironmentId,
          environments: this.environments,
          onEnvironmentChange: (id: string) => {
            this.selectedEnvironmentId = id;
            this.persistLocalData();
          },
          onSettings: () => this.selectDestination('settings'),
          onSearch: () => this.showOverlay('global-search'),
          onImport: () => this.showOverlay('import')
        })

        if (this.isPhone()) {
          Column() {
            this.mainContent()
            MobileNavigation({
              activeDestination: this.activeDestination === 'help' ? 'settings' : this.activeDestination,
              onDestinationChange: (destination: NavigationDestination) => this.selectDestination(destination)
            })
          }
          .layoutWeight(1)
          .width('100%')
        } else {
          Row() {
            PrimarySidebar({
              compact: this.isCompact(),
              activeDestination: this.activeDestination,
              onDestinationChange: (destination: NavigationDestination) => this.selectDestination(destination),
              onCreateRequest: () => this.createTab(),
              onCreateWebSocket: () => this.createWebSocketTab(),
              onCreateSse: () => this.createSseTab()
            })

            this.mainContent()
          }
          .layoutWeight(1)
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorTokens.bgApp)
      .keyboardShortcut('s', [ModifierKey.CTRL], () => {
        if (this.activeOverlay.length === 0 && this.activeTabId.length > 0) {
          this.beginSaveRequest(this.activeTabId);
        }
      })

      if (this.activeOverlay === 'create-collection') {
        CollectionNameDialog({
          title: $r('app.string.collection_create'),
          placeholder: $r('app.string.collection_name_placeholder'),
          onCancel: () => { this.pendingSaveTabId = ''; this.hideOverlay(); },
          onConfirm: (name: string) => this.createCollection(name)
        })
      }
      if (this.activeOverlay === 'global-search') {
        GlobalSearchDialog({
          items: this.globalSearchItems(),
          onCancel: () => this.hideOverlay(),
          onSelect: (item: GlobalSearchItem) => this.selectSearchItem(item)
        })
      }
      if (this.activeOverlay === 'create-folder') {
        CollectionNameDialog({
          title: $r('app.string.folder_create'),
          placeholder: $r('app.string.folder_name_placeholder'),
          onCancel: () => { this.collectionParentId = ''; this.hideOverlay(); },
          onConfirm: (name: string) => this.createFolder(name)
        })
      }
      if (this.activeOverlay === 'create-environment') {
        CollectionNameDialog({
          title: $r('app.string.environment_create'),
          placeholder: $r('app.string.environment_name_placeholder'),
          onCancel: () => this.hideOverlay(),
          onConfirm: (name: string) => this.createEnvironment(name)
        })
      }
      if (this.activeOverlay === 'collection-variables') {
        CollectionVariablesDialog({
          targetName: this.editingCollectionVariablesName,
          initialVariables: this.editingCollectionVariables,
          onCancel: () => {
            this.editingCollectionVariablesId = '';
            this.editingCollectionVariablesName = '';
            this.editingCollectionVariables = [];
            this.hideOverlay();
          },
          onConfirm: (variables: KeyValueItem[]) => this.saveCollectionVariables(variables)
        })
      }
      if (this.activeOverlay === 'delete-environment') {
        NimboDialog({
          title: $r('app.string.environment_delete_title'),
          message: $r('app.string.environment_delete_message'),
          confirmLabel: $r('app.string.action_delete'),
          dangerous: true,
          onCancel: () => { this.deletingEnvironmentId = ''; this.hideOverlay(); },
          onConfirm: () => this.deleteEnvironment()
        })
      }
      if (this.activeOverlay === 'rename-folder') {
        CollectionNameDialog({
          title: $r('app.string.folder_rename'),
          placeholder: $r('app.string.folder_name_placeholder'),
          confirmLabel: $r('app.string.action_save'),
          initialName: this.findCollectionNode(this.collections, this.renamingFolderId)?.name ?? '',
          onCancel: () => { this.renamingFolderId = ''; this.hideOverlay(); },
          onConfirm: (name: string) => this.renameFolder(name)
        })
      }
      if (this.activeOverlay === 'rename-request') {
        CollectionNameDialog({
          title: $r('app.string.request_name_placeholder'),
          placeholder: $r('app.string.request_name_placeholder'),
          confirmLabel: $r('app.string.action_save'),
          initialName: this.findCollectionNode(this.collections, this.renamingRequestId)?.name ?? '',
          onCancel: () => { this.renamingRequestId = ''; this.hideOverlay(); },
          onConfirm: (name: string) => this.renameRequest(name)
        })
      }
      if (this.activeOverlay === 'delete-collection-node') {
        NimboDialog({
          title: $r('app.string.collection_node_delete_title'),
          message: $r('app.string.collection_node_delete_message'),
          confirmLabel: $r('app.string.action_delete'),
          dangerous: true,
          onCancel: () => { this.deletingCollectionNodeId = ''; this.hideOverlay(); },
          onConfirm: () => this.deleteCollectionNode()
        })
      }
      if (this.activeOverlay === 'collection-runner') {
        CollectionRunnerDialog({
          targetName: this.runnerTargetName,
          environmentName: this.runnerEnvironmentName,
          dataFileName: this.runnerDataFileName,
          dataRowCount: this.runnerDataRowCount,
          dataColumns: this.runnerDataColumns,
          dataError: this.runnerDataError,
          items: $runnerItems,
          running: this.runnerRunning,
          onStart: (iterations: number, delayMs: number) => this.startRunner(iterations, delayMs),
          onStop: () => this.stopRunner(),
          onExport: () => this.exportRunnerReport(),
          onSelectData: () => this.selectRunnerData(),
          onClearData: () => this.clearRunnerData(),
          onClose: () => this.closeRunner()
        })
      }
      if (this.activeOverlay === 'save-request') {
        SaveRequestDialog({
          initialName: this.pendingSaveName(),
          targets: this.collectionTargets(),
          onCancel: () => { this.pendingSaveTabId = ''; this.hideOverlay(); },
          onConfirm: (name: string, targetId: string) => this.saveRequestToCollection(name, targetId)
        })
      }
      if (this.activeOverlay === 'import') {
        ApiFileImportDialog({
          onCancel: () => this.hideOverlay(),
          onImportCurl: (result: CurlImportResult) => {
            this.hideOverlay();
            this.createImportedRequest(result, 'Imported cURL');
            this.showToast($r('app.string.toast_imported'));
          },
          onImportPostman: (result: PostmanImportResult) => this.applyPostmanImport(result),
          onImportOpenApi: (result: OpenApiImportResult) => this.applyOpenApiImport(result),
          onComplete: () => { this.hideOverlay(); this.showToast($r('app.string.toast_imported')); }
        })
      }
      if (this.activeOverlay === 'clear-history') {
        NimboDialog({
          title: $r('app.string.action_clear_history'),
          message: $r('app.string.dialog_clear_history_message'),
          confirmLabel: $r('app.string.action_clear_history'),
          dangerous: true,
          onCancel: () => this.hideOverlay(),
          onConfirm: () => {
            this.lastDeletedHistory = this.historyItems;
            this.historyItems = [];
            this.hideOverlay();
            this.persistLocalData();
            this.showToast($r('app.string.toast_deleted'), true);
          }
        })
      }
      if (this.activeOverlay === 'reset-app') {
        NimboDialog({
          title: $r('app.string.reset_title'),
          message: $r('app.string.dialog_reset_message'),
          confirmLabel: $r('app.string.reset_action'),
          dangerous: true,
          onCancel: () => this.hideOverlay(),
          onConfirm: () => {
            this.applySafeDefaults();
            try {
              i18n.System.setAppPreferredLanguage('en');
            } catch (_error) {
              this.showToast($r('app.string.toast_language_failed'));
            }
            this.hideOverlay();
            this.persistLocalData();
            this.restartForLanguage();
          }
        })
      }
      if (this.activeOverlay === 'export-secrets') {
        NimboDialog({
          title: $r('app.string.export_secrets_title'),
          message: $r('app.string.dialog_export_secrets_message'),
          confirmLabel: $r('app.string.export_action'),
          dangerous: true,
          onCancel: () => this.hideOverlay(),
          onConfirm: () => {
            this.hideOverlay();
            this.exportNimbo(true);
          }
        })
      }
      if (this.toastVisible) {
        NimboToast({ message: this.toastMessage, actionVisible: this.toastActionVisible,
          onAction: () => this.undoHistoryDelete() })
          .margin({ bottom: this.isPhone() ? 72 : SpacingTokens.x5 })
      }
    }
    .width('100%')
    .height('100%')
    .focusable(true)
    .defaultFocus(true)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const measuredWidth = Number.parseFloat(newValue.width.toString());
      if (Number.isNaN(measuredWidth) || measuredWidth < 320 || WindowChromeController.isMinimized() ||
        this.layoutClass(measuredWidth) === this.layoutClass(this.windowWidth)) return;
      if (this.windowWidth >= BreakpointTokens.tablet && measuredWidth < BreakpointTokens.tablet &&
        this.activeDestination === 'collections') this.collectionDrawerOpen = true;
      if (measuredWidth >= BreakpointTokens.tablet) this.collectionDrawerOpen = false;
      this.windowWidth = measuredWidth;
    })
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyCode === 2035 &&
        event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
        if (this.activeOverlay.length === 0 && this.activeTabId.length > 0) {
          const requestId = this.activeTabId;
          setTimeout(() => this.beginSaveRequest(requestId), 0);
        }
        return true;
      }
      if (event.type === KeyType.Down && event.keyCode === 2027 &&
        event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
        if (this.activeOverlay === 'global-search') this.hideOverlay();
        else this.showOverlay('global-search');
        return true;
      }
      return false;
    })
  }
}
