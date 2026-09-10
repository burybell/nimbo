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
  @Prop syntaxHighlight: boolean = true;
  @Watch('handleVisualChange') @Prop query: string = '';
  @Watch('handleSearchNavigation') @Prop searchIndex: number = 0;
  @Watch('handleSearchNavigation') @Prop searchRevision: number = 0;
  onChange: (value: string) => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';
  private applyingStyle: boolean = false;
  private listenerRegistered: boolean = false;
  private highlightTimer: number = -1;

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
    if (this.syntaxHighlight) {
      this.tokens(source).forEach((token: JsonToken) => {
        styles.push({ start: token.start, length: token.length, styledKey: StyledStringKey.FONT,
          styledValue: this.fontStyle(token.color, token.color === ColorTokens.codeKey ?
            FontWeight.Medium : FontWeight.Regular) });
      });
    }
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

  private handleVisualChange(): void {
    this.applyStyledValue(this.displayedValue, true);
  }

  private handleSearchNavigation(): void {
    if (this.query.length === 0 || this.displayedValue.length === 0) return;
    const source = this.displayedValue.toLowerCase();
    const needle = this.query.toLowerCase();
    let matchIndex = 0;
    let offset = 0;
    while (offset < source.length) {
      const match = source.indexOf(needle, offset);
      if (match < 0) return;
      if (matchIndex === this.searchIndex) {
        this.controller.setSelection(match, match + this.query.length);
        return;
      }
      matchIndex += 1;
      offset = match + needle.length;
    }
  }

  private scheduleHighlight(): void {
    if (this.highlightTimer >= 0) clearTimeout(this.highlightTimer);
    this.highlightTimer = setTimeout(() => {
      this.highlightTimer = -1;
      const content = this.controller.getStyledString().getString();
      if (content === this.displayedValue) this.applyStyledValue(content, true);
    }, 120);
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

  private isInsideString(source: string, offset: number): boolean {
    let inside = false;
    let escaped = false;
    for (let index = 0; index < offset; index += 1) {
      const character = source[index];
      if (escaped) {
        escaped = false;
      } else if (character === '\\') {
        escaped = true;
      } else if (character === '"') {
        inside = !inside;
      }
    }
    return inside;
  }

  private closingCharacter(character: string): string {
    if (character === '{') return '}';
    if (character === '[') return ']';
    if (character === '(') return ')';
    if (character === '"') return '"';
    return '';
  }

  private openingCharacter(character: string): string {
    if (character === '}') return '{';
    if (character === ']') return '[';
    if (character === ')') return '(';
    if (character === '"') return '"';
    return '';
  }

  private isClosingCharacter(character: string): boolean {
    return character === '}' || character === ']' || character === ')' || character === '"';
  }

  private replaceEditorValue(current: string, start: number, end: number, replacement: string,
    caretOffset: number, selectionLength: number = 0): void {
    const next = current.substring(0, start) + replacement + current.substring(end);
    this.displayedValue = next;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(next));
    if (selectionLength > 0) {
      this.controller.setSelection(caretOffset, caretOffset + selectionLength);
    } else {
      this.controller.setCaretOffset(caretOffset);
    }
    this.applyingStyle = false;
    this.onChange(next);
  }

  private replaceWithPair(current: string, start: number, end: number,
    opening: string, closing: string): void {
    const selected = current.substring(start, end);
    this.replaceEditorValue(current, start, end, opening + selected + closing,
      start + 1, selected.length);
  }

  private lineIndent(source: string, offset: number): string {
    const lineStart = source.lastIndexOf('\n', Math.max(0, offset - 1)) + 1;
    let index = lineStart;
    while (index < source.length && index < offset && (source[index] === ' ' || source[index] === '\t')) {
      index += 1;
    }
    return source.substring(lineStart, index).replace(/\t/g, '  ');
  }

  private previousNonWhitespace(source: string, offset: number): string {
    let index = offset - 1;
    while (index >= 0 && this.isWhitespace(source[index])) index -= 1;
    return index >= 0 ? source[index] : '';
  }

  private consumeNewline(current: string, start: number, end: number): void {
    const indent = this.lineIndent(current, start);
    const previous = this.previousNonWhitespace(current, start);
    const next = this.nextNonWhitespace(current, end);
    const closesPair = this.closingCharacter(previous) === next;
    if (closesPair) {
      const innerIndent = indent + '  ';
      const replacement = `\n${innerIndent}\n${indent}`;
      this.replaceEditorValue(current, start, end, replacement, start + 1 + innerIndent.length);
      return;
    }
    const nextIndent = previous === '{' || previous === '[' ? indent + '  ' : indent;
    const replacement = `\n${nextIndent}`;
    this.replaceEditorValue(current, start, end, replacement, start + replacement.length);
  }

  private consumeColon(current: string, start: number, end: number): boolean {
    if (start !== end || this.isInsideString(current, start)) return false;
    const next = current[start] ?? '';
    const replacement = next === ' ' || next === '\t' ? ':' : ': ';
    this.replaceEditorValue(current, start, end, replacement, start + replacement.length);
    return true;
  }

  private consumePairedInput(current: string, start: number, end: number, character: string): boolean {
    if (character === '\n') {
      this.consumeNewline(current, start, end);
      return true;
    }
    if (character === ':') return this.consumeColon(current, start, end);
    if (character.length !== 1) return false;
    if (start === end && this.isClosingCharacter(character) && current[start] === character) {
      this.controller.setCaretOffset(start + 1);
      return true;
    }
    const closing = this.closingCharacter(character);
    if (closing.length === 0 || (character === '"' && start === end && this.isInsideString(current, start))) {
      return false;
    }
    this.replaceWithPair(current, start, end, character, closing);
    return true;
  }

  private beforeDelete(value: RichEditorDeleteValue): boolean {
    if (this.readOnly) return false;
    const selection = this.controller.getSelection();
    const selectionStart = selection.start ?? 0;
    const selectionEnd = selection.end ?? selectionStart;
    if (selectionStart !== selectionEnd || value.direction !== RichEditorDeleteDirection.BACKWARD ||
      value.length !== 1) return true;
    const caret = this.controller.getCaretOffset();
    if (caret <= 0) return true;
    const current = this.controller.getStyledString().getString();
    const opening = current[caret - 1];
    const closing = current[caret];
    if (this.closingCharacter(opening) !== closing || this.openingCharacter(closing) !== opening) return true;
    this.replaceEditorValue(current, caret - 1, caret + 1, '', caret - 1);
    return false;
  }

  private consumeTab(outdent: boolean): void {
    const current = this.controller.getStyledString().getString();
    const selection = this.controller.getSelection();
    const rawStart = selection.start ?? this.controller.getCaretOffset();
    const rawEnd = selection.end ?? rawStart;
    const start = Math.min(rawStart, rawEnd);
    const end = Math.max(rawStart, rawEnd);
    if (!outdent) {
      if (start === end) {
        this.replaceEditorValue(current, start, end, '  ', start + 2);
        return;
      }
      const lineStart = current.lastIndexOf('\n', Math.max(0, start - 1)) + 1;
      const selectedLines = current.substring(lineStart, end);
      const replacement = '  ' + selectedLines.split('\n').join('\n  ');
      this.replaceEditorValue(current, lineStart, end, replacement, lineStart, replacement.length);
      return;
    }
    const lineStart = current.lastIndexOf('\n', Math.max(0, start - 1)) + 1;
    const selectedLines = current.substring(lineStart, end);
    const lines = selectedLines.split('\n');
    let replacement = '';
    let removed = 0;
    let firstRemoved = 0;
    lines.forEach((line: string, index: number) => {
      let removeCount = 0;
      if (line.startsWith('\t')) removeCount = 1;
      else if (line.startsWith('  ')) removeCount = 2;
      else if (line.startsWith(' ')) removeCount = 1;
      if (index === 0) firstRemoved = removeCount;
      removed += removeCount;
      if (index > 0) replacement += '\n';
      replacement += line.substring(removeCount);
    });
    if (removed === 0) return;
    if (start === end) {
      this.replaceEditorValue(current, lineStart, end, replacement,
        Math.max(lineStart, start - firstRemoved));
    } else {
      this.replaceEditorValue(current, lineStart, end, replacement, lineStart, replacement.length);
    }
  }

  private beforeInput(value: RichEditorInsertValue): boolean {
    if (this.readOnly) return false;
    if (value.insertValue.length !== 1) return true;
    const current = this.controller.getStyledString().getString();
    const selection: RichEditorRange = this.controller.getSelection();
    const selectionStart = selection.start ?? value.insertOffset;
    const selectionEnd = selection.end ?? selectionStart;
    const start = selectionStart === selectionEnd ? value.insertOffset : Math.min(selectionStart, selectionEnd);
    const end = selectionStart === selectionEnd ? value.insertOffset : Math.max(selectionStart, selectionEnd);
    return !this.consumePairedInput(current, start, end, value.insertValue);
  }

  private willChange(change: StyledStringChangeValue): boolean {
    if (this.readOnly) return false;
    if (this.applyingStyle) return true;
    const current = this.controller.getStyledString().getString();
    const start = change.range.start ?? 0;
    const end = change.range.end ?? start;
    const replacement = change.replacementString.getString();
    if (this.consumePairedInput(current, start, end, replacement)) return false;
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
        .aboutToIMEInput((value: RichEditorInsertValue) => this.beforeInput(value))
        .aboutToDelete((value: RichEditorDeleteValue) => this.beforeDelete(value))
        .onKeyEvent((event: KeyEvent) => {
          if (!this.readOnly && event.type === KeyType.Down && event.keyCode === 2054) {
            const sending = event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl']);
            if (sending) return false;
            const selection = this.controller.getSelection();
            const rawStart = selection.start ?? this.controller.getCaretOffset();
            const rawEnd = selection.end ?? rawStart;
            this.consumeNewline(this.controller.getStyledString().getString(),
              Math.min(rawStart, rawEnd), Math.max(rawStart, rawEnd));
            return true;
          }
          if (!this.readOnly && event.type === KeyType.Down && event.keyCode === 2049) {
            const outdent = event.getModifierKeyState !== undefined && event.getModifierKeyState(['shift']);
            this.consumeTab(outdent);
            return true;
          }
          return false;
        })
        .onAppear(() => {
          this.registerContentListener();
          this.applyStyledValue(this.value, false);
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor(ColorTokens.codeBackground)
    .borderRadius(RadiusTokens.small)
    .clip(true)
  }
}
