import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct CollectionNameDialog {
  @Prop title: ResourceStr = '';
  @Prop placeholder: ResourceStr = '';
  @Prop confirmLabel: ResourceStr = $r('app.string.action_create');
  @State name: string = '';
  onCancel: () => void = () => {};
  onConfirm: (name: string) => void = () => {};

  private submit(): void {
    const value = this.name.trim();
    if (value.length > 0) this.onConfirm(value);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim)
        .onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
          .width('100%')
        TextInput({ text: this.name, placeholder: this.placeholder })
          .height(SizeTokens.controlLarge)
          .fontSize(13)
          .fontColor(ColorTokens.textPrimary)
          .backgroundColor(ColorTokens.bgWorkspace)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium)
          .onChange((value: string) => { this.name = value; })
          .onSubmit(() => this.submit())
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          Button($r('app.string.action_cancel')).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
            .onClick(this.onCancel)
          Button(this.confirmLabel).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(this.name.trim().length > 0 ? ColorTokens.brand500 : ColorTokens.textTertiary)
            .borderRadius(RadiusTokens.medium).enabled(this.name.trim().length > 0)
            .onClick(() => this.submit())
        }.width('100%')
      }
      .width('90%').constraintSize({ maxWidth: 420 }).padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
  }
}
