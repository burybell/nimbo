import {
  CollectionNode,
  HttpMethod,
  NavigationDestination,
  RequestDraft,
  RequestTabModel,
  ResponseModel,
  ResponseStatus
} from '../models/ShellModels';
import { ShellState } from '../state/ShellState';
import {
  createBinaryResponse,
  createCancelledResponse,
  createEmptyRequest,
  createEmptyResponse,
  createErrorResponse,
  createLargeResponse,
  createSuccessResponse
} from '../mock/ShellMockData';
import { CollectionSidebar } from '../ui/components/collection/CollectionSidebar';
import { GlobalToolbar } from '../ui/components/common/GlobalToolbar';
import { PrimarySidebar } from '../ui/components/common/PrimarySidebar';
import { Workspace } from '../ui/components/request/Workspace';
import { ColorTokens } from '../ui/tokens/ColorTokens';
import { BreakpointTokens, SizeTokens } from '../ui/tokens/LayoutTokens';

@Component
export struct NimboWindow {
  @State windowWidth: number = 1440;
  @State activeDestination: NavigationDestination = 'collections';
  @State collections: CollectionNode[] = ShellState.createInitialCollections();
  @State tabs: RequestTabModel[] = ShellState.createInitialTabs();
  @State activeTabId: string = 'get-users';
  private nextTabNumber: number = 1;

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
      previous.binaryFileName !== next.binaryFileName;
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
      binaryFileName: request.binaryFileName
    };
  }

  private mockResponseForUrl(url: string): ResponseModel {
    const normalized = url.toLowerCase();
    if (normalized.includes('localhost') || normalized.includes('error')) return createErrorResponse();
    if (normalized.includes('large')) return createLargeResponse();
    if (normalized.includes('binary') || normalized.includes('download')) return createBinaryResponse();
    return createSuccessResponse();
  }

  private completeMockRequest(id: string): void {
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id || tab.request.lifecycle !== 'sending') return tab;
      return {
        id: tab.id,
        name: tab.name,
        method: tab.method,
        dirty: tab.dirty,
        pinned: tab.pinned,
        loading: false,
        request: this.requestWithLifecycle(tab.request, 'idle'),
        response: this.mockResponseForUrl(tab.request.url)
      };
    });
  }

  private updateRequest(id: string, request: RequestDraft): void {
    let shouldComplete = false;
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id) return tab;
      const started = tab.request.lifecycle !== 'sending' && request.lifecycle === 'sending';
      const cancelled = tab.request.lifecycle === 'sending' && request.lifecycle === 'idle';
      shouldComplete = started;
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
      setTimeout(() => this.completeMockRequest(id), 800);
    }
  }

  private previewLargeResponse(id: string): void {
    this.tabs = this.tabs.map((tab: RequestTabModel) => {
      if (tab.id !== id) return tab;
      const response = createSuccessResponse();
      response.size = '1.0 MB preview';
      return {
        id: tab.id,
        name: tab.name,
        method: tab.method,
        dirty: tab.dirty,
        pinned: tab.pinned,
        loading: tab.loading,
        request: tab.request,
        response
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
  }

  private closeTab(id: string): void {
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
    Column() {
      GlobalToolbar({ compact: this.isCompact() })

      Row() {
        PrimarySidebar({
          compact: this.isCompact(),
          activeDestination: this.activeDestination,
          onDestinationChange: (destination: NavigationDestination) => {
            this.activeDestination = destination;
          },
          onCreateRequest: () => this.createTab()
        })

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
          onSelectTab: (id: string) => {
            this.activeTabId = id;
          },
          onCloseTab: (id: string) => this.closeTab(id),
          onCreateTab: () => this.createTab(),
          onUpdateRequest: (id: string, request: RequestDraft) => this.updateRequest(id, request),
          onPreviewLargeResponse: (id: string) => this.previewLargeResponse(id)
        })
          .layoutWeight(1)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgApp)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const measuredWidth = Number.parseFloat(newValue.width.toString());
      if (!Number.isNaN(measuredWidth)) {
        this.windowWidth = measuredWidth;
      }
    })
  }
}
