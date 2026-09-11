import { KeyValueItem, ResponseBodyMode, ResponseModel, ResponseTab } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { ErrorPanel } from './ErrorPanel';
import { JsonViewer } from './JsonViewer';
import { LargeResponseViewer } from './LargeResponseViewer';
import { RawViewer } from './RawViewer';
import { ResponseHeader } from './ResponseHeader';
import { MotionTokens } from '../../tokens/MotionTokens';
import { MediaViewer } from './MediaViewer';
import { TestResultsView } from './TestResultsView';

@Component
export struct ResponsePanel {
  @Prop response: ResponseModel;
  @State activeTab: ResponseTab = 'body';
  @State bodyMode: ResponseBodyMode = 'pretty';
  @State searchVisible: boolean = false;
  @State searchQuery: string = '';
  @State searchIndex: number = 0;
  @State searchRevision: number = 0;
  onRetry: () => void = () => {};
  onPreviewLarge: () => void = () => {};
  onSaveBinary: () => void = () => {};
  onCopyBody: () => void = () => {};
  onDownloadBody: () => void = () => {};

  private matchCount(): number {
    if (this.searchQuery.length === 0) return 0;
    const source = this.response.body.toLowerCase();
    const needle = this.searchQuery.toLowerCase();
    let count = 0;
    let offset = 0;
    while (offset < source.length) {
      const match = source.indexOf(needle, offset);
      if (match < 0) break;
      count += 1;
      offset = match + needle.length;
    }
    return count;
  }

  private navigateMatch(step: number): void {
    const count = this.matchCount();
    if (count === 0) return;
    this.searchIndex = (this.searchIndex + step + count) % count;
    this.searchRevision += 1;
  }

  private closeSearch(): void {
    this.searchVisible = false;
    this.searchQuery = '';
    this.searchIndex = 0;
  }

  private toggleSearch(): void {
    if (this.searchVisible) {
      this.closeSearch();
      return;
    }
    this.searchVisible = true;
    setTimeout(() => {
      focusControl.requestFocus('nimboResponseSearchInput');
    }, 50);
  }

