import { CollectionNode, HttpMethod, NavigationDestination, RequestDraft, RequestTabModel } from '../models/ShellModels';
import { ShellState } from '../state/ShellState';
import { createEmptyRequest } from '../mock/ShellMockData';
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
      request
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
    const tab: RequestTabModel = {
      id: node.id,
      name: node.name,
      method: request.method,
      dirty: false,
      pinned: false,
      loading: false,
      request
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
          onUpdateRequest: (id: string, request: RequestDraft) => {
            this.tabs = this.tabs.map((tab: RequestTabModel) => {
              if (tab.id !== id) {
                return tab;
              }
              return {
                id: tab.id,
                name: tab.name,
                method: request.method,
                dirty: tab.dirty || this.requestContentChanged(tab.request, request),
                pinned: tab.pinned,
                loading: request.lifecycle === 'sending',
                request
              };
            });
          }
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
