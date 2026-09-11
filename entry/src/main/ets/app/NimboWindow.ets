import {
  CollectionNode,
  ExtractionResult,
  ExtractionRule,
  ExtractionStatus,
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
import { CurlCodec, CurlImportResult } from '../services/CurlCodec';
import { PostmanImportResult } from '../services/PostmanCodec';
import { OpenApiImportResult } from '../services/OpenApiCodec';
import { LocalFileExporter } from '../services/LocalFileExporter';
import { MediaPreviewStore } from '../services/MediaPreviewStore';
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
import { DEMO_HISTORY } from '../mock/SupportingMockData';
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
  private nextTabNumber: number = 1;
  private nextCollectionNodeNumber: number = 1;
  private requestController: RequestController = new RequestController();
  private requestPersistenceTimer: number = -1;
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
        subtitle: $r('app.string.search_command'), keywords: 'settings preferences 设置 偏好', icon: '⚙' }
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
            method: saved.method, expanded: false, children: [] });
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

  private createRequestInCollection(parentId: string): void {
    const number = this.nextTabNumber;
    const id = `untitled-${number}`;
    const name = this.preferences.language === 'zh' ? `未命名请求 ${number}` : `Untitled Request ${number}`;
    const request = this.createRequest();
    const requestNode: CollectionNode = {
      id, type: 'request', name, method: 'GET', expanded: false, children: []
    };
    this.collections = this.updateCollectionNode(this.collections, parentId, (node: CollectionNode) => ({
      id: node.id, type: node.type, name: node.name, method: node.method,
      expanded: true, children: [...node.children, requestNode]
    }));
    this.tabs = [...this.tabs, {
      id, name, method: 'GET', dirty: false, pinned: false, loading: false,
      request, response: createEmptyResponse()
    }];
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

  private renameFolder(name: string): void {
    const id = this.renamingFolderId;
    if (id.length === 0) return;
    this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
      id: node.id, type: node.type, name, method: node.method,
      expanded: node.expanded, children: node.children
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
    this.collections = this.updateCollectionNode(this.collections, id, (node: CollectionNode) => ({
      id: node.id, type: node.type, name, method: node.method,
      expanded: node.expanded, children: node.children
    }));
    this.savedRequests = this.savedRequests.map((item: PersistedRequestModel) => item.id === id ? {
      id: item.id, name, method: item.method, request: item.request
    } : item);
    this.tabs = this.tabs.map((tab: RequestTabModel) => tab.id === id ? {
      id: tab.id, name, method: tab.method, dirty: tab.dirty,
      pinned: tab.pinned, loading: tab.loading, request: tab.request, response: tab.response
    } : tab);
    this.renamingRequestId = '';
    this.hideOverlay();
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
          expanded: node.expanded, children
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
      id, type: 'request', name, method: request.method, expanded: false, children: []
    };
    this.collections = this.insertAfterCollectionNode(this.collections, node.id, duplicated);
    this.tabs = [...this.tabs, {
      id, name, method: request.method, dirty: false, pinned: false, loading: false,
      request, response: createEmptyResponse()
    }];
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
          expanded: node.expanded, children });
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
    });
    const activeIndex = this.tabs.findIndex((tab: RequestTabModel) => tab.id === this.activeTabId);
    this.collections = this.removeCollectionNode(this.collections, node.id);
    this.savedRequests = this.savedRequests.filter((item: PersistedRequestModel) =>
      !requestIds.includes(item.id));
    this.tabs = this.tabs.filter((tab: RequestTabModel) => !requestIds.includes(tab.id));
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
      previous.binaryFileName !== next.binaryFileName || previous.extractionRules !== next.extractionRules ||
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
      protocol: response.protocol,
      error: response.error,
      previewAvailable: response.previewAvailable,
      extractionResults: response.extractionResults
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
      extractionRules: request.extractionRules,
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
      protocol: response.protocol, error: response.error, previewAvailable: response.previewAvailable,
      extractionResults: results
    };
  }

  private activeEnvironment(): EnvironmentModel {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === this.selectedEnvironmentId);
    if (environment) return environment;
    return { id: '', name: 'No Environment', kind: 'development', variables: [] };
  }

  private async sendRealRequest(id: string, request: RequestDraft, serial: number): Promise<void> {
    let response = await this.requestController.send(id, request, this.activeEnvironment());
    if (this.requestSerials.get(id) !== serial) return;
    if (response.status === 'binary' && response.mediaKind !== 'none' && response.binaryBody.byteLength > 0) {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const mediaUri = await MediaPreviewStore.create(context.cacheDir, id,
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
          protocol: response.protocol,
          error: response.error,
          previewAvailable: true,
          extractionResults: response.extractionResults
        };
      } catch (_error) {
        // Fall back to the existing binary download view if preview preparation fails.
      }
    }
    if (this.requestSerials.get(id) !== serial) return;
    response = this.applyResponseExtractions(request, response);
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
        protocol: response.protocol,
        error: response.error,
        previewAvailable: false,
        extractionResults: response.extractionResults
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
              borderedEnd: false,
              nodes: $collections,
              onOpenRequest: (node: CollectionNode) => this.openCollectionRequest(node),
              onToggleNode: (id: string) => this.toggleCollectionNode(id),
              onCreateCollection: () => this.beginCreateCollection(),
              onCreateRequest: (parentId: string) => this.createRequestInCollection(parentId),
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId),
              onRenameFolder: (node: CollectionNode) => this.beginRenameFolder(node),
              onRenameRequest: (node: CollectionNode) => this.beginRenameRequest(node),
              onDuplicateRequest: (node: CollectionNode) => this.duplicateCollectionRequest(node),
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
            onSelectTab: (id: string) => {
              this.activeTabId = id;
              this.persistLocalData();
            },
            onCloseTab: (id: string) => this.closeTab(id),
            onCreateTab: () => this.createTab(),
            onUpdateRequest: (id: string, request: RequestDraft) => this.updateRequest(id, request),
            onSaveRequest: (id: string) => this.beginSaveRequest(id),
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
              onCreateFolder: (parentId: string) => this.beginCreateFolder(parentId),
              onRenameFolder: (node: CollectionNode) => this.beginRenameFolder(node),
              onRenameRequest: (node: CollectionNode) => this.beginRenameRequest(node),
              onDuplicateRequest: (node: CollectionNode) => this.duplicateCollectionRequest(node),
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
    } else if (node.id === 'get-posts-request') {
      request.url = 'https://jsonplaceholder.typicode.com/posts';
      request.params = [
        { id: 'param-post-limit', enabled: true, key: '_limit', value: '10', description: '返回数量',
          type: 'text', secret: false }
      ];
    } else if (node.id === 'create-post-request') {
      request.url = 'https://jsonplaceholder.typicode.com/posts';
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
              onCreateRequest: () => this.createTab()
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
      if (!Number.isNaN(measuredWidth)) {
        if (this.windowWidth >= BreakpointTokens.tablet && measuredWidth < BreakpointTokens.tablet &&
          this.activeDestination === 'collections') this.collectionDrawerOpen = true;
        if (measuredWidth >= BreakpointTokens.tablet) this.collectionDrawerOpen = false;
        this.windowWidth = measuredWidth;
      }
    })
    .onKeyEvent((event: KeyEvent) => {
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
