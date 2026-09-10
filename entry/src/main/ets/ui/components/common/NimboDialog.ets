import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct NimboDialog {
  @Prop title: ResourceStr = '';
  @Prop message: ResourceStr = '';
  @Prop confirmLabel: ResourceStr = $r('app.string.action_confirm');
  @Prop dangerous: boolean = false;
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorTokens.overlayScrim)
        .onClick(this.onCancel)

      Column({ space: SpacingTokens.x4 }) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
          .width('100%')
        Text(this.message)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(ColorTokens.textSecondary)
          .width('100%')
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          Button($r('app.string.action_cancel'))
            .fontSize(13)
            .fontColor(ColorTokens.textPrimary)
            .backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.medium)
            .onClick(this.onCancel)
          Button(this.confirmLabel)
            .fontSize(13)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(this.dangerous ? ColorTokens.httpDelete : ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium)
            .onClick(this.onConfirm)
        }
        .width('100%')
      }
      .width('90%')
      .constraintSize({ maxWidth: 420 })
      .padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 8 }))
        .combine(TransitionEffect.scale({ x: 0.96, y: 0.96 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%')
    .height('100%')
    .transition(TransitionEffect.OPACITY
      .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }
}
