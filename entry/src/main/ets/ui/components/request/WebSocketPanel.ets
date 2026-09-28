import {
  AuthConfig,
  KeyValueItem,
  RequestDraft,
  WebSocketConnectionRecord,
  WebSocketMessageModel,
  WebSocketSessionModel
} from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { AuthEditor } from './AuthEditor';
import { KeyValueEditor } from './KeyValueEditor';
import { VariableTextInput } from './VariableTextInput';

type WebSocketPanelTab = 'messages' | 'headers' | 'auth' | 'history';

@Component
export struct WebSocketPanel {
  @Prop session: WebSocketSessionModel;
  @Prop request: RequestDraft;
  @Prop variables: KeyValueItem[] = [];
  @State activeTab: WebSocketPanelTab = 'messages';
  @State searchQuery: string = '';
  onUrlChange: (value: string) => void = () => {};
  onHeadersChange: (value: KeyValueItem[]) => void = () => {};
  onAuthChange: (value: AuthConfig) => void = () => {};
  onConnect: () => void = () => {};
  onDisconnect: () => void = () => {};
  onComposerChange: (value: string) => void = () => {};
  onSend: () => void = () => {};
  onClear: () => void = () => {};
  onCopy: () => void = () => {};
  onExport: () => void = () => {};

  private connected(): boolean {
    return this.session.status === 'connected';
  }

  private busy(): boolean {
    return this.session.status === 'connecting' || this.session.status === 'closing';
  }

  private validUrl(): boolean {
    const value = this.request.url.trim();
    return (value.startsWith('ws://') && value.length > 5) ||
      (value.startsWith('wss://') && value.length > 6) || value.includes('{{');
  }

  private statusText(): ResourceStr {
    if (this.session.status === 'connecting') return $r('app.string.websocket_status_connecting');
    if (this.session.status === 'connected') return $r('app.string.websocket_status_connected');
    if (this.session.status === 'closing') return $r('app.string.websocket_status_closing');
    if (this.session.status === 'error') return $r('app.string.websocket_status_error');
    return $r('app.string.websocket_status_disconnected');
  }

  private statusColor(): ResourceColor {
    if (this.session.status === 'connected') return ColorTokens.statusSuccess;
    if (this.session.status === 'error') return ColorTokens.statusServerError;
    if (this.busy()) return ColorTokens.brand500;
    return ColorTokens.textTertiary;
  }

  private directionText(message: WebSocketMessageModel): ResourceStr {
    if (message.direction === 'sent') return $r('app.string.websocket_sent');
    if (message.direction === 'received') return $r('app.string.websocket_received');
    return $r('app.string.websocket_system');
  }

