import { EnvironmentModel, RequestDraft, RequestTabModel, ResponseModel } from '../../../models/ShellModels';
import { RequestTabBar } from './RequestTabBar';
import { RequestPanel } from './RequestPanel';
import { NimboEmptyState } from '../common/NimboEmptyState';
import { NimboSplitter } from '../common/NimboSplitter';
import { ResponsePanel } from '../response/ResponsePanel';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct Workspace {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  @StorageLink('workspace.splitRatio') splitRatio: number = 0.48;
  @State panelHeight: number = 600;
  @State mobilePage: string = 'request';
  @State contentOpacity: number = 1;
  @Prop phone: boolean = false;
  @Prop environments: EnvironmentModel[] = [];
  onSelectTab: (id: string) => void = () => {};
  onCloseTab: (id: string) => void = () => {};
  onCreateTab: () => void = () => {};
  onUpdateRequest: (id: string, request: RequestDraft) => void = () => {};
  onSaveRequest: (id: string) => void = () => {};
  onPreviewLargeResponse: (id: string) => void = () => {};
  onSaveBinary: (response: ResponseModel) => void = () => {};
  onCopyResponseBody: (response: ResponseModel) => void = () => {};
  onDownloadResponseBody: (response: ResponseModel) => void = () => {};
  private tabSwitchSerial: number = 0;

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
      extractionRules: request.extractionRules,
      settings: request.settings
    };
  }

  private selectTab(id: string): void {
    if (id === this.activeTabId) return;
    this.tabSwitchSerial += 1;
    const serial = this.tabSwitchSerial;
    this.getUIContext().animateTo({ duration: MotionTokens.hover, curve: MotionTokens.exitCurve }, () => {
      this.contentOpacity = 0.72;
    });
    setTimeout(() => {
      if (serial !== this.tabSwitchSerial) return;
      if (!this.tabs.some((tab: RequestTabModel) => tab.id === id)) {
        this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }, () => {
          this.contentOpacity = 1;
        });
        return;
      }
      this.onSelectTab(id);
      this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }, () => {
        this.contentOpacity = 1;
      });
    }, MotionTokens.hover);
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
          onSelect: (id: string) => this.selectTab(id),
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
            response: this.tabs[this.activeIndex()].response,
            environments: this.environments,
            phone: true,
            onChange: (request: RequestDraft) => this.onUpdateRequest(this.activeTabId, request),
            onSave: () => this.onSaveRequest(this.activeTabId)
          })
          .layoutWeight(1)
          .opacity(this.contentOpacity)
        } else {
          ResponsePanel({
            response: this.tabs[this.activeIndex()].response,
            onRetry: () => this.onUpdateRequest(this.activeTabId,
              this.requestWithLifecycle(this.tabs[this.activeIndex()].request, 'sending')),
            onPreviewLarge: () => this.onPreviewLargeResponse(this.activeTabId),
            onSaveBinary: () => this.onSaveBinary(this.tabs[this.activeIndex()].response),
            onCopyBody: () => this.onCopyResponseBody(this.tabs[this.activeIndex()].response),
            onDownloadBody: () => this.onDownloadResponseBody(this.tabs[this.activeIndex()].response)
          })
          .layoutWeight(1)
          .opacity(this.contentOpacity)
        }
      } else {
        Column() {
          RequestPanel({
            request: this.tabs[this.activeIndex()].request,
            response: this.tabs[this.activeIndex()].response,
            environments: this.environments,
            onChange: (request: RequestDraft) => this.onUpdateRequest(this.activeTabId, request),
            onSave: () => this.onSaveRequest(this.activeTabId)
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
            onSaveBinary: () => this.onSaveBinary(this.tabs[this.activeIndex()].response),
            onCopyBody: () => this.onCopyResponseBody(this.tabs[this.activeIndex()].response),
            onDownloadBody: () => this.onDownloadResponseBody(this.tabs[this.activeIndex()].response)
          })
            .layoutWeight(1)
        }
          .layoutWeight(1)
          .width('100%')
          .opacity(this.contentOpacity)
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
