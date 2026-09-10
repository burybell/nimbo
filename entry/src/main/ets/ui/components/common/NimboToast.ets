import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboToast {
  @Prop message: ResourceStr = '';
  @Prop actionVisible: boolean = false;
  onAction: () => void = () => {};

  build() {
    Row({ space: SpacingTokens.x4 }) {
      Text(this.message)
        .fontSize(13)
        .fontColor(ColorTokens.textOnBrand)
      if (this.actionVisible) {
        Text($r('app.string.action_undo'))
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.toastAction)
          .onClick(this.onAction)
      }
    }
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    .backgroundColor(ColorTokens.toastBackground)
    .borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
  }
}
