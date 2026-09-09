import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct JsonEditor {
  @Prop value: string = '';
  @Prop readOnly: boolean = false;
  @State wrap: boolean = true;
  @State validation: string = '';
  onChange: (value: string) => void = () => {};

  private lineNumbers(): string {
    const count = Math.max(1, this.value.split('\n').length);
    const values: string[] = [];
    for (let index = 1; index <= count; index += 1) {
      values.push(index.toString());
    }
    return values.join('\n');
  }

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
        Button('Format')
          .fontSize(11)
          .fontColor(ColorTokens.textSecondary)
          .height(26)
          .backgroundColor(ColorTokens.bgWorkspace)
          .onClick(() => this.formatJson(false))
        Button('Minify')
          .fontSize(11)
          .fontColor(ColorTokens.textSecondary)
          .height(26)
          .backgroundColor(ColorTokens.bgWorkspace)
          .onClick(() => this.formatJson(true))
        Button(this.wrap ? 'Wrap On' : 'Wrap Off')
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

      Row() {
        Text(this.lineNumbers())
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor(ColorTokens.textTertiary)
          .lineHeight(21)
          .width(44)
          .height('100%')
          .padding({ top: 10, right: SpacingTokens.x2 })
          .textAlign(TextAlign.End)
          .backgroundColor(ColorTokens.bgApp)
        TextArea({ text: this.value, placeholder: '{\n  "key": "value"\n}' })
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor(ColorTokens.textPrimary)
          .lineHeight(21)
          .height('100%')
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: 8, bottom: 8 })
          .backgroundColor(ColorTokens.bgWorkspace)
          .layoutWeight(1)
          .enabled(!this.readOnly)
          .onChange((value: string) => {
            this.validation = '';
            this.onChange(value);
          })
      }
      .layoutWeight(1)
      .width('100%')

      if (this.validation.length > 0) {
        Text(this.validation)
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .width('100%')
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: 7, bottom: 7 })
          .backgroundColor('#FFF3F3')
          .border({ width: { top: 1 }, color: '#FFDADA' })
      }
    }
    .width('100%')
    .height('100%')
    .border({ width: 1, color: this.validation.length > 0 ? ColorTokens.httpDelete : ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.small)
  }
}