  @Builder
  private emptyState(title: ResourceStr, description: ResourceStr, loading: boolean = false) {
    Column({ space: SpacingTokens.x2 }) {
      if (loading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(ColorTokens.brand500)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.7, y: 0.7 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      }
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.textPrimary)
      Text(description)
        .fontSize(12)
        .fontColor(ColorTokens.textTertiary)
      Text('Ctrl + Enter')
        .fontSize(11)
        .fontColor(ColorTokens.textTertiary)
        .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 3, bottom: 3 })
        .border({ width: 1, color: ColorTokens.borderDefault })
        .borderRadius(RadiusTokens.small)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 6 }))
      .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }

  @Builder
  private metadataRows(items: KeyValueItem[], emptyLabel: ResourceStr) {
    if (items.length === 0) {
      Column() {
        Text(emptyLabel)
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .transition(TransitionEffect.OPACITY
        .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
    } else {
      Scroll() {
        Column() {
          ForEach(items, (item: KeyValueItem) => {
            Row({ space: SpacingTokens.x3 }) {
              Text(item.key)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTokens.textSecondary)
                .layoutWeight(2)
              Text(item.value)
                .fontSize(12)
                .fontFamily('monospace')
                .fontColor(ColorTokens.textPrimary)
                .layoutWeight(4)
            }
            .width('100%')
            .constraintSize({ minHeight: 36 })
            .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
            .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
          }, (item: KeyValueItem) => item.id)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
      .transition(TransitionEffect.OPACITY
        .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
    }
  }

  @Builder
  private bodyContent() {
    if (this.response.mediaKind !== 'none' && this.response.mediaUri.length > 0) {
      MediaViewer({
        kind: this.response.mediaKind,
        uri: this.response.mediaUri,
        contentType: this.response.contentType,
        responseSize: this.response.size,
        onSave: this.onSaveBinary
      })
      .layoutWeight(1)
      .transition(TransitionEffect.OPACITY.animation({ duration: MotionTokens.fast,
        curve: MotionTokens.standardCurve }))
    } else {
      Column() {
        Row({ space: SpacingTokens.x1 }) {
          Text($r('app.string.response_pretty'))
            .fontSize(11)
            .fontColor(this.bodyMode === 'pretty' ? ColorTokens.brand600 : ColorTokens.textSecondary)
            .height(SizeTokens.controlSmall)
            .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
            .textAlign(TextAlign.Center)
            .backgroundColor(this.bodyMode === 'pretty' ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
            .borderRadius(RadiusTokens.small)
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
            .onClick(() => {
              this.getUIContext().animateTo({ duration: MotionTokens.fast,
                curve: MotionTokens.standardCurve }, () => { this.bodyMode = 'pretty'; });
            })
          Text($r('app.string.response_raw'))
            .fontSize(11)
            .fontColor(this.bodyMode === 'raw' ? ColorTokens.brand600 : ColorTokens.textSecondary)
            .height(SizeTokens.controlSmall)
            .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
            .textAlign(TextAlign.Center)
            .backgroundColor(this.bodyMode === 'raw' ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
            .borderRadius(RadiusTokens.small)
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
            .onClick(() => {
              this.getUIContext().animateTo({ duration: MotionTokens.fast,
                curve: MotionTokens.standardCurve }, () => { this.bodyMode = 'raw'; });
            })
          Blank()
          Button({ type: ButtonType.Normal }) {
            Image($r('app.media.search'))
              .width(16)
              .height(16)
          }
            .width(28)
            .height(28)
            .backgroundColor(this.searchVisible ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
            .borderRadius(RadiusTokens.small)
            .accessibilityText($r('app.string.response_search_action'))
            .onClick(() => { this.toggleSearch(); })
          Button({ type: ButtonType.Normal }) {
            Image($r('app.media.response_copy'))
              .width(16)
              .height(16)
          }
            .width(28)
            .height(28)
            .backgroundColor(ColorTokens.bgWorkspace)
            .borderRadius(RadiusTokens.small)
            .accessibilityText($r('app.string.response_copy_action'))
            .onClick(() => { this.onCopyBody(); })
          Button({ type: ButtonType.Normal }) {
            Image($r('app.media.response_download'))
              .width(16)
              .height(16)
          }
            .width(28)
            .height(28)
            .backgroundColor(ColorTokens.bgWorkspace)
            .borderRadius(RadiusTokens.small)
            .accessibilityText($r('app.string.response_download_action'))
            .onClick(() => { this.onDownloadBody(); })
          Text(this.response.contentType.toLowerCase().includes('json') ? 'JSON' : $r('app.string.body_text'))
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textSecondary)
        }
        .height(34)
        .width('100%')
        .padding({ left: SpacingTokens.x2, right: SpacingTokens.x3 })

        if (this.searchVisible) {
          Row({ space: SpacingTokens.x1 }) {
            TextInput({ text: this.searchQuery, placeholder: $r('app.string.search_response') })
              .id('nimboResponseSearchInput')
              .fontSize(10)
              .height(28)
              .layoutWeight(1)
              .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 0, bottom: 0 })
              .backgroundColor(ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.borderDefault })
              .borderRadius(RadiusTokens.small)
              .onChange((value: string) => {
                this.searchQuery = value;
                this.searchIndex = 0;
              })
              .onKeyEvent((event: KeyEvent) => {
                if (event.type === KeyType.Down && event.keyCode === 2070) {
                  this.closeSearch();
                  return true;
                }
                return false;
              })
              .onSubmit(() => { this.navigateMatch(1); })
            Text(`${this.matchCount() === 0 ? 0 : this.searchIndex + 1} / ${this.matchCount()}`)
              .fontSize(11)
              .fontColor(ColorTokens.textSecondary)
              .width(46)
              .textAlign(TextAlign.Center)
            Text('↑')
              .fontSize(13)
              .fontColor(ColorTokens.textSecondary)
              .width(26)
              .height(26)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.navigateMatch(-1); })
            Text('↓')
              .fontSize(13)
              .fontColor(ColorTokens.textSecondary)
              .width(26)
              .height(26)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.navigateMatch(1); })
            Text('×')
              .fontSize(16)
              .fontColor(ColorTokens.textSecondary)
              .width(26)
              .height(26)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.closeSearch();
              })
          }
          .height(36)
          .width('100%')
          .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
          .backgroundColor(ColorTokens.bgSurface)
        }

        if (this.bodyMode === 'pretty' && this.response.contentType.toLowerCase().includes('json')) {
          JsonViewer({ value: this.response.body, query: this.searchQuery,
            searchIndex: this.searchIndex, searchRevision: this.searchRevision })
            .layoutWeight(1)
        } else {
          RawViewer({ value: this.response.body, query: this.searchQuery,
            searchIndex: this.searchIndex, searchRevision: this.searchRevision })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, bottom: SpacingTokens.x2 })
      .transition(TransitionEffect.OPACITY
        .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
    }
  }

  build() {
    Column() {
      if (this.response.status === 'empty') {
        this.emptyState($r('app.string.response_empty_title'), $r('app.string.response_empty_description'))
      } else if (this.response.status === 'error' || this.response.status === 'cancelled') {
        Column() {
          ErrorPanel({ error: this.response.error, onRetry: this.onRetry })
        }
        .width('100%')
        .height('100%')
        .padding(SpacingTokens.x4)
        .justifyContent(FlexAlign.Center)
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 6 }))
          .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
      } else if (this.response.status === 'large') {
        LargeResponseViewer({
          responseSize: this.response.size,
          contentType: this.response.contentType,
          previewAvailable: this.response.previewAvailable,
          onPreview: this.onPreviewLarge
        })
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 6 }))
            .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
      } else if (this.response.status === 'binary') {
        Column({ space: SpacingTokens.x3 }) {
          Text($r('app.string.response_binary'))
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary)
          Text(this.response.contentType)
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
          Text(this.response.size)
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
          Button($r('app.string.response_download_binary'))
            .fontSize(13)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium)
            .onClick(this.onSaveBinary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 6 }))
          .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
      } else if (this.response.status === 'sending' && this.response.body.length === 0) {
        this.emptyState($r('app.string.response_waiting_title'), $r('app.string.response_waiting_description'), true)
      } else {
        ResponseHeader({
          response: this.response,
          activeTab: this.activeTab,
          onTabChange: (tab: ResponseTab) => {
            this.activeTab = tab;
          }
        })
        if (this.activeTab === 'body') {
          this.bodyContent()
        } else if (this.activeTab === 'headers') {
          this.metadataRows(this.response.headers, $r('app.string.response_no_headers'))
        } else if (this.activeTab === 'cookies') {
          this.metadataRows(this.response.cookies, $r('app.string.response_no_cookies'))
        } else if (this.activeTab === 'tests') {
          TestResultsView({ results: this.response.testResults })
            .layoutWeight(1)
            .transition(TransitionEffect.OPACITY
              .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
        } else {
          Column({ space: SpacingTokens.x2 }) {
            Text($r('app.string.response_timing_unavailable'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text($r('app.string.response_timing_description'))
              .fontSize(12)
              .fontColor(ColorTokens.textTertiary)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .transition(TransitionEffect.OPACITY
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgWorkspace)
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyCode === 2070 && this.searchVisible) {
        this.closeSearch();
        return true;
      }
      if (event.type === KeyType.Down && event.keyText.toLowerCase() === 'f' &&
        event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
        this.toggleSearch();
        return true;
      }
      return false;
    })
  }
}
