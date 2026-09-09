import { RequestDraft, RequestTabModel, ResponseModel } from '../../../models/ShellModels';
import { RequestTabBar } from './RequestTabBar';
import { RequestPanel } from './RequestPanel';
import { NimboEmptyState } from '../common/NimboEmptyState';
import { NimboSplitter } from '../common/NimboSplitter';
import { ResponsePanel } from '../response/ResponsePanel';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct Workspace {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  @StorageLink('workspace.splitRatio') splitRatio: number = 0.48;
  @State panelHeight: number = 600;
  @State mobilePage: string = 'request';
  @Prop phone: boolean = false;
  onSelectTab: (id: string) => void = () => {};
  onCloseTab: (id: string) => void = () => {};
  onCreateTab: () => void = () => {};
  onUpdateRequest: (id: string, request: RequestDraft) => void = () => {};
  onPreviewLargeResponse: (id: string) => void = () => {};
  onSaveBinary: (response: ResponseModel) => void = () => {};

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
      if (this.phone && this.tabs.length > 0) {
        Row({ space: SpacingTokens.x2 }) {
          Text(this.tabs[this.activeIndex()].method)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.brand600)
          Text(this.tabs[this.activeIndex()].name)
            .layoutWeight(1)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('+')
            .width(SizeTokens.controlLarge)
            .height(SizeTokens.controlLarge)
            .fontSize(20)
            .textAlign(TextAlign.Center)
            .fontColor(ColorTokens.brand500)
            .onClick(this.onCreateTab)
        }
        .width('100%')
        .height(48)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
        .backgroundColor(ColorTokens.bgSurface)
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        Row() {
          Text($r('app.string.mobile_request'))
            .layoutWeight(1)
            .height(44)
            .fontSize(13)
            .fontWeight(this.mobilePage === 'request' ? FontWeight.Medium : FontWeight.Regular)
            .textAlign(TextAlign.Center)
            .fontColor(this.mobilePage === 'request' ? ColorTokens.brand600 : ColorTokens.textSecondary)
            .border({ width: { bottom: this.mobilePage === 'request' ? 2 : 0 }, color: ColorTokens.brand500 })
            .onClick(() => { this.mobilePage = 'request'; })
          Text($r('app.string.mobile_response'))
            .layoutWeight(1)
            .height(44)
            .fontSize(13)
            .fontWeight(this.mobilePage === 'response' ? FontWeight.Medium : FontWeight.Regular)
            .textAlign(TextAlign.Center)
            .fontColor(this.mobilePage === 'response' ? ColorTokens.brand600 : ColorTokens.textSecondary)
            .border({ width: { bottom: this.mobilePage === 'response' ? 2 : 0 }, color: ColorTokens.brand500 })
            .onClick(() => { this.mobilePage = 'response'; })
        }
        .width('100%')
        .height(44)
        .backgroundColor(ColorTokens.bgSurface)
      } else if (!this.phone) {
        RequestTabBar({
          tabs: $tabs,
          activeTabId: $activeTabId,
          onSelect: this.onSelectTab,
          onClose: this.onCloseTab,
          onCreate: this.onCreateTab
        })
      }

      if (this.tabs.length === 0) {
        NimboEmptyState({
          title: $r('app.string.empty_workspace_title'),
          description: $r('app.string.empty_workspace_description')
        })
          .layoutWeight(1)
      } else if (this.phone) {
        if (this.mobilePage === 'request') {
          RequestPanel({
            request: this.tabs[this.activeIndex()].request,
            phone: true,
            onChange: (request: RequestDraft) => this.onUpdateRequest(this.activeTabId, request)
          })
          .layoutWeight(1)
        } else {
          ResponsePanel({
            response: this.tabs[this.activeIndex()].response,
            onRetry: () => this.onUpdateRequest(this.activeTabId,
              this.requestWithLifecycle(this.tabs[this.activeIndex()].request, 'sending')),
            onPreviewLarge: () => this.onPreviewLargeResponse(this.activeTabId),
            onSaveBinary: () => this.onSaveBinary(this.tabs[this.activeIndex()].response)
          })
          .layoutWeight(1)
        }
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
            onPreviewLarge: () => this.onPreviewLargeResponse(this.activeTabId),
            onSaveBinary: () => this.onSaveBinary(this.tabs[this.activeIndex()].response)
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
