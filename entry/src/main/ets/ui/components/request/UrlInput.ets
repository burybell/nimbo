import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct UrlInput {
  @Prop value: string = '';
  @Prop standalone: boolean = false;
  @Prop embedded: boolean = false;
  private controller: TextInputController = new TextInputController();
  onChange: (value: string) => void = () => {};
  onSubmit: () => void = () => {};

  private completeProtocol(): boolean {
    let completion = '';
    if (this.value === 'h') completion = 'http://';
    if (this.value === 'hs') completion = 'https://';
    if (completion.length === 0) return false;
    this.onChange(completion);
    setTimeout(() => this.controller.caretPosition(completion.length), 0);
    return true;
  }

  build() {
    TextInput({ text: this.value, placeholder: $r('app.string.request_url_placeholder'), controller: this.controller })
      .fontSize(14)
      .fontColor(ColorTokens.textPrimary)
      .placeholderColor(ColorTokens.textTertiary)
      .height(SizeTokens.controlLarge)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .backgroundColor(this.embedded ? Color.Transparent : ColorTokens.bgSurface)
      .border({ width: this.embedded ? 0 : (this.standalone ? 1 : { top: 1, right: 1, bottom: 1 }),
        color: ColorTokens.borderDefault })
      .borderRadius(this.embedded ? 0 : (this.standalone ? RadiusTokens.medium :
        { topRight: RadiusTokens.medium, bottomRight: RadiusTokens.medium }))
      .onChange((value: string) => this.onChange(value))
      .onSubmit(() => this.onSubmit())
      .onKeyEvent((event: KeyEvent) => {
        if (event.type === KeyType.Down && event.keyCode === 2049) return this.completeProtocol();
        return false;
      })
  }
}
