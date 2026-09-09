import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboButton {
  @Prop label: string;
  @Prop icon: string = '';
  @Prop primary: boolean = false;
  onPress: () => void = () => {};

  build() {
    Button() {
      Row({ space: SpacingTokens.x2 }) {
        if (this.icon.length > 0) {
          Text(this.icon)
            .fontSize(18)
            .fontColor(this.primary ? ColorTokens.textOnBrand : ColorTokens.textSecondary)
        }
        Text(this.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primary ? ColorTokens.textOnBrand : ColorTokens.textPrimary)
      }
      .justifyContent(FlexAlign.Center)
    }
    .height(SizeTokens.controlLarge)
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
    .backgroundColor(this.primary ? ColorTokens.brand500 : ColorTokens.bgSurface)
    .borderRadius(RadiusTokens.medium)
    .border({ width: this.primary ? 0 : 1, color: ColorTokens.borderDefault })
    .stateStyles({
      normal: { .backgroundColor(this.primary ? ColorTokens.brand500 : ColorTokens.bgSurface) },
      pressed: { .backgroundColor(this.primary ? ColorTokens.brand600 : ColorTokens.bgSurfaceHover) }
    })
    .onClick(this.onPress)
  }
}