  private filteredMessages(): WebSocketMessageModel[] {
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) return this.session.messages;
    return this.session.messages.filter((item: WebSocketMessageModel) =>
      item.text.toLowerCase().includes(query));
  }

  private historyStatus(item: WebSocketConnectionRecord): ResourceStr {
    if (item.status === 'connecting') return $r('app.string.websocket_history_connecting');
    if (item.status === 'connected') return $r('app.string.websocket_history_connected');
    if (item.status === 'closed') return $r('app.string.websocket_history_closed');
    return $r('app.string.websocket_history_failed');
  }

  @Builder
  private tab(label: ResourceStr, value: WebSocketPanelTab, badge: number = 0) {
    Row({ space: 5 }) {
      Text(label).fontSize(11).fontWeight(this.activeTab === value ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeTab === value ? ColorTokens.brand600 : ColorTokens.textSecondary)
      if (badge > 0) Text(`${badge}`).fontSize(9).fontColor(ColorTokens.textTertiary)
    }
    .height(34).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
    .border({ width: { bottom: this.activeTab === value ? 2 : 0 }, color: ColorTokens.brand500 })
    .onClick(() => { this.activeTab = value; })
  }

  @Builder
  private iconAction(icon: Resource, label: Resource, enabled: boolean, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Image(icon).width(15).height(15).fillColor(enabled ? ColorTokens.textSecondary : ColorTokens.textTertiary)
    }
    .width(28).height(28).padding(0).backgroundColor(Color.Transparent).borderRadius(RadiusTokens.small)
    .enabled(enabled).accessibilityText(label).onClick(action)
  }

  @Builder
  private messageTimeline() {
    if (this.session.messages.length === 0) {
      Column({ space: SpacingTokens.x2 }) {
        Text($r('app.string.websocket_empty_title'))
          .fontSize(14).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text($r('app.string.websocket_empty_description'))
          .fontSize(12).fontColor(ColorTokens.textSecondary).textAlign(TextAlign.Center)
      }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
    } else if (this.filteredMessages().length === 0) {
      Text($r('app.string.websocket_search_empty')).layoutWeight(1).width('100%').fontSize(12)
        .fontColor(ColorTokens.textSecondary).textAlign(TextAlign.Center)
    } else {
      Scroll() {
        Column({ space: SpacingTokens.x2 }) {
          ForEach(this.filteredMessages(), (message: WebSocketMessageModel) => {
            Column({ space: SpacingTokens.x2 }) {
              Row({ space: SpacingTokens.x2 }) {
                Text(this.directionText(message)).fontSize(10).fontWeight(FontWeight.Medium)
                  .fontColor(message.direction === 'sent' ? ColorTokens.brand600 :
                    (message.direction === 'received' ? ColorTokens.statusSuccess : ColorTokens.textSecondary))
                Text(message.timestamp).fontSize(10).fontColor(ColorTokens.textTertiary)
              }.width('100%')
              Text(message.text).width('100%').fontSize(12).fontFamily('monospace')
                .fontColor(ColorTokens.textPrimary).copyOption(CopyOptions.LocalDevice)
            }
            .width('100%').padding(SpacingTokens.x3).alignItems(HorizontalAlign.Start)
            .backgroundColor(message.direction === 'system' ? ColorTokens.bgWorkspace : ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.medium)
          }, (message: WebSocketMessageModel) => message.id)
        }.width('100%').padding(SpacingTokens.x4)
      }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
    }
  }

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Text('WS').fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
          .width(42).height(SizeTokens.controlLarge).textAlign(TextAlign.Center)
        VariableTextInput({ value: this.request.url, variables: this.variables,
          inputId: 'nimbo-websocket-url', placeholder: 'wss://echo.example.com', fontSize: 13,
          controlHeight: SizeTokens.controlLarge, fillColor: ColorTokens.bgSurface,
          onChange: this.onUrlChange })
          .layoutWeight(1).border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium).enabled(!this.connected() && !this.busy())
        if (this.connected()) {
          Button($r('app.string.websocket_disconnect')).height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.statusServerError).backgroundColor(ColorTokens.statusDangerBackground)
            .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
            .onClick(this.onDisconnect)
        } else {
          Button(this.session.status === 'connecting' ? $r('app.string.websocket_connecting') :
            $r('app.string.websocket_connect')).height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium).enabled(!this.busy() && this.validUrl()).onClick(this.onConnect)
        }
      }
      .width('100%').padding(SpacingTokens.x4).backgroundColor(ColorTokens.bgWorkspace)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      Row() {
        this.tab($r('app.string.websocket_tab_messages'), 'messages', this.session.messages.length)
        this.tab($r('app.string.websocket_tab_headers'), 'headers',
          this.request.headers.filter((item: KeyValueItem) => item.enabled).length)
        this.tab($r('app.string.websocket_tab_auth'), 'auth')
        this.tab($r('app.string.websocket_tab_history'), 'history', (this.session.connectionHistory ?? []).length)
        Blank()
        Row({ space: SpacingTokens.x2 }) {
          Text('●').fontSize(9).fontColor(this.statusColor())
          Text(this.statusText()).fontSize(11).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textSecondary)
          if (this.session.errorCode.length > 0) {
            Text(this.session.errorCode).fontSize(10).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
          }
        }.margin({ right: SpacingTokens.x4 })
      }
      .width('100%').height(36).backgroundColor(ColorTokens.bgSurface)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      if (this.activeTab === 'messages') {
        Row({ space: SpacingTokens.x2 }) {
          Image($r('app.media.search')).width(14).height(14).fillColor(ColorTokens.textTertiary)
          TextInput({ text: this.searchQuery, placeholder: $r('app.string.websocket_search_placeholder') })
            .layoutWeight(1).height(28).fontSize(11).backgroundColor(Color.Transparent)
            .placeholderColor(ColorTokens.textTertiary).onChange((value: string) => { this.searchQuery = value; })
          this.iconAction($r('app.media.response_copy'), $r('app.string.websocket_copy_all'),
            this.session.messages.length > 0, this.onCopy)
          this.iconAction($r('app.media.response_download'), $r('app.string.websocket_export'),
            this.session.messages.length > 0, this.onExport)
          Text($r('app.string.websocket_clear')).fontSize(11).fontColor(ColorTokens.textSecondary)
            .enabled(this.session.messages.length > 0).onClick(this.onClear)
        }
        .width('100%').height(38).padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        .backgroundColor(ColorTokens.bgWorkspace).border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
        this.messageTimeline()
        Row({ space: SpacingTokens.x2 }) {
          TextArea({ text: this.session.composer, placeholder: $r('app.string.websocket_message_placeholder') })
            .layoutWeight(1).height(76).fontSize(12).fontFamily('monospace')
            .fontColor(ColorTokens.textPrimary).placeholderColor(ColorTokens.textTertiary)
            .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.medium).enabled(this.connected()).onChange(this.onComposerChange)
          Button($r('app.string.websocket_send')).width(82).height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium)
            .enabled(this.connected() && this.session.composer.length > 0).onClick(this.onSend)
        }
        .width('100%').padding(SpacingTokens.x4).alignItems(VerticalAlign.Bottom)
        .backgroundColor(ColorTokens.bgWorkspace).border({ width: { top: 1 }, color: ColorTokens.borderSubtle })
      } else if (this.activeTab === 'headers') {
        Scroll() {
          KeyValueEditor({ items: this.request.headers, variables: this.variables, mode: 'headers',
            showDescription: true, onChange: this.onHeadersChange })
            .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
      } else if (this.activeTab === 'auth') {
        AuthEditor({ config: this.request.auth, variables: this.variables, onChange: this.onAuthChange })
          .layoutWeight(1)
      } else {
        if ((this.session.connectionHistory ?? []).length === 0) {
          Text($r('app.string.websocket_history_empty')).layoutWeight(1).width('100%').fontSize(12)
            .fontColor(ColorTokens.textSecondary).textAlign(TextAlign.Center)
        } else {
          Scroll() {
            Column({ space: SpacingTokens.x2 }) {
              ForEach([...(this.session.connectionHistory ?? [])].reverse(), (item: WebSocketConnectionRecord) => {
                Row({ space: SpacingTokens.x3 }) {
                  Text(this.historyStatus(item)).width(78).fontSize(11)
                    .fontColor(item.status === 'failed' ? ColorTokens.statusServerError : ColorTokens.textSecondary)
                  Column({ space: 3 }) {
                    Text(item.url).fontSize(12).fontFamily('monospace').fontColor(ColorTokens.textPrimary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.endedAt.length > 0 ? `${item.startedAt} — ${item.endedAt}` : item.startedAt)
                      .fontSize(10).fontColor(ColorTokens.textTertiary)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  if (item.errorCode.length > 0) {
                    Text(item.errorCode).fontSize(10).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
                  }
                }
                .width('100%').padding(SpacingTokens.x3).backgroundColor(ColorTokens.bgSurface)
                .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.medium)
              }, (item: WebSocketConnectionRecord) => item.id)
            }.width('100%').padding(SpacingTokens.x4)
          }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
        }
      }
    }.width('100%').height('100%').backgroundColor(ColorTokens.bgWorkspace)
  }
}
