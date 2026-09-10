import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboLogo {
  @Prop compact: boolean = false;

  build() {
    Row({ space: SpacingTokens.x2 }) {
      Image($r('app.media.app_icon'))
      .width(28)
      .height(28)
      .objectFit(ImageFit.Contain)
      .borderRadius(7)

      if (!this.compact) {
        Text('Nimbo')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary)
      }
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}
