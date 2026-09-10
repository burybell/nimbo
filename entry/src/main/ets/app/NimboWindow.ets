import {
  CollectionNode,
  HttpMethod,
  NavigationDestination,
  RequestDraft,
  RequestTabModel,
  ResponseModel,
  ResponseStatus
} from '../models/ShellModels';
import { EnvironmentModel, HistoryItemModel, KeyValueItem } from '../models/ShellModels';
import {
  AppPreferencesModel,
  NimboTheme,
  PersistedAppState,
  PersistedRequestModel,
  PersistedTabModel
} from '../models/PersistenceModels';
import { ShellState } from '../state/ShellState';
import { createDefaultPreferences } from '../state/AppDefaults';
import { LocalDataStore } from '../services/LocalDataStore';
import { CurlCodec, CurlImportResult } from '../services/CurlCodec';
import { PostmanImportResult } from '../services/PostmanCodec';
import { LocalFileExporter } from '../services/LocalFileExporter';
import { NimboExportCodec } from '../services/NimboExportCodec';
import { RequestController } from '../controller/RequestController';
import {
  createBinaryResponse,
  createCancelledResponse,
  createEmptyRequest,
  createEmptyResponse,
  createErrorResponse,
  createLargeResponse,
  createSuccessResponse
} from '../mock/ShellMockData';
import { DEMO_ENVIRONMENTS, DEMO_HISTORY } from '../mock/SupportingMockData';
import { CollectionSidebar } from '../ui/components/collection/CollectionSidebar';
import { CollectionNameDialog } from '../ui/components/collection/CollectionNameDialog';
import { CollectionTarget, SaveRequestDialog } from '../ui/components/collection/SaveRequestDialog';
import { GlobalToolbar } from '../ui/components/common/GlobalToolbar';
import { MobileNavigation } from '../ui/components/common/MobileNavigation';
import { NimboDialog } from '../ui/components/common/NimboDialog';
import { NimboToast } from '../ui/components/common/NimboToast';
import { PrimarySidebar } from '../ui/components/common/PrimarySidebar';
import { EnvironmentPage } from '../ui/components/environment/EnvironmentPage';
import { HistoryPage } from '../ui/components/history/HistoryPage';
import { ImportCurlDialog } from '../ui/components/importer/ImportCurlDialog';
import { PostmanImportDialog } from '../ui/components/importer/PostmanImportDialog';
import { Workspace } from '../ui/components/request/Workspace';
import { SettingsPage } from '../ui/components/settings/SettingsPage';
import { ColorTokens } from '../ui/tokens/ColorTokens';
import { BreakpointTokens, SizeTokens, SpacingTokens } from '../ui/tokens/LayoutTokens';
import { MotionTokens } from '../ui/tokens/MotionTokens';
import { i18n } from '@kit.LocalizationKit';
import { common, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';

@Component
export struct NimboWindow {
  @StorageLink('nimbo.localData') persistedData: string = '';
  @State windowWidth: number = 1440;
  @State activeDestination: NavigationDestination = 'collections';
  @State collections: CollectionNode[] = ShellState.createInitialCollections();
  @State tabs: RequestTabModel[] = ShellState.createInitialTabs();
  @State activeTabId: string = 'get-users';
  @State environments: EnvironmentModel[] = DEMO_ENVIRONMENTS;
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
  private nextTabNumber: number = 1;
  private nextCollectionNodeNumber: number = 1;
  private requestController: RequestController = new RequestController();
  private requestSerials: Map<string, number> = new Map<string, number>();
  private stateReady: boolean = false;

  aboutToAppear(): void {
    this.restoreLocalData();
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
      duration: item.duration
    };
  }

  private restoreLocalData(): void {
    const state = LocalDataStore.decode(this.persistedData);
    if (state) {
      this.collections = state.collections;
      this.savedRequests = state.requests;
      this.restoreNextTabNumber();
      this.environments = state.environments;
      this.selectedEnvironmentId = state.activeEnvironmentId;
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
    this.environments = [];
    this.historyItems = [];
    this.lastDeletedHistory = [];
    this.selectedEnvironmentId = '';
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
    this.persistedData = LocalDataStore.encode(this.persistedState());
  }

  private isCompact(): boolean {
    return this.windowWidth < BreakpointTokens.desktop;
  }

  private isPhone(): boolean {
    return this.windowWidth < BreakpointTokens.tablet;
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
    return this.isCompact() ? SizeTokens.collectionSidebarCompactWidth : SizeTokens.collectionSidebarWidth;
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
        expanded: node.expanded, children };
    });
    return changed ? updated : nodes;
  }

  private toggleCollectionNode(id: string): void {
    this.animateState(() => {
      this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
        id: node.id, type: node.type, name: node.name, method: node.method,
        expanded: !node.expanded, children: node.children
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
      expanded: true, children: []
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
      id: this.newCollectionNodeId('folder'), type: 'folder', name, expanded: true, children: []
    };
    this.collections = this.updateCollectionNode(this.collections, parentId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, children: [...node.children, folder]
    }));
    this.collectionParentId = '';
    this.hideOverlay();
    this.persistLocalData();
    this.showToast($r('app.string.toast_folder_created'));
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
      id, type: 'request', name, method: tab.request.method, expanded: false, children: []
    };
    this.collections = this.updateCollectionNode(this.collections, targetId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, children: [...node.children, requestNode]
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
      previous.binaryFileName !== next.binaryFileName || previous.settings !== next.settings;
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
      contentType: response.contentType,
      size: response.size,
      duration: response.duration,
      protocol: response.protocol,
      error: response.error,
      previewAvailable: response.previewAvailable
    };
  }

  private requestWithLifecycle(request: RequestDraft, lifecycle: 'idle' | 'sending'): RequestDraft {
    return {
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
      settings: request.settings
    };
  }

  private applyRealResponse(id: string, response: ResponseModel): void {
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
      const now = new Date();
      const hours = now.getHours().toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      this.historyItems = [{
        id: `history-${Date.now()}`,
        group: 'Today',
        createdAt: Date.now(),
        time: `${hours}:${minutes}`,
        method: completed.request.method,
        url: completed.request.url,
        status: response.statusCode,
        duration: response.duration.length > 0 ? response.duration : '—'
      }, ...this.historyItems];
    }
    this.persistLocalData();
  }

  private activeEnvironment(): EnvironmentModel {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === this.selectedEnvironmentId);
    if (environment) return environment;
    return { id: '', name: 'No Environment', kind: 'development', variables: [] };
  }

  private async sendRealRequest(id: string, request: RequestDraft, serial: number): Promise<void> {
    const response = await this.requestController.send(id, request, this.activeEnvironment());
    if (this.requestSerials.get(id) !== serial) return;
    this.applyRealResponse(id, response);
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
        id: node.id, type: node.type, name: node.name, method: current.request.method,
        expanded: node.expanded, children: node.children
      }));
    }
    this.persistLocalData();
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
        contentType: response.contentType,
        size: `${response.size} · 1.0 MB preview`,
        duration: response.duration,
        protocol: response.protocol,
        error: response.error,
        previewAvailable: false
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
      return { id: environment.id, name: environment.name, kind: environment.kind, variables };
    });
    this.persistLocalData();
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

  private updatePreferences(preferences: AppPreferencesModel): void {
    const languageChanged = this.preferences.language !== preferences.language;
    const themeChanged = this.preferences.theme !== preferences.theme;
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

  private openHistoryItem(item: HistoryItemModel): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === item.id);
    if (existing) {
      this.activeTabId = existing.id;
    } else {
      const request = this.createRequest(item.method);
      request.url = item.url;
      this.tabs = [...this.tabs, {
        id: item.id,
        name: `${item.method} Request`,
        method: item.method,
        dirty: false,
        pinned: false,
        loading: false,
        request,
        response: createEmptyResponse()
      }];
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
    if (asCurl) {
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
    return 'bin';
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
        onReset: () => this.showOverlay('reset-app')
      })
      .layoutWeight(1)
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    } else {
      Stack({ alignContent: Alignment.TopStart }) {
        Row() {
          if (this.showCollectionSidebar()) {
            CollectionSidebar({
              widthValue: this.collectionWidth(),
              nodes: $collections,
              onOpenRequest: (node: CollectionNode) => this.openCollectionRequest(node),
              onToggleNode: (id: string) => this.toggleCollectionNode(id),
              onCreateCollection: () => this.beginCreateCollection(),
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId)
            })
          }

          Workspace({
            tabs: $tabs,
            activeTabId: $activeTabId,
            phone: this.isPhone(),
            onSelectTab: (id: string) => {
              this.activeTabId = id;
              this.persistLocalData();
            },
            onCloseTab: (id: string) => this.closeTab(id),
            onCreateTab: () => this.createTab(),
            onUpdateRequest: (id: string, request: RequestDraft) => this.updateRequest(id, request),
            onSaveRequest: (id: string) => this.beginSaveRequest(id),
            onPreviewLargeResponse: (id: string) => this.previewLargeResponse(id),
            onSaveBinary: (response: ResponseModel) => this.saveBinaryResponse(response)
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
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId),
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

  private openCollectionRequest(node: CollectionNode): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === node.id);
    if (existing) {
      this.activeTabId = existing.id;
      this.persistLocalData();
      return;
    }
    let method: HttpMethod = 'GET';
    if (node.method === 'POST') method = 'POST';
    if (node.method === 'PUT') method = 'PUT';
    if (node.method === 'PATCH') method = 'PATCH';
    if (node.method === 'DELETE') method = 'DELETE';
    if (node.method === 'HEAD') method = 'HEAD';
    if (node.method === 'OPTIONS') method = 'OPTIONS';
    const saved = this.savedRequests.find((item: PersistedRequestModel) => item.id === node.id);
    const request = saved ? this.idleRequest(saved.request) : this.createRequest(method);
    let response = createEmptyResponse();
    if (saved) {
      response = createEmptyResponse();
    } else if (node.id === 'get-users-request') {
      request.url = 'https://jsonplaceholder.typicode.com/users';
      response = createSuccessResponse();
    } else if (node.id === 'create-user-request') {
      request.url = 'https://jsonplaceholder.typicode.com/posts';
      request.activeConfigTab = 'body';
      request.bodyType = 'json';
      request.bodyText = '{\n  "title": "Nimbo",\n  "body": "HarmonyOS request",\n  "userId": 1\n}';
    } else if (node.id === 'connection-error-request') {
      request.url = 'https://localhost:8080/api/users';
      response = createErrorResponse();
    } else if (node.id === 'large-response-request') {
      request.url = 'https://api.example.com/large';
      response = createLargeResponse();
    } else if (node.id === 'binary-response-request') {
      request.url = 'https://api.example.com/download';
      response = createBinaryResponse();
    }
    const tab: RequestTabModel = {
      id: node.id,
      name: node.name,
      method: request.method,
      dirty: false,
      pinned: false,
      loading: false,
      request,
      response
    };
    this.tabs = [...this.tabs, tab];
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
          onEnvironmentChange: (id: string) => {
            this.selectedEnvironmentId = id;
            this.persistLocalData();
          },
          onSettings: () => this.selectDestination('settings')
        })

        if (this.isPhone()) {
          Column() {
            this.mainContent()
            MobileNavigation({
              activeDestination: this.activeDestination,
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
              onImportCurl: () => this.showOverlay('curl'),
              onImportPostman: () => this.showOverlay('postman')
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

      if (this.activeOverlay === 'create-collection') {
        CollectionNameDialog({
          title: $r('app.string.collection_create'),
          placeholder: $r('app.string.collection_name_placeholder'),
          onCancel: () => { this.pendingSaveTabId = ''; this.hideOverlay(); },
          onConfirm: (name: string) => this.createCollection(name)
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
      if (this.activeOverlay === 'save-request') {
        SaveRequestDialog({
          initialName: this.pendingSaveName(),
          targets: this.collectionTargets(),
          onCancel: () => { this.pendingSaveTabId = ''; this.hideOverlay(); },
          onConfirm: (name: string, targetId: string) => this.saveRequestToCollection(name, targetId)
        })
      }
      if (this.activeOverlay === 'curl') {
        ImportCurlDialog({
          onCancel: () => this.hideOverlay(),
          onImport: (result: CurlImportResult) => {
            this.hideOverlay();
            this.createImportedRequest(result, 'Imported cURL');
            this.showToast($r('app.string.toast_imported'));
          }
        })
      }
      if (this.activeOverlay === 'postman') {
        PostmanImportDialog({
          onCancel: () => this.hideOverlay(),
          onImport: (result: PostmanImportResult) => this.applyPostmanImport(result),
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
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const measuredWidth = Number.parseFloat(newValue.width.toString());
      if (!Number.isNaN(measuredWidth)) {
        if (this.windowWidth >= BreakpointTokens.tablet && measuredWidth < BreakpointTokens.tablet &&
          this.activeDestination === 'collections') this.collectionDrawerOpen = true;
        if (measuredWidth >= BreakpointTokens.tablet) this.collectionDrawerOpen = false;
        this.windowWidth = measuredWidth;
      }
    })
  }
}
