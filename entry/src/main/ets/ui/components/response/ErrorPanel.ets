import { ResponseErrorModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ErrorPanel {
  @Prop error: ResponseErrorModel;
  @State showDetails: boolean = false;
  onRetry: () => void = () => {};

  private title(): ResourceStr {
    if (this.error.type === 'invalidUrl') return $r('app.string.error_invalid_url');
    if (this.error.type === 'dns') return $r('app.string.error_dns');
    if (this.error.type === 'connectionRefused' || this.error.type === 'connectionReset') {
      return $r('app.string.error_connection');
    }
    if (this.error.type === 'timeout') return $r('app.string.error_timeout');
    if (this.error.type === 'tls') return $r('app.string.error_tls');
    if (this.error.type === 'cancelled') return $r('app.string.error_cancelled');
    if (this.error.title.length > 0) return this.error.title;
    return $r('app.string.error_request_failed');
  }

  private message(): ResourceStr {
    if (this.error.type === 'cancelled') return $r('app.string.error_cancelled_message');
    return this.error.message;
  }

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
          .backgroundColor(ColorTokens.statusDangerBackground)
          .borderRadius(18)
        Column({ space: SpacingTokens.x1 }) {
          Text(this.title())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textPrimary)
          Text(this.message())
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
    .backgroundColor(ColorTokens.statusDangerBackground)
    .border({ width: 1, color: ColorTokens.statusDangerBorder })
    .borderRadius(RadiusTokens.medium)
  }
}
