import { AuthConfig, EnvironmentModel, KeyValueItem, RequestDraft, RequestTabModel, ResponseErrorModel,
  ResponseModel, SseSessionModel, WebSocketSessionModel } from '../../../models/ShellModels';
import { RequestTabBar } from './RequestTabBar';
import { RequestPanel } from './RequestPanel';
import { NimboEmptyState } from '../common/NimboEmptyState';
import { NimboSplitter } from '../common/NimboSplitter';
import { ResponsePanel } from '../response/ResponsePanel';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';
import { WebSocketPanel } from './WebSocketPanel';
import { SsePanel } from './SsePanel';

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
  @Prop selectedEnvironmentId: string = '';
  @Prop webSocketSession: WebSocketSessionModel = {
    requestId: '', status: 'disconnected', composer: '', messages: [], errorCode: '', errorMessage: ''
  };
  @Prop sseSession: SseSessionModel = {
    requestId: '', status: 'disconnected', events: [], errorCode: '', errorMessage: '',
    statusCode: 0, contentType: ''
  };
  onSaveRequest: (id: string) => void = () => {};
  onSelectTab: (id: string) => void = () => {};
  onCloseTab: (id: string) => void = () => {};
  onCloseAllTabs: () => void = () => {};
  onCreateTab: () => void = () => {};
  onRenameRequest: (id: string, name: string) => void = () => {};
  onUpdateRequest: (id: string, request: RequestDraft) => void = () => {};
  onPreviewLargeResponse: (id: string) => void = () => {};
  onSaveBinary: (response: ResponseModel) => void = () => {};
  onCopyResponseBody: (response: ResponseModel) => void = () => {};
  onDownloadResponseBody: (response: ResponseModel) => void = () => {};
  onCopyGeneratedCode: (value: string) => void = () => {};
  onCopyErrorDiagnostic: (error: ResponseErrorModel) => void = () => {};
  onWebSocketUrlChange: (id: string, value: string) => void = () => {};
  onWebSocketConnect: (id: string) => void = () => {};
  onWebSocketDisconnect: (id: string) => void = () => {};
  onWebSocketComposerChange: (id: string, value: string) => void = () => {};
  onWebSocketSend: (id: string) => void = () => {};
  onWebSocketClear: (id: string) => void = () => {};
  onWebSocketCopy: (id: string) => void = () => {};
  onWebSocketExport: (id: string) => void = () => {};
  onSseConnect: (id: string) => void = () => {};
  onSseStop: (id: string) => void = () => {};
  onSseClear: (id: string) => void = () => {};
  onSseCopy: (id: string) => void = () => {};
  onSseExport: (id: string) => void = () => {};
  private tabSwitchSerial: number = 0;

  private activeIndex(): number {
    return this.tabs.findIndex((tab: RequestTabModel) => tab.id === this.activeTabId);
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

  private webSocketRequest(request: RequestDraft, url: string, headers: KeyValueItem[], auth: AuthConfig): RequestDraft {
    return {
      protocol: request.protocol, method: request.method, url, lifecycle: request.lifecycle,
      activeConfigTab: request.activeConfigTab, params: request.params, headers, auth,
      bodyType: request.bodyType, bodyText: request.bodyText, formItems: request.formItems,
      multipartItems: request.multipartItems, binaryFileName: request.binaryFileName,
      preRequestScript: request.preRequestScript, postResponseScript: request.postResponseScript,
      extractionRules: request.extractionRules, testRules: request.testRules, settings: request.settings
    };
  }

  private activeVariables(): KeyValueItem[] {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === this.selectedEnvironmentId);
    return environment ? environment.variables : [];
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
          Text(this.tabs[this.activeIndex()].request.protocol === 'websocket' ? 'WS' :
            (this.tabs[this.activeIndex()].request.protocol === 'sse' ? 'SSE' :
              this.tabs[this.activeIndex()].method))
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

        if (this.tabs[this.activeIndex()].request.protocol !== 'websocket' &&
          this.tabs[this.activeIndex()].request.protocol !== 'sse') {
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
        }
      } else if (!this.phone) {
        RequestTabBar({
          tabs: $tabs,
          activeTabId: $activeTabId,
          onSelect: (id: string) => this.selectTab(id),
          onClose: this.onCloseTab,
          onCloseAll: this.onCloseAllTabs,
          onCreate: this.onCreateTab,
          onRename: this.onRenameRequest
        })
      }

      if (this.tabs.length === 0) {
        NimboEmptyState({
          title: $r('app.string.empty_workspace_title'),
          description: $r('app.string.empty_workspace_description')
        })
          .layoutWeight(1)
      } else if (this.tabs[this.activeIndex()].request.protocol === 'sse') {
        SsePanel({
          session: this.sseSession,
          request: this.tabs[this.activeIndex()].request,
          variables: this.activeVariables(),
          onUrlChange: (value: string) => this.onWebSocketUrlChange(this.activeTabId, value),
          onHeadersChange: (headers: KeyValueItem[]) => this.onUpdateRequest(this.activeTabId,
            this.webSocketRequest(this.tabs[this.activeIndex()].request,
              this.tabs[this.activeIndex()].request.url, headers, this.tabs[this.activeIndex()].request.auth)),
          onAuthChange: (auth: AuthConfig) => this.onUpdateRequest(this.activeTabId,
            this.webSocketRequest(this.tabs[this.activeIndex()].request,
              this.tabs[this.activeIndex()].request.url, this.tabs[this.activeIndex()].request.headers, auth)),
          onConnect: () => this.onSseConnect(this.activeTabId),
          onStop: () => this.onSseStop(this.activeTabId),
          onClear: () => this.onSseClear(this.activeTabId),
          onCopy: () => this.onSseCopy(this.activeTabId),
          onExport: () => this.onSseExport(this.activeTabId)
        })
          .layoutWeight(1)
          .opacity(this.contentOpacity)
      } else if (this.tabs[this.activeIndex()].request.protocol === 'websocket') {
        WebSocketPanel({
          session: this.webSocketSession,
          request: this.tabs[this.activeIndex()].request,
          variables: this.activeVariables(),
          onUrlChange: (value: string) => this.onWebSocketUrlChange(this.activeTabId, value),
          onHeadersChange: (headers: KeyValueItem[]) => this.onUpdateRequest(this.activeTabId,
            this.webSocketRequest(this.tabs[this.activeIndex()].request,
              this.tabs[this.activeIndex()].request.url, headers, this.tabs[this.activeIndex()].request.auth)),
          onAuthChange: (auth: AuthConfig) => this.onUpdateRequest(this.activeTabId,
            this.webSocketRequest(this.tabs[this.activeIndex()].request,
              this.tabs[this.activeIndex()].request.url, this.tabs[this.activeIndex()].request.headers, auth)),
          onConnect: () => this.onWebSocketConnect(this.activeTabId),
          onDisconnect: () => this.onWebSocketDisconnect(this.activeTabId),
          onComposerChange: (value: string) => this.onWebSocketComposerChange(this.activeTabId, value),
          onSend: () => this.onWebSocketSend(this.activeTabId),
          onClear: () => this.onWebSocketClear(this.activeTabId),
          onCopy: () => this.onWebSocketCopy(this.activeTabId),
          onExport: () => this.onWebSocketExport(this.activeTabId)
        })
          .layoutWeight(1)
          .opacity(this.contentOpacity)
      } else if (this.phone) {
        if (this.mobilePage === 'request') {
          RequestPanel({
            request: this.tabs[this.activeIndex()].request,
            response: this.tabs[this.activeIndex()].response,
            environments: this.environments,
            selectedEnvironmentId: this.selectedEnvironmentId,
            onSaveRequest: () => this.onSaveRequest(this.activeTabId),
            onCopyGeneratedCode: this.onCopyGeneratedCode,
            phone: true,
            onChange: (request: RequestDraft) => this.onUpdateRequest(this.activeTabId, request)
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
            onDownloadBody: () => this.onDownloadResponseBody(this.tabs[this.activeIndex()].response),
            onCopyDiagnostic: () => this.onCopyErrorDiagnostic(this.tabs[this.activeIndex()].response.error)
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
            selectedEnvironmentId: this.selectedEnvironmentId,
            onSaveRequest: () => this.onSaveRequest(this.activeTabId),
            onCopyGeneratedCode: this.onCopyGeneratedCode,
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
            onSaveBinary: () => this.onSaveBinary(this.tabs[this.activeIndex()].response),
            onCopyBody: () => this.onCopyResponseBody(this.tabs[this.activeIndex()].response),
            onDownloadBody: () => this.onDownloadResponseBody(this.tabs[this.activeIndex()].response),
            onCopyDiagnostic: () => this.onCopyErrorDiagnostic(this.tabs[this.activeIndex()].response.error)
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
