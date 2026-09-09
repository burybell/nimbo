import { RequestDraft, RequestTabModel } from '../../../models/ShellModels';
import { RequestTabBar } from './RequestTabBar';
import { RequestPanel } from './RequestPanel';
import { NimboEmptyState } from '../common/NimboEmptyState';
import { NimboSplitter } from '../common/NimboSplitter';
import { ResponsePanel } from '../response/ResponsePanel';
import { ColorTokens } from '../../tokens/ColorTokens';

@Component
export struct Workspace {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  @StorageLink('workspace.splitRatio') splitRatio: number = 0.48;
  @State panelHeight: number = 600;
  onSelectTab: (id: string) => void = () => {};
  onCloseTab: (id: string) => void = () => {};
  onCreateTab: () => void = () => {};
  onUpdateRequest: (id: string, request: RequestDraft) => void = () => {};
  onPreviewLargeResponse: (id: string) => void = () => {};

  private activeIndex(): number {
    return this.tabs.findIndex((tab: RequestTabModel) => tab.id === this.activeTabId);
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

  build() {
    Column() {
      RequestTabBar({
        tabs: $tabs,
        activeTabId: $activeTabId,
        onSelect: this.onSelectTab,
        onClose: this.onCloseTab,
        onCreate: this.onCreateTab
      })

      if (this.tabs.length === 0) {
        NimboEmptyState({
          title: $r('app.string.empty_workspace_title'),
          description: $r('app.string.empty_workspace_description')
        })
          .layoutWeight(1)
      } else {
        Column() {
          RequestPanel({
            request: this.tabs[this.activeIndex()].request,
            onChange: (request: RequestDraft) => this.onUpdateRequest(this.activeTabId, request)
          })
            .height(`${Math.round(this.splitRatio * 100)}%`)

          NimboSplitter({
            ratio: this.splitRatio,
            availableHeight: this.panelHeight,
            min: 0.25,
            max: 0.75,
            onResize: (ratio: number) => {
              this.splitRatio = ratio;
            }
          })

          ResponsePanel({
            response: this.tabs[this.activeIndex()].response,
            onRetry: () => this.onUpdateRequest(this.activeTabId,
              this.requestWithLifecycle(this.tabs[this.activeIndex()].request, 'sending')),
            onPreviewLarge: () => this.onPreviewLargeResponse(this.activeTabId)
          })
            .layoutWeight(1)
        }
          .layoutWeight(1)
          .width('100%')
          .onAreaChange((_oldValue: Area, newValue: Area) => {
            const height = Number.parseFloat(newValue.height.toString());
            if (!Number.isNaN(height)) this.panelHeight = height;
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgWorkspace)
  }
}
