import { KeyValueItem, ResponseBodyMode, ResponseModel, ResponseTab } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { ErrorPanel } from './ErrorPanel';
import { JsonViewer } from './JsonViewer';
import { LargeResponseViewer } from './LargeResponseViewer';
import { RawViewer } from './RawViewer';
import { ResponseHeader } from './ResponseHeader';

@Component
export struct ResponsePanel {
  @Prop response: ResponseModel;
  @State activeTab: ResponseTab = 'body';
  @State bodyMode: ResponseBodyMode = 'pretty';
  onRetry: () => void = () => {};
  onPreviewLarge: () => void = () => {};

  @Builder
  private emptyState(title: string, description: string) {
    Column({ space: SpacingTokens.x2 }) {
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
  }

  @Builder
  private metadataRows(items: KeyValueItem[], emptyLabel: string) {
    if (items.length === 0) {
      Column() {
        Text(emptyLabel)
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
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
      .height('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
    }
  }

  @Builder
  private bodyContent() {
    Column() {
      Row({ space: SpacingTokens.x1 }) {
        Text('Pretty')
          .fontSize(11)
          .fontColor(this.bodyMode === 'pretty' ? ColorTokens.brand600 : ColorTokens.textSecondary)
          .height(SizeTokens.controlSmall)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .textAlign(TextAlign.Center)
          .backgroundColor(this.bodyMode === 'pretty' ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            this.bodyMode = 'pretty';
          })
        Text('Raw')
          .fontSize(11)
          .fontColor(this.bodyMode === 'raw' ? ColorTokens.brand600 : ColorTokens.textSecondary)
          .height(SizeTokens.controlSmall)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .textAlign(TextAlign.Center)
          .backgroundColor(this.bodyMode === 'raw' ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            this.bodyMode = 'raw';
          })
        Blank()
        Text('JSON')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textSecondary)
      }
      .height(34)
      .width('100%')
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x3 })

      if (this.bodyMode === 'pretty') {
        JsonViewer({ value: this.response.body })
          .layoutWeight(1)
      } else {
        RawViewer({ value: this.response.body })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, bottom: SpacingTokens.x2 })
  }

  build() {
    Column() {
      if (this.response.status === 'empty') {
        this.emptyState('No response yet', 'Send the request to see the response here.')
      } else if (this.response.status === 'error' || this.response.status === 'cancelled') {
        Column() {
          ErrorPanel({ error: this.response.error, onRetry: this.onRetry })
        }
        .width('100%')
        .height('100%')
        .padding(SpacingTokens.x4)
        .justifyContent(FlexAlign.Center)
      } else if (this.response.status === 'large') {
        LargeResponseViewer({
          responseSize: this.response.size,
          contentType: this.response.contentType,
          previewAvailable: this.response.previewAvailable,
          onPreview: this.onPreviewLarge
        })
      } else if (this.response.status === 'binary') {
        Column({ space: SpacingTokens.x3 }) {
          Text('Binary response')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary)
          Text(this.response.contentType)
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
          Text(this.response.size)
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.response.status === 'sending' && this.response.body.length === 0) {
        this.emptyState('Waiting for response...', 'The request is still in progress.')
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
          this.metadataRows(this.response.headers, 'No response headers')
        } else if (this.activeTab === 'cookies') {
          this.metadataRows(this.response.cookies, 'No cookies in this response')
        } else {
          Column({ space: SpacingTokens.x2 }) {
            Text('Timing details unavailable')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text('This mock response does not include network timing data.')
              .fontSize(12)
              .fontColor(ColorTokens.textTertiary)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgWorkspace)
  }
}
