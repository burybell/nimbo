import { LengthMetrics } from '@kit.ArkUI';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface CurlToken {
  start: number;
  length: number;
  color: ResourceColor;
  emphasized: boolean;
}

@Component
export struct CurlCodeSurface {
  @Watch('handleExternalValue') @Prop value: string = '';
  @Prop invalid: boolean = false;
  onChange: (value: string) => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';
  private applyingStyle: boolean = false;
  private listenerRegistered: boolean = false;
  private highlightTimer: number = -1;

  private isWhitespace(character: string): boolean {
    return character === ' ' || character === '\n' || character === '\r' || character === '\t';
  }

  private methodColor(value: string): ResourceColor | undefined {
    const method = value.toUpperCase();
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    if (method === 'HEAD' || method === 'OPTIONS') return ColorTokens.httpOther;
    return undefined;
  }

  private classify(start: number, length: number, rawValue: string, quoted: boolean): CurlToken {
    const value = quoted && rawValue.length >= 2 ? rawValue.substring(1, rawValue.length - 1) : rawValue;
    if (value === 'curl') {
      return { start, length, color: ColorTokens.codeKey, emphasized: true };
    }
    if (!quoted && value.startsWith('-')) {
      return { start, length, color: ColorTokens.codeLiteral, emphasized: true };
    }
    const method = this.methodColor(value);
    if (method !== undefined) {
      return { start, length, color: method, emphasized: true };
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return { start, length, color: ColorTokens.codeKey, emphasized: false };
    }
    if (value.startsWith('{{') && value.endsWith('}}')) {
      return { start, length, color: ColorTokens.codeNumber, emphasized: false };
    }
    return { start, length, color: quoted ? ColorTokens.codeString : ColorTokens.codeText,
      emphasized: false };
  }

  private tokens(source: string): CurlToken[] {
    const tokens: CurlToken[] = [];
    let index = 0;
    while (index < source.length) {
      const character = source[index];
      if (this.isWhitespace(character)) {
        index += 1;
        continue;
      }
      if (character === '\\') {
        tokens.push({ start: index, length: 1, color: ColorTokens.codePunctuation, emphasized: false });
        index += 1;
        continue;
      }
      const start = index;
      if (character === '"' || character === "'") {
        const quote = character;
        index += 1;
        let escaped = false;
        while (index < source.length) {
          const current = source[index];
          index += 1;
          if (escaped) {
            escaped = false;
          } else if (current === '\\' && quote === '"') {
            escaped = true;
          } else if (current === quote) {
            break;
          }
        }
        tokens.push(this.classify(start, index - start, source.substring(start, index), true));
        continue;
      }
      index += 1;
      while (index < source.length && !this.isWhitespace(source[index]) && source[index] !== '\\') index += 1;
      tokens.push(this.classify(start, index - start, source.substring(start, index), false));
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
    this.tokens(source).forEach((token: CurlToken) => {
      styles.push({ start: token.start, length: token.length, styledKey: StyledStringKey.FONT,
        styledValue: this.fontStyle(token.color, token.emphasized ? FontWeight.Medium : FontWeight.Regular) });
    });
    return new StyledString(source, styles);
  }

  private applyStyledValue(source: string, preserveCaret: boolean): void {
    if (this.highlightTimer >= 0) {
      clearTimeout(this.highlightTimer);
      this.highlightTimer = -1;
    }
    const caret = preserveCaret ? this.controller.getCaretOffset() : 0;
    this.displayedValue = source;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(source));
    this.controller.setCaretOffset(Math.min(caret, source.length));
    this.applyingStyle = false;
  }

  private handleExternalValue(): void {
    if (this.value !== this.displayedValue) this.applyStyledValue(this.value, true);
  }

  private scheduleHighlight(): void {
    if (this.highlightTimer >= 0) clearTimeout(this.highlightTimer);
    this.highlightTimer = setTimeout(() => {
      this.highlightTimer = -1;
      const content = this.controller.getStyledString().getString();
      if (content === this.displayedValue) this.applyStyledValue(content, true);
    }, 100);
  }

  private contentChanged(): void {
    if (this.applyingStyle) return;
    const content = this.controller.getStyledString().getString();
    if (content !== this.displayedValue) {
      this.displayedValue = content;
      this.onChange(content);
    }
    this.scheduleHighlight();
  }

  private willChange(change: StyledStringChangeValue): boolean {
    if (this.applyingStyle) return true;
    const current = this.controller.getStyledString().getString();
    const start = change.range.start ?? 0;
    const end = change.range.end ?? start;
    const replacement = change.replacementString.getString();
    const next = current.substring(0, start) + replacement + current.substring(end);
    this.displayedValue = next;
    this.onChange(next);
    return true;
  }

  private registerContentListener(): void {
    if (this.listenerRegistered) return;
    this.listenerRegistered = true;
    this.controller.onContentChanged({
      onWillChange: (change: StyledStringChangeValue): boolean => this.willChange(change),
      onDidChange: (_before: TextRange, _after: TextRange): void => this.contentChanged()
    });
  }

  private lineNumbers(): string {
    const count = Math.max(1, this.value.split('\n').length);
    const values: string[] = [];
    for (let index = 1; index <= count; index += 1) values.push(index.toString());
    return values.join('\n');
  }

  build() {
    Row() {
      Column() {
        Text(this.lineNumbers())
          .fontSize(12).fontFamily('monospace').fontColor(ColorTokens.codeLineNumber)
          .lineHeight(21).width('100%')
          .padding({ top: SpacingTokens.x3, right: SpacingTokens.x2 })
          .textAlign(TextAlign.End)
      }
      .width(42).height('100%').alignItems(HorizontalAlign.End)
      .backgroundColor(ColorTokens.codeGutter)
      RichEditor({ controller: this.controller })
        .layoutWeight(1).height('100%')
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3,
          top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
        .backgroundColor(ColorTokens.codeBackground)
        .caretColor(ColorTokens.brand500)
        .selectedBackgroundColor(ColorTokens.codeSelection)
        .copyOptions(CopyOptions.LocalDevice)
        .placeholder('curl https://api.example.com/users', { fontColor: ColorTokens.codeLineNumber })
        .onAppear(() => {
          this.registerContentListener();
          this.applyStyledValue(this.value, false);
        })
    }
    .width('100%').height('100%').alignItems(VerticalAlign.Top)
    .backgroundColor(ColorTokens.codeBackground)
    .border({ width: 1, color: this.invalid ? ColorTokens.httpDelete : ColorTokens.borderDefault })
    .borderRadius(RadiusTokens.medium).clip(true)
  }
}
