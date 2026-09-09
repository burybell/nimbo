import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct LargeResponseViewer {
  @Prop responseSize: string = '';
  @Prop contentType: string = '';
  @Prop previewAvailable: boolean = false;
  onPreview: () => void = () => {};

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Text($r('app.string.response_large'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary)
      Text(this.responseSize)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTokens.statusClientError)
      Text(this.contentType)
        .fontSize(11)
        .fontColor(ColorTokens.textTertiary)
      Text($r('app.string.response_large_warning'))
        .fontSize(13)
        .fontColor(ColorTokens.textSecondary)
      if (this.previewAvailable) {
        Button($r('app.string.response_preview_mb'))
          .fontSize(12)
          .height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textOnBrand)
          .backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.small)
          .onClick(this.onPreview)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
