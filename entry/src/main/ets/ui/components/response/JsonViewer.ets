import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct JsonViewer {
  @Prop value: string = '';
  @State searchVisible: boolean = false;
  @State query: string = '';

  private matchCount(): number {
    if (this.query.length === 0) return 0;
    let count = 0;
    let offset = 0;
    const source = this.value.toLowerCase();
    const needle = this.query.toLowerCase();
    while (offset < source.length) {
      const found = source.indexOf(needle, offset);
      if (found < 0) break;
      count += 1;
      offset = found + needle.length;
    }
    return count;
  }

  build() {
    Column() {
      if (this.searchVisible) {
        Row({ space: SpacingTokens.x2 }) {
          TextInput({ text: this.query, placeholder: $r('app.string.search_response') })
            .fontSize(12)
            .height(28)
            .layoutWeight(1)
            .backgroundColor(ColorTokens.bgSurface)
            .borderRadius(RadiusTokens.small)
            .onChange((value: string) => {
              this.query = value;
            })
          Row({ space: SpacingTokens.x1 }) {
            Text(`${this.matchCount()}`).fontSize(11).fontColor(ColorTokens.codeText)
            Text($r('app.string.matches')).fontSize(11).fontColor(ColorTokens.codeText)
          }
          Text('×')
            .fontSize(16)
            .fontColor(ColorTokens.codeText)
            .width(24)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.searchVisible = false;
              this.query = '';
            })
        }
        .height(36)
        .width('100%')
        .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
        .backgroundColor(ColorTokens.codeGutter)
      }

      JsonCodeSurface({ value: this.value, readOnly: true, query: this.query })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.codeBackground)
    .borderRadius(RadiusTokens.small)
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyText.toLowerCase() === 'f' &&
        event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
        this.searchVisible = true;
        return true;
      }
      return false;
    })
  }
}
