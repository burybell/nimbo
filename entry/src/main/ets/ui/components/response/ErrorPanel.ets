import { ResponseErrorModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ErrorPanel {
  @Prop error: ResponseErrorModel;
  @State showDetails: boolean = false;
  onRetry: () => void = () => {};

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Row({ space: SpacingTokens.x3 }) {
        Text('!')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.statusServerError)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor('#FFE6E6')
          .borderRadius(18)
        Column({ space: SpacingTokens.x1 }) {
          Text(this.error.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary)
          Text(this.error.message)
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
        }
        .alignItems(HorizontalAlign.Start)
      }

      if (this.showDetails) {
        Column({ space: SpacingTokens.x1 }) {
          Text(this.error.code)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.statusServerError)
          Text(this.error.details)
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor(ColorTokens.textSecondary)
        }
        .width('100%')
        .padding(SpacingTokens.x3)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(ColorTokens.bgSurface)
        .borderRadius(RadiusTokens.small)
      }

      Row({ space: SpacingTokens.x2 }) {
        Button($r('app.string.action_retry'))
          .fontSize(12)
          .height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textOnBrand)
          .backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.small)
          .onClick(this.onRetry)
        Button(this.showDetails ? $r('app.string.hide_details') : $r('app.string.details'))
          .fontSize(12)
          .height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textSecondary)
          .backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            this.showDetails = !this.showDetails;
          })
      }
    }
    .width('100%')
    .padding(SpacingTokens.x5)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFF1F1')
    .border({ width: 1, color: '#FFDADA' })
    .borderRadius(RadiusTokens.medium)
  }
}
