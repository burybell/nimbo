import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboDialog {
  @Prop title: string = '';
  @Prop message: string = '';
  @Prop confirmLabel: string = 'Confirm';
  @Prop dangerous: boolean = false;
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#520F1422')
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
          Button('Cancel')
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
      .width(420)
      .padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: '#33000000', offsetY: 8 })
    }
    .width('100%')
    .height('100%')
  }
}
