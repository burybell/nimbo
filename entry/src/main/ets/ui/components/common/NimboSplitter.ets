import { ColorTokens } from '../../tokens/ColorTokens';

@Component
export struct NimboSplitter {
  @Prop ratio: number = 0.48;
  @Prop availableHeight: number = 600;
  @Prop min: number = 0.25;
  @Prop max: number = 0.75;
  @State dragStartRatio: number = 0.48;
  onResize: (ratio: number) => void = () => {};

  private clamp(value: number): number {
    return Math.max(this.min, Math.min(this.max, value));
  }

  build() {
    Row() {
      Row()
        .width(44)
        .height(2)
        .backgroundColor(ColorTokens.borderDefault)
        .borderRadius(1)
    }
    .width('100%')
    .height(8)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(ColorTokens.bgWorkspace)
    .border({ width: { top: 1, bottom: 1 }, color: ColorTokens.borderSubtle })
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2 })
          .onAction(() => this.onResize(0.48)),
        PanGesture({ direction: PanDirection.Vertical, distance: 1 })
          .onActionStart(() => {
            this.dragStartRatio = this.ratio;
          })
          .onActionUpdate((event: GestureEvent) => {
            const height = Math.max(1, this.availableHeight);
            this.onResize(this.clamp(this.dragStartRatio + event.offsetY / height));
          })
      )
    )
  }
}
