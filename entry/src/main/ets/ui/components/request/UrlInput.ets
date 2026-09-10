import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct UrlInput {
  @Prop value: string = '';
  @Prop standalone: boolean = false;
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
      .border({ width: this.standalone ? 1 : { top: 1, right: 1, bottom: 1 },
        color: ColorTokens.borderDefault })
      .borderRadius(this.standalone ? RadiusTokens.medium :
        { topRight: RadiusTokens.medium, bottomRight: RadiusTokens.medium })
      .onChange((value: string) => this.onChange(value))
      .onSubmit(() => this.onSubmit())
  }
}
