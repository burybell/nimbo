import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboToast {
  @Prop message: string = '';
  onAction: () => void = () => {};

  build() {
    Row({ space: SpacingTokens.x4 }) {
      Text(this.message)
        .fontSize(13)
        .fontColor(ColorTokens.textOnBrand)
      if (this.message.includes('— Undo')) {
        Text('Undo')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#AEB6FF')
          .onClick(this.onAction)
      }
    }
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    .backgroundColor(ColorTokens.textPrimary)
    .borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: '#33000000', offsetY: 4 })
  }
}
