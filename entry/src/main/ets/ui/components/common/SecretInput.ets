import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct SecretInput {
  @Prop value: string = '';
  @Prop placeholder: ResourceStr = $r('app.string.secret_placeholder');
  @State revealed: boolean = false;
  onChange: (value: string) => void = () => {};

  build() {
    Row() {
      TextInput({ text: this.value, placeholder: this.placeholder })
        .type(this.revealed ? InputType.Normal : InputType.Password)
        .showPasswordIcon(false)
        .fontSize(13)
        .fontColor(ColorTokens.textPrimary)
        .placeholderColor(ColorTokens.textTertiary)
        .height(SizeTokens.controlMedium)
        .padding({ left: SpacingTokens.x3 })
        .backgroundColor(ColorTokens.bgSurface)
        .borderRadius(RadiusTokens.small)
        .layoutWeight(1)
        .onChange((value: string) => this.onChange(value))
        .onBlur(() => {
          this.revealed = false;
        })

      Text(this.revealed ? $r('app.string.hide') : $r('app.string.show'))
        .fontSize(11)
        .fontColor(ColorTokens.brand600)
        .width(48)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.revealed = !this.revealed;
        })
    }
    .height(SizeTokens.controlMedium)
    .width('100%')
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderDefault })
    .borderRadius(RadiusTokens.small)
  }
}
