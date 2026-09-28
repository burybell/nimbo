import { ColorTokens } from '../../tokens/ColorTokens';
import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct RealtimePayloadView {
  @Prop value: string = '';

  private formattedJson(): string {
    const source = this.value.trim();
    if (source.length === 0) return '';
    try {
      const parsed = JSON.parse(source) as Object;
      return JSON.stringify(parsed, null, 2);
    } catch (_error) {
      return '';
    }
  }

  private editorHeight(value: string): number {
    const lines = Math.max(1, value.split('\n').length);
    return Math.min(260, Math.max(58, lines * 21 + 20));
  }

  build() {
    if (this.formattedJson().length > 0) {
      JsonCodeSurface({ value: this.formattedJson(), readOnly: true })
        .width('100%')
        .height(this.editorHeight(this.formattedJson()))
    } else {
      Text(this.value)
        .width('100%')
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor(ColorTokens.textPrimary)
        .copyOption(CopyOptions.LocalDevice)
    }
  }
}
