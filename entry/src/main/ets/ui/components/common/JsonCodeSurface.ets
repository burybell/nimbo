import { LengthMetrics } from '@kit.ArkUI';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface JsonToken {
  start: number;
  length: number;
  color: ResourceColor;
}

@Component
export struct JsonCodeSurface {
  @Watch('handleExternalValue') @Prop value: string = '';
  @Prop readOnly: boolean = false;
  @Prop wrap: boolean = true;
  @Watch('handleVisualChange') @Prop query: string = '';
  onChange: (value: string) => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';

  private lineNumbers(): string {
    const count = Math.max(1, this.value.split('\n').length);
    const values: string[] = [];
    for (let index = 1; index <= count; index += 1) values.push(index.toString());
    return values.join('\n');
  }

  private isWhitespace(character: string): boolean {
    return character === ' ' || character === '\n' || character === '\r' || character === '\t';
  }

  private isDigit(character: string): boolean {
    return character >= '0' && character <= '9';
  }

  private nextNonWhitespace(source: string, offset: number): string {
    let index = offset;
    while (index < source.length && this.isWhitespace(source[index])) index += 1;
    return index < source.length ? source[index] : '';
  }

  private tokens(source: string): JsonToken[] {
    const tokens: JsonToken[] = [];
    let index = 0;
    while (index < source.length) {
      const character = source[index];
      if (character === '"') {
        const start = index;
        index += 1;
        let escaped = false;
        while (index < source.length) {
          const current = source[index];
          index += 1;
          if (escaped) {
            escaped = false;
          } else if (current === '\\') {
            escaped = true;
          } else if (current === '"') {
            break;
          }
        }
        const key = this.nextNonWhitespace(source, index) === ':';
        tokens.push({ start, length: index - start,
          color: key ? ColorTokens.codeKey : ColorTokens.codeString });
        continue;
      }
      if (this.isDigit(character) || (character === '-' && index + 1 < source.length &&
        this.isDigit(source[index + 1]))) {
        const start = index;
        index += 1;
        while (index < source.length) {
          const current = source[index];
          if (!this.isDigit(current) && current !== '.' && current !== 'e' && current !== 'E' &&
            current !== '+' && current !== '-') break;
          index += 1;
        }
        tokens.push({ start, length: index - start, color: ColorTokens.codeNumber });
        continue;
      }
      if (source.startsWith('true', index) || source.startsWith('null', index)) {
        tokens.push({ start: index, length: 4, color: ColorTokens.codeLiteral });
        index += 4;
        continue;
      }
      if (source.startsWith('false', index)) {
        tokens.push({ start: index, length: 5, color: ColorTokens.codeLiteral });
        index += 5;
        continue;
      }
      if (character === '{' || character === '}' || character === '[' || character === ']' ||
        character === ':' || character === ',') {
        tokens.push({ start: index, length: 1, color: ColorTokens.codePunctuation });
      }
      index += 1;
    }
    return tokens;
  }

  private fontStyle(color: ResourceColor, weight: FontWeight = FontWeight.Regular): TextStyle {
    return new TextStyle({
      fontColor: color,
      fontFamily: 'monospace',
      fontSize: LengthMetrics.fp(13),
      fontWeight: weight
    });
  }

  private styledValue(source: string): StyledString {
    const styles: StyleOptions[] = [];
    if (source.length > 0) {
      styles.push({ start: 0, length: source.length, styledKey: StyledStringKey.FONT,
        styledValue: this.fontStyle(ColorTokens.codeText) });
      styles.push({ start: 0, length: source.length, styledKey: StyledStringKey.LINE_HEIGHT,
        styledValue: new LineHeightStyle(LengthMetrics.vp(21)) });
    }
    this.tokens(source).forEach((token: JsonToken) => {
      styles.push({ start: token.start, length: token.length, styledKey: StyledStringKey.FONT,
        styledValue: this.fontStyle(token.color, token.color === ColorTokens.codeKey ?
          FontWeight.Medium : FontWeight.Regular) });
    });
    if (this.query.length > 0) {
      const lowerSource = source.toLowerCase();
      const lowerQuery = this.query.toLowerCase();
      let offset = 0;
      while (offset < source.length) {
        const match = lowerSource.indexOf(lowerQuery, offset);
        if (match < 0) break;
        styles.push({ start: match, length: this.query.length, styledKey: StyledStringKey.BACKGROUND_COLOR,
          styledValue: new BackgroundColorStyle({ color: ColorTokens.codeSearchMatch, radius: 2 }) });
        offset = match + this.query.length;
      }
    }
    return new StyledString(source, styles);
  }

  private applyStyledValue(source: string, preserveCaret: boolean): void {
    const caret = preserveCaret ? this.controller.getCaretOffset() : 0;
    this.displayedValue = source;
    this.controller.setStyledString(this.styledValue(source));
    this.controller.setCaretOffset(Math.min(caret, source.length));
  }

  private handleExternalValue(): void {
    if (this.value !== this.displayedValue) this.applyStyledValue(this.value, true);
  }

  private handleVisualChange(): void {
    this.applyStyledValue(this.displayedValue, true);
  }

  private contentChanged(): void {
    const content = this.controller.getStyledString().getString();
    if (content === this.displayedValue) return;
    this.displayedValue = content;
    this.onChange(content);
    this.applyStyledValue(content, true);
  }

  build() {
    Row() {
      Text(this.lineNumbers())
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor(ColorTokens.codeLineNumber)
        .lineHeight(21)
        .width(46)
        .height('100%')
        .padding({ top: SpacingTokens.x3, right: SpacingTokens.x2, bottom: SpacingTokens.x3 })
        .textAlign(TextAlign.End)
        .backgroundColor(ColorTokens.codeGutter)
      RichEditor({ controller: this.controller })
        .layoutWeight(1)
        .height('100%')
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3,
          top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
        .backgroundColor(ColorTokens.codeBackground)
        .caretColor(ColorTokens.brand500)
        .selectedBackgroundColor(ColorTokens.codeSelection)
        .copyOptions(CopyOptions.LocalDevice)
        .enableKeyboardOnFocus(!this.readOnly)
        .placeholder('{\n  "key": "value"\n}', { fontColor: ColorTokens.codeLineNumber })
        .onWillChange((_change: RichEditorChangeValue) => !this.readOnly)
        .onDidChange((_before: TextRange, _after: TextRange) => this.contentChanged())
        .onAppear(() => this.applyStyledValue(this.value, false))
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor(ColorTokens.codeBackground)
    .borderRadius(RadiusTokens.small)
    .clip(true)
  }
}
