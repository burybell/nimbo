import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct RawViewer {
  @Prop value: string = '';

  build() {
    Scroll() {
      Text(this.value)
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor(ColorTokens.codeText)
        .lineHeight(20)
        .width('100%')
        .padding(SpacingTokens.x4)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.TopStart)
    .scrollBar(BarState.Auto)
    .backgroundColor(ColorTokens.codeBackground)
    .borderRadius(RadiusTokens.small)
  }
}
