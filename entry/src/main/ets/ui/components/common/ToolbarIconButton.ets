import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct ToolbarIconButton {
  @Prop icon: Resource;
  @Prop accessibilityLabel: Resource;
  @State hovered: boolean = false;
  onTap: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.icon)
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
    }
    .width(SizeTokens.controlMedium)
    .height(SizeTokens.controlMedium)
    .backgroundColor(this.hovered ? ColorTokens.bgSurfaceHover : Color.Transparent)
    .borderRadius(SizeTokens.controlMedium / 2)
    .opacity(this.hovered ? 1 : 0.9)
    .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
    .stateStyles({
      normal: {},
      pressed: { .backgroundColor(ColorTokens.bgSurfaceActive).opacity(0.68) }
    })
    .onHover((hovered: boolean) => { this.hovered = hovered; })
    .accessibilityText(this.accessibilityLabel)
    .onClick(this.onTap)
  }
}
