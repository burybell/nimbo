import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct NimboEmptyState {
  @Prop title: ResourceStr;
  @Prop description: ResourceStr;

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Stack() {
        Text('☁')
          .fontSize(44)
          .fontColor(ColorTokens.brand500)
      }
      .width(72)
      .height(64)
      .backgroundColor(ColorTokens.brand50)
      .borderRadius(32)

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTokens.textPrimary)

      Text(this.description)
        .fontSize(13)
        .fontColor(ColorTokens.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
      .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }
}
