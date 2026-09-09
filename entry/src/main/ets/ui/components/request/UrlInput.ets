import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct UrlInput {
  @Prop value: string = '';
  onChange: (value: string) => void = () => {};
  onSubmit: () => void = () => {};

  build() {
    TextInput({ text: this.value, placeholder: $r('app.string.request_url_placeholder') })
      .fontSize(14)
      .fontColor(ColorTokens.textPrimary)
      .placeholderColor(ColorTokens.textTertiary)
      .height(SizeTokens.controlLarge)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: { top: 1, bottom: 1 }, color: ColorTokens.borderDefault })
      .borderRadius(0)
      .onChange((value: string) => this.onChange(value))
      .onSubmit(() => this.onSubmit())
  }
}
