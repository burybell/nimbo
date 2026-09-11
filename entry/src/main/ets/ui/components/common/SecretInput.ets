import { KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { VariableTextInput } from '../request/VariableTextInput';

@Component
export struct SecretInput {
  @Prop value: string = '';
  @Prop placeholder: ResourceStr = $r('app.string.secret_placeholder');
  @Prop variables: KeyValueItem[] = [];
  @Prop inputId: string = '';
  @State revealed: boolean = false;
  onChange: (value: string) => void = () => {};

  private maskable(): boolean {
    return this.value.trim().length > 0 && !this.value.includes('{{');
  }

  private plainTextMode(): boolean {
    return !this.maskable() || this.revealed;
  }

  build() {
    Row() {
      if (this.plainTextMode()) {
        VariableTextInput({
          value: this.value,
          variables: this.variables,
          inputId: this.inputId,
          fontSize: 13,
          fillColor: ColorTokens.bgSurface,
          placeholder: this.placeholder,
          onChange: (value: string) => {
            if (value.trim().length > 0 && !value.includes('{{')) this.revealed = true;
            this.onChange(value);
          },
          onLoseFocus: () => {
            setTimeout(() => {
              if (this.maskable()) this.revealed = false;
            }, 180);
          }
        })
          .layoutWeight(1)
      } else {
        TextInput({ text: this.value, placeholder: this.placeholder })
          .id(this.inputId)
          .type(InputType.Password)
          .showPasswordIcon(false)
          .fontSize(13)
          .fontColor(ColorTokens.textPrimary)
          .placeholderColor(ColorTokens.textTertiary)
          .height(SizeTokens.controlMedium)
          .padding({ left: SpacingTokens.x3 })
          .backgroundColor(ColorTokens.bgSurface)
          .borderRadius(RadiusTokens.small)
          .layoutWeight(1)
          .onChange((value: string) => {
            if (value.trim().length === 0 || value.includes('{{')) {
              this.revealed = true;
              setTimeout(() => focusControl.requestFocus(this.inputId), 0);
            }
            this.onChange(value);
          })
      }

      if (this.maskable()) {
        Text(this.revealed ? $r('app.string.hide') : $r('app.string.show'))
          .fontSize(11)
          .fontColor(ColorTokens.brand600)
          .width(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.revealed = !this.revealed;
            if (this.revealed) setTimeout(() => focusControl.requestFocus(this.inputId), 0);
          })
      } else {
        Blank().width(48)
      }
    }
    .height(SizeTokens.controlMedium)
    .width('100%')
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderDefault })
    .borderRadius(RadiusTokens.small)
  }
}
