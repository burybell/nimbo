import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct JsonEditor {
  @Prop value: string = '';
  @Prop readOnly: boolean = false;
  @State wrap: boolean = true;
  @State validation: string = '';
  onChange: (value: string) => void = () => {};

  private formatJson(compact: boolean): void {
    if (this.value.trim().length === 0) {
      this.validation = '';
      return;
    }
    try {
      const parsed: Object = JSON.parse(this.value);
      const formatted = compact ? JSON.stringify(parsed) : JSON.stringify(parsed, null, 2);
      this.validation = '';
      this.onChange(formatted);
    } catch (error) {
      this.validation = 'Invalid JSON. Check commas, quotes, and brackets.';
    }
  }

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Text('JSON')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.brand600)
        Blank()
        Button($r('app.string.action_format'))
          .fontSize(11)
          .fontColor(ColorTokens.textSecondary)
          .height(26)
          .backgroundColor(ColorTokens.bgWorkspace)
          .onClick(() => this.formatJson(false))
        Button($r('app.string.action_minify'))
          .fontSize(11)
          .fontColor(ColorTokens.textSecondary)
          .height(26)
          .backgroundColor(ColorTokens.bgWorkspace)
          .onClick(() => this.formatJson(true))
        Button(this.wrap ? $r('app.string.wrap_on') : $r('app.string.wrap_off'))
          .fontSize(11)
          .fontColor(this.wrap ? ColorTokens.brand600 : ColorTokens.textSecondary)
          .height(26)
          .backgroundColor(this.wrap ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            this.wrap = !this.wrap;
          })
      }
      .height(38)
      .width('100%')
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
      .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

      JsonCodeSurface({
        value: this.value,
        readOnly: this.readOnly,
        wrap: this.wrap,
        onChange: (value: string) => {
          this.validation = '';
          this.onChange(value);
        }
      })
      .layoutWeight(1)
      .width('100%')

      if (this.validation.length > 0) {
        Text(this.validation)
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .width('100%')
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: 7, bottom: 7 })
          .backgroundColor(ColorTokens.statusDangerBackground)
          .border({ width: { top: 1 }, color: ColorTokens.statusDangerBorder })
      }
    }
    .width('100%')
    .height('100%')
    .border({ width: 1, color: this.validation.length > 0 ? ColorTokens.httpDelete : ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.small)
  }
}
