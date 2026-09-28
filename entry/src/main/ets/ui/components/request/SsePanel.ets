import { AuthConfig, HttpMethod, KeyValueItem, RequestDraft, SseEventModel,
  SseSessionModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { AuthEditor } from './AuthEditor';
import { KeyValueEditor } from './KeyValueEditor';
import { MethodSelector } from './MethodSelector';
import { UrlInput } from './UrlInput';

type SsePanelTab = 'events' | 'headers' | 'auth';

@Component
export struct SsePanel {
  @Prop session: SseSessionModel;
  @Prop request: RequestDraft;
  @Prop variables: KeyValueItem[] = [];
  @State activeTab: SsePanelTab = 'events';
  @State searchQuery: string = '';
  onUrlChange: (value: string) => void = () => {};
  onMethodChange: (value: HttpMethod) => void = () => {};
  onHeadersChange: (value: KeyValueItem[]) => void = () => {};
  onAuthChange: (value: AuthConfig) => void = () => {};
  onConnect: () => void = () => {};
  onStop: () => void = () => {};
  onClear: () => void = () => {};
  onCopy: () => void = () => {};
  onExport: () => void = () => {};

  private active(): boolean {
    return this.session.status === 'connecting' || this.session.status === 'connected' ||
      this.session.status === 'stopping';
  }

  private validUrl(): boolean {
    const value = this.request.url.trim();
    return (value.startsWith('http://') && value.length > 7) ||
      (value.startsWith('https://') && value.length > 8) || value.includes('{{');
  }

  private statusText(): ResourceStr {
    if (this.session.status === 'connecting') return $r('app.string.sse_status_connecting');
    if (this.session.status === 'connected') return $r('app.string.sse_status_connected');
    if (this.session.status === 'stopping') return $r('app.string.sse_status_stopping');
    if (this.session.status === 'completed') return $r('app.string.sse_status_completed');
    if (this.session.status === 'error') return $r('app.string.sse_status_error');
    return $r('app.string.sse_status_disconnected');
  }

  private statusColor(): ResourceColor {
    if (this.session.status === 'connected') return ColorTokens.statusSuccess;
    if (this.session.status === 'error') return ColorTokens.statusServerError;
    if (this.active()) return ColorTokens.brand500;
    return ColorTokens.textTertiary;
  }

  private filteredEvents(): SseEventModel[] {
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) return this.session.events;
    return this.session.events.filter((item: SseEventModel) =>
      item.data.toLowerCase().includes(query) || item.event.toLowerCase().includes(query) ||
      item.eventId.toLowerCase().includes(query));
  }

  @Builder
  private tab(label: ResourceStr, value: SsePanelTab, badge: number = 0) {
    Row({ space: 5 }) {
      Text(label).fontSize(13).fontWeight(this.activeTab === value ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeTab === value ? ColorTokens.brand600 : ColorTokens.textSecondary)
      if (badge > 0) Text(`${badge}`).fontSize(9).fontColor(ColorTokens.textTertiary)
    }
    .height(40).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
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
  private eventsTimeline() {
    if (this.session.events.length === 0) {
      Column({ space: SpacingTokens.x2 }) {
        Text($r('app.string.sse_empty_title')).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text($r('app.string.sse_empty_description')).fontSize(12).fontColor(ColorTokens.textSecondary)
          .textAlign(TextAlign.Center)
      }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
    } else if (this.filteredEvents().length === 0) {
      Text($r('app.string.sse_search_empty')).layoutWeight(1).width('100%').fontSize(12)
        .fontColor(ColorTokens.textSecondary).textAlign(TextAlign.Center)
    } else {
      Scroll() {
        Column({ space: SpacingTokens.x2 }) {
          ForEach(this.filteredEvents(), (item: SseEventModel) => {
            Column({ space: SpacingTokens.x2 }) {
              Row({ space: SpacingTokens.x2 }) {
                Text(item.event).fontSize(10).fontWeight(FontWeight.Medium).fontColor(ColorTokens.brand600)
                if (item.eventId.length > 0) {
                  Text(`#${item.eventId}`).fontSize(10).fontFamily('monospace').fontColor(ColorTokens.textSecondary)
                }
                if (item.retry.length > 0) {
                  Text(`${item.retry} ms`).fontSize(10).fontColor(ColorTokens.textTertiary)
                }
                Blank()
                Text(item.timestamp).fontSize(10).fontColor(ColorTokens.textTertiary)
              }.width('100%')
              Text(item.data).width('100%').fontSize(12).fontFamily('monospace')
                .fontColor(ColorTokens.textPrimary).copyOption(CopyOptions.LocalDevice)
            }
            .width('100%').padding(SpacingTokens.x3).alignItems(HorizontalAlign.Start)
            .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderSubtle })
            .borderRadius(RadiusTokens.medium)
          }, (item: SseEventModel) => item.id)
        }.width('100%').padding(SpacingTokens.x4)
      }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
    }
  }

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Row() {
          MethodSelector({ value: this.request.method, embedded: true, onChange: this.onMethodChange })
          UrlInput({ value: this.request.url, variables: this.variables, embedded: true,
            onChange: this.onUrlChange, onSubmit: this.onConnect })
            .layoutWeight(1)
        }
        .height(SizeTokens.controlLarge).layoutWeight(1).backgroundColor(ColorTokens.bgSurface)
        .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
        .clip(true).enabled(!this.active())
        if (this.active()) {
          Button(this.session.status === 'stopping' ? $r('app.string.sse_stopping') : $r('app.string.sse_stop'))
            .height(SizeTokens.controlLarge).fontSize(12).fontColor(ColorTokens.statusServerError)
            .backgroundColor(ColorTokens.statusDangerBackground)
            .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
            .enabled(this.session.status !== 'stopping').onClick(this.onStop)
        } else {
          Button($r('app.string.sse_connect')).height(SizeTokens.controlLarge).fontSize(12)
            .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium).enabled(this.validUrl()).onClick(this.onConnect)
        }
      }
      .width('100%').padding(SpacingTokens.x4).backgroundColor(ColorTokens.bgWorkspace)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      Row() {
        this.tab($r('app.string.sse_tab_events'), 'events', this.session.events.length)
        this.tab($r('app.string.websocket_tab_headers'), 'headers',
          this.request.headers.filter((item: KeyValueItem) => item.enabled).length)
        this.tab($r('app.string.websocket_tab_auth'), 'auth')
        Blank()
        Row({ space: SpacingTokens.x2 }) {
          Text('●').fontSize(9).fontColor(this.statusColor())
          Text(this.statusText()).fontSize(11).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textSecondary)
          if (this.session.statusCode > 0) {
            Text(`${this.session.statusCode}`).fontSize(10).fontFamily('monospace')
              .fontColor(this.session.statusCode >= 400 ? ColorTokens.statusServerError : ColorTokens.textTertiary)
          }
          if (this.session.errorCode.length > 0) {
            Text(this.session.errorCode).fontSize(10).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
          }
        }.margin({ right: SpacingTokens.x4 })
      }
      .width('100%').height(41).backgroundColor(ColorTokens.bgSurface)
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      if (this.activeTab === 'events') {
        Row({ space: SpacingTokens.x2 }) {
          Image($r('app.media.search')).width(14).height(14).fillColor(ColorTokens.textTertiary)
          TextInput({ text: this.searchQuery, placeholder: $r('app.string.sse_search_placeholder') })
            .layoutWeight(1).height(28).fontSize(11).padding({ left: 6, right: 6, top: 0, bottom: 0 })
            .placeholderFont({ size: 11 })
            .backgroundColor(Color.Transparent)
            .placeholderColor(ColorTokens.textTertiary).onChange((value: string) => { this.searchQuery = value; })
          if (this.session.contentType.length > 0) {
            Text(this.session.contentType).fontSize(10).fontColor(ColorTokens.textTertiary)
          }
          this.iconAction($r('app.media.response_copy'), $r('app.string.sse_copy_all'),
            this.session.events.length > 0, this.onCopy)
          this.iconAction($r('app.media.response_download'), $r('app.string.sse_export'),
            this.session.events.length > 0, this.onExport)
          Text($r('app.string.sse_clear')).fontSize(11).fontColor(ColorTokens.textSecondary)
            .enabled(this.session.events.length > 0).onClick(this.onClear)
        }
        .width('100%').height(38).padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        .backgroundColor(ColorTokens.bgWorkspace).border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
        if (this.session.errorMessage.length > 0) {
          Text(this.session.errorMessage).width('100%').padding(SpacingTokens.x3).fontSize(11)
            .fontColor(ColorTokens.statusServerError).backgroundColor(ColorTokens.statusDangerBackground)
        }
        this.eventsTimeline()
      } else if (this.activeTab === 'headers') {
        Scroll() {
          KeyValueEditor({ items: this.request.headers, variables: this.variables, mode: 'headers',
            showDescription: true, onChange: this.onHeadersChange })
            .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
      } else {
        AuthEditor({ config: this.request.auth, variables: this.variables, onChange: this.onAuthChange })
          .layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(ColorTokens.bgWorkspace)
  }
}
