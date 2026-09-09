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
import { ShellState } from '../state/ShellState';
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
import { GlobalToolbar } from '../ui/components/common/GlobalToolbar';
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

@Component
export struct NimboWindow {
  @State windowWidth: number = 1440;
  @State activeDestination: NavigationDestination = 'collections';
  @State collections: CollectionNode[] = ShellState.createInitialCollections();
  @State tabs: RequestTabModel[] = ShellState.createInitialTabs();
  @State activeTabId: string = 'get-users';
  @State environments: EnvironmentModel[] = DEMO_ENVIRONMENTS;
  @State historyItems: HistoryItemModel[] = DEMO_HISTORY;
  @State activeOverlay: string = '';
  @State toastMessage: string = '';
  @State lastDeletedHistory: HistoryItemModel[] = [];
  @State selectedEnvironmentId: string = 'development';
  private nextTabNumber: number = 1;
  private requestController: RequestController = new RequestController();
  private requestSerials: Map<string, number> = new Map<string, number>();

  private isCompact(): boolean {
    return this.windowWidth < BreakpointTokens.desktop;
  }

  private collectionWidth(): number {
    return this.isCompact() ? SizeTokens.collectionSidebarCompactWidth : SizeTokens.collectionSidebarWidth;
  }

  private showCollectionSidebar(): boolean {
    return this.activeDestination === 'collections' && this.windowWidth >= BreakpointTokens.compact;
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
    if (completedRequest && response.status !== 'cancelled') {
      const completed = completedRequest as RequestTabModel;
      const now = new Date();
      const hours = now.getHours().toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      this.historyItems = [{
        id: `history-${Date.now()}`,
        group: 'Today',
        time: `${hours}:${minutes}`,
        method: completed.request.method,
        url: completed.request.url,
        status: response.statusCode,
        duration: response.duration.length > 0 ? response.duration : '—'
      }, ...this.historyItems];
    }
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
        dirty: tab.dirty || this.requestContentChanged(tab.request, request),
        pinned: tab.pinned,
        loading: request.lifecycle === 'sending',
        request,
        response: started ? this.responseWithStatus(tab.response, 'sending') :
          (cancelled ? createCancelledResponse() : tab.response)
      };
    });
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
    const request = createEmptyRequest();
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
    this.activeDestination = 'workspace';
  }

  private showToast(message: string): void {
    this.toastMessage = message;
    setTimeout(() => {
      if (this.toastMessage === message) this.toastMessage = '';
    }, 1800);
  }

  private updateEnvironment(id: string, variables: KeyValueItem[]): void {
    this.environments = this.environments.map((environment: EnvironmentModel) => {
      if (environment.id !== id) return environment;
      return { id: environment.id, name: environment.name, kind: environment.kind, variables };
    });
  }

  private createImportedRequest(method: HttpMethod, url: string, name: string): void {
    const id = `imported-${Date.now()}`;
    const request = createEmptyRequest(method);
    request.url = url;
    this.tabs = [...this.tabs, {
      id,
      name,
      method,
      dirty: true,
      pinned: false,
      loading: false,
      request,
      response: createEmptyResponse()
    }];
    this.activeTabId = id;
    this.activeDestination = 'workspace';
  }

  private openHistoryItem(item: HistoryItemModel): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === item.id);
    if (existing) {
      this.activeTabId = existing.id;
    } else {
      const request = createEmptyRequest(item.method);
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
    this.activeDestination = 'workspace';
  }

  private deleteHistoryItem(id: string): void {
    this.lastDeletedHistory = this.historyItems.filter((item: HistoryItemModel) => item.id === id);
    this.historyItems = this.historyItems.filter((item: HistoryItemModel) => item.id !== id);
    this.showToast('Deleted — Undo');
  }

  private undoHistoryDelete(): void {
    if (this.lastDeletedHistory.length === 0) return;
    this.historyItems = [...this.lastDeletedHistory, ...this.historyItems];
    this.lastDeletedHistory = [];
    this.toastMessage = '';
  }

  @Builder
  mainContent() {
    if (this.activeDestination === 'environments') {
      EnvironmentPage({
        environments: this.environments,
        onChange: (id: string, variables: KeyValueItem[]) => this.updateEnvironment(id, variables),
        onSaved: () => this.showToast('Saved')
      })
      .layoutWeight(1)
    } else if (this.activeDestination === 'history') {
      HistoryPage({
        items: this.historyItems,
        onOpen: (item: HistoryItemModel) => this.openHistoryItem(item),
        onCopy: (message: string) => this.showToast(message),
        onDelete: (id: string) => this.deleteHistoryItem(id),
        onClear: () => { this.activeOverlay = 'clear-history'; }
      })
      .layoutWeight(1)
    } else if (this.activeDestination === 'settings') {
      SettingsPage({
        onSaved: () => this.showToast('Saved'),
        onReset: () => { this.activeOverlay = 'reset-app'; }
      })
      .layoutWeight(1)
    } else {
      if (this.showCollectionSidebar()) {
        CollectionSidebar({
          widthValue: this.collectionWidth(),
          nodes: $collections,
          onOpenRequest: (node: CollectionNode) => this.openCollectionRequest(node)
        })
      }

      Workspace({
        tabs: $tabs,
        activeTabId: $activeTabId,
        onSelectTab: (id: string) => { this.activeTabId = id; },
        onCloseTab: (id: string) => this.closeTab(id),
        onCreateTab: () => this.createTab(),
        onUpdateRequest: (id: string, request: RequestDraft) => this.updateRequest(id, request),
        onPreviewLargeResponse: (id: string) => this.previewLargeResponse(id)
      })
      .layoutWeight(1)
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
  }

  private openCollectionRequest(node: CollectionNode): void {
    const existing = this.tabs.find((tab: RequestTabModel) => tab.id === node.id);
    if (existing) {
      this.activeTabId = existing.id;
      return;
    }
    let method: HttpMethod = 'GET';
    if (node.method === 'POST') method = 'POST';
    if (node.method === 'PUT') method = 'PUT';
    if (node.method === 'PATCH') method = 'PATCH';
    if (node.method === 'DELETE') method = 'DELETE';
    if (node.method === 'HEAD') method = 'HEAD';
    if (node.method === 'OPTIONS') method = 'OPTIONS';
    const request = createEmptyRequest(method);
    let response = createEmptyResponse();
    if (node.id === 'get-users-request') {
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
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        GlobalToolbar({
          compact: this.isCompact(),
          selectedEnvironmentId: this.selectedEnvironmentId,
          onEnvironmentChange: (id: string) => { this.selectedEnvironmentId = id; },
          onSettings: () => { this.activeDestination = 'settings'; }
        })

        Row() {
          PrimarySidebar({
            compact: this.isCompact(),
            activeDestination: this.activeDestination,
            onDestinationChange: (destination: NavigationDestination) => { this.activeDestination = destination; },
            onCreateRequest: () => this.createTab(),
            onImportCurl: () => { this.activeOverlay = 'curl'; },
            onImportPostman: () => { this.activeOverlay = 'postman'; }
          })

          this.mainContent()
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorTokens.bgApp)

      if (this.activeOverlay === 'curl') {
        ImportCurlDialog({
          onCancel: () => { this.activeOverlay = ''; },
          onImport: (method: HttpMethod, url: string) => {
            this.activeOverlay = '';
            this.createImportedRequest(method, url, 'Imported cURL');
            this.showToast('Imported');
          }
        })
      }
      if (this.activeOverlay === 'postman') {
        PostmanImportDialog({
          onCancel: () => { this.activeOverlay = ''; },
          onComplete: () => { this.activeOverlay = ''; this.showToast('Imported'); }
        })
      }
      if (this.activeOverlay === 'clear-history') {
        NimboDialog({
          title: 'Clear History',
          message: 'Delete all local request history? This action can be undone briefly.',
          confirmLabel: 'Clear History',
          dangerous: true,
          onCancel: () => { this.activeOverlay = ''; },
          onConfirm: () => {
            this.lastDeletedHistory = this.historyItems;
            this.historyItems = [];
            this.activeOverlay = '';
            this.showToast('Deleted — Undo');
          }
        })
      }
      if (this.activeOverlay === 'reset-app') {
        NimboDialog({
          title: 'Reset Nimbo',
          message: 'Reset local demo data and settings to their defaults?',
          confirmLabel: 'Reset App',
          dangerous: true,
          onCancel: () => { this.activeOverlay = ''; },
          onConfirm: () => {
            this.environments = DEMO_ENVIRONMENTS;
            this.historyItems = DEMO_HISTORY;
            this.activeOverlay = '';
            this.showToast('Saved');
          }
        })
      }
      if (this.toastMessage.length > 0) {
        NimboToast({ message: this.toastMessage, onAction: () => this.undoHistoryDelete() })
          .margin({ bottom: SpacingTokens.x5 })
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const measuredWidth = Number.parseFloat(newValue.width.toString());
      if (!Number.isNaN(measuredWidth)) {
        this.windowWidth = measuredWidth;
      }
    })
  }
}
