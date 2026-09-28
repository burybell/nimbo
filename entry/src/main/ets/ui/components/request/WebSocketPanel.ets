import { WebSocketMessageModel, WebSocketSessionModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct WebSocketPanel {
  @Prop session: WebSocketSessionModel;
  @Prop url: string = '';
  onUrlChange: (value: string) => void = () => {};
  onConnect: () => void = () => {};
  onDisconnect: () => void = () => {};
  onComposerChange: (value: string) => void = () => {};
  onSend: () => void = () => {};
  onClear: () => void = () => {};

  private connected(): boolean {
    return this.session.status === 'connected';
  }

  private busy(): boolean {
    return this.session.status === 'connecting' || this.session.status === 'closing';
  }

  private validUrl(): boolean {
    const value = this.url.trim();
    return (value.startsWith('ws://') && value.length > 5) ||
      (value.startsWith('wss://') && value.length > 6);
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

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Text('WS')
          .fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
          .width(42).height(SizeTokens.controlLarge).textAlign(TextAlign.Center)
        TextInput({ text: this.url, placeholder: 'wss://echo.example.com' })
          .layoutWeight(1).height(SizeTokens.controlLarge).fontSize(13)
          .fontColor(ColorTokens.textPrimary).placeholderColor(ColorTokens.textTertiary)
          .backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
          .enabled(!this.connected() && !this.busy())
          .onChange(this.onUrlChange)
          .onSubmit(() => { if (!this.connected() && !this.busy()) this.onConnect(); })
        if (this.connected()) {
          Button($r('app.string.websocket_disconnect'))
            .height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.statusServerError).backgroundColor(ColorTokens.statusDangerBackground)
            .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
            .onClick(this.onDisconnect)
        } else {
          Button(this.session.status === 'connecting' ? $r('app.string.websocket_connecting') :
            $r('app.string.websocket_connect'))
            .height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium).enabled(!this.busy() && this.validUrl())
            .onClick(this.onConnect)
        }
      }
      .width('100%').padding(SpacingTokens.x4)
      .backgroundColor(ColorTokens.bgWorkspace)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      Row({ space: SpacingTokens.x2 }) {
        Text('●').fontSize(9).fontColor(this.statusColor())
        Text(this.statusText()).fontSize(11).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textSecondary)
        if (this.session.errorCode.length > 0) {
          Text(this.session.errorCode).fontSize(10).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
        }
        Blank()
        Text($r('app.string.websocket_clear'))
          .fontSize(11).fontColor(ColorTokens.textSecondary)
          .enabled(this.session.messages.length > 0).onClick(this.onClear)
      }
      .width('100%').height(36).padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      if (this.session.messages.length === 0) {
        Column({ space: SpacingTokens.x2 }) {
          Text($r('app.string.websocket_empty_title'))
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
          Text($r('app.string.websocket_empty_description'))
            .fontSize(12).fontColor(ColorTokens.textSecondary).textAlign(TextAlign.Center)
        }
        .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: SpacingTokens.x2 }) {
            ForEach(this.session.messages, (message: WebSocketMessageModel) => {
              Column({ space: SpacingTokens.x2 }) {
                Row({ space: SpacingTokens.x2 }) {
                  Text(this.directionText(message))
                    .fontSize(10).fontWeight(FontWeight.Medium)
                    .fontColor(message.direction === 'sent' ? ColorTokens.brand600 :
                      (message.direction === 'received' ? ColorTokens.statusSuccess : ColorTokens.textSecondary))
                  Text(message.timestamp).fontSize(10).fontColor(ColorTokens.textTertiary)
                }
                .width('100%')
                Text(message.text)
                  .width('100%').fontSize(12).fontFamily('monospace').fontColor(ColorTokens.textPrimary)
                  .copyOption(CopyOptions.LocalDevice)
              }
              .width('100%').padding(SpacingTokens.x3).alignItems(HorizontalAlign.Start)
              .backgroundColor(message.direction === 'system' ? ColorTokens.bgWorkspace : ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.medium)
            }, (message: WebSocketMessageModel) => message.id)
          }
          .width('100%').padding(SpacingTokens.x4)
        }
        .layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
      }

      Row({ space: SpacingTokens.x2 }) {
        TextArea({ text: this.session.composer, placeholder: $r('app.string.websocket_message_placeholder') })
          .layoutWeight(1).height(76).fontSize(12).fontFamily('monospace')
          .fontColor(ColorTokens.textPrimary).placeholderColor(ColorTokens.textTertiary)
          .backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
          .enabled(this.connected()).onChange(this.onComposerChange)
        Button($r('app.string.websocket_send'))
          .width(82).height(SizeTokens.controlLarge).fontSize(12)
          .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.medium)
          .enabled(this.connected() && this.session.composer.length > 0).onClick(this.onSend)
      }
      .width('100%').padding(SpacingTokens.x4).alignItems(VerticalAlign.Bottom)
      .backgroundColor(ColorTokens.bgWorkspace)
      .border({ width: { top: 1 }, color: ColorTokens.borderSubtle })
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgWorkspace)
  }
}
