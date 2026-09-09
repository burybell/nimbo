import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboLogo {
  @Prop compact: boolean = false;

  build() {
    Row({ space: SpacingTokens.x2 }) {
      Stack() {
        Text('☁')
          .fontSize(20)
          .fontColor(ColorTokens.brand500)
      }
      .width(28)
      .height(28)
      .backgroundColor(ColorTokens.brand50)
      .borderRadius(14)

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

