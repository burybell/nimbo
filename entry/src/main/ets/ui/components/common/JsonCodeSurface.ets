import { LengthMetrics } from '@kit.ArkUI';
import { KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface JsonToken {
  start: number;
  length: number;
  color: ResourceColor;
}

export type CodeLanguage = 'json' | 'javascript' | 'python' | 'go';
export type JavaScriptCompletionScope = 'all' | 'preRequest' | 'postResponse';

interface CodeCompletion {
  label: string;
  insertText: string;
  caretBack: number;
  variable?: boolean;
  secret?: boolean;
}

@Component
export struct JsonCodeSurface {
  @Watch('handleExternalValue') @Prop value: string = '';
  @Prop readOnly: boolean = false;
  @Prop wrap: boolean = true;
  @Watch('handleVisualChange') @Prop syntaxHighlight: boolean = true;
  @Watch('handleVisualChange') @Prop language: CodeLanguage = 'json';
  @Prop completionScope: JavaScriptCompletionScope = 'all';
  @Prop variables: KeyValueItem[] = [];
  @Prop placeholder: ResourceStr = '{\n  "key": "value"\n}';
  @Watch('handleVisualChange') @Prop query: string = '';
  @Watch('handleSearchNavigation') @Prop searchIndex: number = 0;
  @Watch('handleSearchNavigation') @Prop searchRevision: number = 0;
  onChange: (value: string) => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';
  private applyingStyle: boolean = false;
  private listenerRegistered: boolean = false;
  private highlightTimer: number = -1;
  private undoValues: string[] = [];
  private redoValues: string[] = [];
  private historyApplying: boolean = false;
  private completionScroller: Scroller = new Scroller();
  @State completionItems: CodeCompletion[] = [];
  @State completionIndex: number = 0;
  @State completionStart: number = 0;
  @State completionPrefix: string = '';

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

  private jsonTokens(source: string): JsonToken[] {
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

  private isIdentifierStart(character: string): boolean {
    return (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') ||
      character === '_' || character === '$';
  }

  private isIdentifierPart(character: string): boolean {
    return this.isIdentifierStart(character) || this.isDigit(character);
  }

  private isJavaScriptKeyword(value: string): boolean {
    return ['break', 'case', 'catch', 'class', 'const', 'continue', 'debugger', 'default', 'delete',
      'do', 'else', 'export', 'extends', 'finally', 'for', 'function', 'if', 'import', 'in',
      'instanceof', 'let', 'new', 'return', 'switch', 'throw', 'try', 'typeof', 'var', 'void',
      'while', 'with', 'yield', 'async', 'await', 'of'].includes(value);
  }

  private isPythonKeyword(value: string): boolean {
    return ['and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue', 'def', 'del',
      'elif', 'else', 'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is',
      'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with',
      'yield'].includes(value);
  }

  private isGoKeyword(value: string): boolean {
    return ['break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else', 'fallthrough',
      'for', 'func', 'go', 'goto', 'if', 'import', 'interface', 'map', 'package', 'range', 'return',
      'select', 'struct', 'switch', 'type', 'var'].includes(value);
  }

  private isCodeKeyword(value: string): boolean {
    if (this.language === 'python') return this.isPythonKeyword(value);
    if (this.language === 'go') return this.isGoKeyword(value);
    return this.isJavaScriptKeyword(value);
  }

  private javascriptTokens(source: string): JsonToken[] {
    const tokens: JsonToken[] = [];
    let index = 0;
    while (index < source.length) {
      const character = source[index];
      if ((this.language === 'python' && character === '#') ||
        (this.language !== 'python' && character === '/' && source[index + 1] === '/')) {
        const start = index;
        index += this.language === 'python' ? 1 : 2;
        while (index < source.length && source[index] !== '\n') index += 1;
        tokens.push({ start, length: index - start, color: ColorTokens.codeLineNumber });
        continue;
      }
      if (this.language !== 'python' && character === '/' && source[index + 1] === '*') {
        const start = index;
        index += 2;
        while (index < source.length && !(source[index] === '*' && source[index + 1] === '/')) index += 1;
        index = Math.min(source.length, index + 2);
        tokens.push({ start, length: index - start, color: ColorTokens.codeLineNumber });
        continue;
      }
      if (character === '"' || character === "'" ||
        (this.language !== 'python' && character === '`')) {
        const start = index;
        const delimiter = character;
        index += 1;
        let escaped = false;
        while (index < source.length) {
          const current = source[index];
          index += 1;
          if (escaped) escaped = false;
          else if (current === '\\') escaped = true;
          else if (current === delimiter) break;
        }
        tokens.push({ start, length: index - start, color: ColorTokens.codeString });
        continue;
      }
      if (this.isDigit(character)) {
        const start = index;
        index += 1;
        while (index < source.length && (this.isDigit(source[index]) ||
          source[index] === '.' || source[index] === '_')) index += 1;
        tokens.push({ start, length: index - start, color: ColorTokens.codeNumber });
        continue;
      }
      if (this.isIdentifierStart(character)) {
        const start = index;
        index += 1;
        while (index < source.length && this.isIdentifierPart(source[index])) index += 1;
        const value = source.substring(start, index);
        if (this.isCodeKeyword(value)) {
          tokens.push({ start, length: index - start, color: ColorTokens.codeKey });
        } else if (value === 'true' || value === 'false' || value === 'null' || value === 'undefined' ||
          value === 'True' || value === 'False' || value === 'None' || value === 'nil') {
          tokens.push({ start, length: index - start, color: ColorTokens.codeLiteral });
        }
        continue;
      }
      if ('{}[]():;,.=+-*/!?<>'.includes(character)) {
        tokens.push({ start: index, length: 1, color: ColorTokens.codePunctuation });
      }
      index += 1;
    }
    return tokens;
  }

  private tokens(source: string): JsonToken[] {
    return this.language === 'json' ? this.jsonTokens(source) : this.javascriptTokens(source);
  }

  private completionCatalog(): CodeCompletion[] {
    const items: CodeCompletion[] = [];
    if (this.completionScope !== 'postResponse') {
      items.push({ label: 'nimbo.request.method', insertText: 'nimbo.request.method', caretBack: 0 });
      items.push({ label: 'nimbo.request.url', insertText: 'nimbo.request.url', caretBack: 0 });
      items.push({ label: 'nimbo.request.body', insertText: 'nimbo.request.body', caretBack: 0 });
      items.push({ label: 'nimbo.request.bodyType', insertText: 'nimbo.request.bodyType', caretBack: 0 });
      items.push({ label: 'nimbo.request.headers.get()', insertText: 'nimbo.request.headers.get()', caretBack: 1 });
      items.push({ label: 'nimbo.request.headers.set()', insertText: 'nimbo.request.headers.set()', caretBack: 1 });
      items.push({ label: 'nimbo.request.headers.remove()', insertText: 'nimbo.request.headers.remove()', caretBack: 1 });
    }
    if (this.completionScope !== 'preRequest') {
      items.push({ label: 'nimbo.response.statusCode', insertText: 'nimbo.response.statusCode', caretBack: 0 });
      items.push({ label: 'nimbo.response.statusText', insertText: 'nimbo.response.statusText', caretBack: 0 });
      items.push({ label: 'nimbo.response.body', insertText: 'nimbo.response.body', caretBack: 0 });
      items.push({ label: 'nimbo.response.contentType', insertText: 'nimbo.response.contentType', caretBack: 0 });
      items.push({ label: 'nimbo.response.size', insertText: 'nimbo.response.size', caretBack: 0 });
      items.push({ label: 'nimbo.response.duration', insertText: 'nimbo.response.duration', caretBack: 0 });
      items.push({ label: 'nimbo.response.protocol', insertText: 'nimbo.response.protocol', caretBack: 0 });
      items.push({ label: 'nimbo.response.headers.get()', insertText: 'nimbo.response.headers.get()', caretBack: 1 });
    }
    items.push({ label: 'nimbo.environment.get()', insertText: 'nimbo.environment.get()', caretBack: 1 });
    items.push({ label: 'nimbo.environment.set()', insertText: 'nimbo.environment.set()', caretBack: 1 });
    items.push({ label: 'console.log()', insertText: 'console.log()', caretBack: 1 });
    items.push({ label: 'console.info()', insertText: 'console.info()', caretBack: 1 });
    items.push({ label: 'console.warn()', insertText: 'console.warn()', caretBack: 1 });
    items.push({ label: 'console.error()', insertText: 'console.error()', caretBack: 1 });
    items.push({ label: 'JSON.parse()', insertText: 'JSON.parse()', caretBack: 1 });
    items.push({ label: 'JSON.stringify()', insertText: 'JSON.stringify()', caretBack: 1 });
    return items;
  }

  private completionCharacter(character: string): boolean {
    return this.isIdentifierPart(character) || character === '.';
  }

  private clearCompletion(): void {
    this.completionItems = [];
    this.completionIndex = 0;
    this.completionPrefix = '';
  }

  private resetCompletionScroll(): void {
    setTimeout((): void => {
      this.completionScroller.scrollToIndex(0, false, ScrollAlign.START);
    }, 0);
  }

  private enabledVariable(name: string): boolean {
    const normalized = name.trim().toLowerCase();
    return this.variables.some((item: KeyValueItem) => item.enabled &&
      item.key.trim().toLowerCase() === normalized);
  }

  private refreshVariableCompletion(source: string, caret: number): boolean {
    const start = source.lastIndexOf('{{', Math.max(0, caret - 1));
    if (start < 0 || source.substring(start + 2, caret).includes('}}')) return false;
    const prefix = source.substring(start + 2, caret);
    if (prefix.includes('{') || prefix.includes('}') || prefix.includes(' ') || prefix.includes('/')) return false;
    const normalized = prefix.toLowerCase();
    this.completionStart = start;
    this.completionPrefix = source.substring(start, caret);
    this.completionIndex = 0;
    this.completionItems = this.variables.filter((item: KeyValueItem) => item.enabled &&
      item.key.trim().length > 0 && item.key.trim().toLowerCase().startsWith(normalized)).slice(0, 6)
      .map((item: KeyValueItem): CodeCompletion => ({
        label: `{{${item.key.trim()}}}`,
        insertText: `{{${item.key.trim()}}}`,
        caretBack: 0,
        variable: true,
        secret: item.secret
      }));
    this.resetCompletionScroll();
    return true;
  }

  private refreshCompletion(): void {
    const caret = this.controller.getCaretOffset();
    const source = this.controller.getStyledString().getString();
    if (this.variables.length > 0 && this.refreshVariableCompletion(source, caret)) return;
    if (this.language !== 'javascript') {
      this.clearCompletion();
      return;
    }
    const selection = this.controller.getSelection();
    const start = selection.start ?? this.controller.getCaretOffset();
    const end = selection.end ?? start;
    if (start !== end) {
      this.clearCompletion();
      return;
    }
    if (this.stringDelimiter(source, caret).length > 0) {
      this.clearCompletion();
      return;
    }
    let tokenStart = caret;
    while (tokenStart > 0 && this.completionCharacter(source[tokenStart - 1])) tokenStart -= 1;
    const prefix = source.substring(tokenStart, caret);
    if (prefix.length < 2) {
      this.clearCompletion();
      return;
    }
    const matches = this.completionCatalog().filter((item: CodeCompletion) =>
      item.insertText.startsWith(prefix) && item.insertText !== prefix).slice(0, 6);
    this.completionStart = tokenStart;
    this.completionPrefix = prefix;
    this.completionIndex = 0;
    this.completionItems = matches;
    this.resetCompletionScroll();
  }

  private scheduleCompletion(): void {
    if (this.language !== 'javascript' && this.variables.length === 0) return;
    setTimeout(() => this.refreshCompletion(), 0);
  }

  private acceptCompletion(index: number): void {
    if (index < 0 || index >= this.completionItems.length) return;
    const item = this.completionItems[index];
    const current = this.controller.getStyledString().getString();
    const caret = this.controller.getCaretOffset();
    if (current.substring(this.completionStart, caret) !== this.completionPrefix) {
      this.clearCompletion();
      return;
    }
    let end = caret;
    if (item.variable && current.substring(caret).startsWith('}}')) end += 2;
    else if (item.variable && current.substring(caret).startsWith('}')) end += 1;
    this.clearCompletion();
    this.replaceEditorValue(current, this.completionStart, end, item.insertText,
      this.completionStart + item.insertText.length - item.caretBack);
  }

  private moveCompletion(step: number): void {
    if (this.completionItems.length === 0) return;
    this.completionIndex = (this.completionIndex + step + this.completionItems.length) %
      this.completionItems.length;
    const selected = this.completionIndex;
    setTimeout((): void => {
      this.completionScroller.scrollToIndex(selected, true, ScrollAlign.AUTO);
    }, 0);
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
    if (this.variables.length > 0) {
      let offset = 0;
      while (offset < source.length) {
        const start = source.indexOf('{{', offset);
        if (start < 0) break;
        const closing = source.indexOf('}}', start + 2);
        const end = closing < 0 ? source.length : closing + 2;
        const name = source.substring(start + 2, closing < 0 ? source.length : closing);
        const valid = closing < 0 || this.enabledVariable(name);
        styles.push({ start, length: end - start, styledKey: StyledStringKey.FONT,
          styledValue: this.fontStyle(valid ? ColorTokens.brand500 : ColorTokens.httpDelete,
            FontWeight.Medium) });
        styles.push({ start, length: end - start, styledKey: StyledStringKey.BACKGROUND_COLOR,
          styledValue: new BackgroundColorStyle({
            color: valid ? ColorTokens.brand50 : ColorTokens.statusDangerBackground, radius: 2
          }) });
        if (closing < 0) break;
        offset = end;
      }
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
    if (this.value !== this.displayedValue) {
      this.clearCompletion();
      if (!this.historyApplying) {
        this.undoValues = [];
        this.redoValues = [];
      }
      this.applyStyledValue(this.value, true);
    }
  }

  private rememberUndo(value: string): void {
    if (this.historyApplying || (this.undoValues.length > 0 &&
      this.undoValues[this.undoValues.length - 1] === value)) return;
    this.undoValues.push(value);
    if (this.undoValues.length > 100) this.undoValues.shift();
    this.redoValues = [];
  }

  private restoreHistory(value: string): void {
    this.historyApplying = true;
    this.clearCompletion();
    this.applyStyledValue(value, true);
    this.onChange(value);
    this.historyApplying = false;
  }

  private undo(): void {
    if (this.undoValues.length === 0) return;
    const current = this.controller.getStyledString().getString();
    const previous = this.undoValues.pop();
    if (previous === undefined) return;
    this.redoValues.push(current);
    this.restoreHistory(previous);
  }

  private redo(): void {
    if (this.redoValues.length === 0) return;
    const current = this.controller.getStyledString().getString();
    const next = this.redoValues.pop();
    if (next === undefined) return;
    this.undoValues.push(current);
    this.restoreHistory(next);
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
    this.scheduleCompletion();
  }

  private stringDelimiter(source: string, offset: number): string {
    let delimiter = '';
    let escaped = false;
    for (let index = 0; index < offset; index += 1) {
      const character = source[index];
      if (escaped) {
        escaped = false;
      } else if (character === '\\') {
        escaped = true;
      } else if (delimiter.length > 0 && character === delimiter) {
        delimiter = '';
      } else if (delimiter.length === 0 && (character === '"' ||
        (this.language === 'javascript' && (character === "'" || character === '`')))) {
        delimiter = character;
      }
    }
    return delimiter;
  }

  private closingCharacter(character: string): string {
    if (character === '{') return '}';
    if (character === '[') return ']';
    if (character === '(') return ')';
    if (character === '"') return '"';
    if (this.language === 'javascript' && character === "'") return "'";
    if (this.language === 'javascript' && character === '`') return '`';
    return '';
  }

  private openingCharacter(character: string): string {
    if (character === '}') return '{';
    if (character === ']') return '[';
    if (character === ')') return '(';
    if (character === '"') return '"';
    if (this.language === 'javascript' && character === "'") return "'";
    if (this.language === 'javascript' && character === '`') return '`';
    return '';
  }

  private isClosingCharacter(character: string): boolean {
    return character === '}' || character === ']' || character === ')' || character === '"' ||
      (this.language === 'javascript' && (character === "'" || character === '`'));
  }

  private replaceEditorValue(current: string, start: number, end: number, replacement: string,
    caretOffset: number, selectionLength: number = 0): void {
    this.rememberUndo(current);
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
    this.scheduleCompletion();
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
    if (start !== end || this.stringDelimiter(current, start).length > 0) return false;
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
    const quote = character === '"' || character === "'" || character === '`';
    if (closing.length === 0 || (quote && start === end && this.stringDelimiter(current, start).length > 0)) {
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
    if ((value.insertValue.includes('\n') || value.insertValue.includes('\r')) &&
      this.completionItems.length > 0) {
      this.acceptCompletion(this.completionIndex);
      return false;
    }
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
    const replacement = change.replacementString.getString();
    if ((replacement.includes('\n') || replacement.includes('\r')) && this.completionItems.length > 0) {
      this.acceptCompletion(this.completionIndex);
      return false;
    }
    const current = this.controller.getStyledString().getString();
    const start = change.range.start ?? 0;
    const end = change.range.end ?? start;
    if (this.consumePairedInput(current, start, end, replacement)) return false;
    this.rememberUndo(current);
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
    Stack({ alignContent: Alignment.BottomStart }) {
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
          .undoStyle(UndoStyle.KEEP_STYLE)
          .enableKeyboardOnFocus(!this.readOnly)
          .placeholder(this.placeholder, { fontColor: ColorTokens.codeLineNumber })
          .aboutToIMEInput((value: RichEditorInsertValue) => this.beforeInput(value))
          .aboutToDelete((value: RichEditorDeleteValue) => this.beforeDelete(value))
          .onKeyEventDispatch((event: KeyEvent) => {
            if (event.type === KeyType.Down && event.getModifierKeyState !== undefined &&
              event.getModifierKeyState(['ctrl'])) {
              if (event.keyCode === 2017 || event.keyText.toLowerCase() === 'a') {
                const contentLength = this.controller.getStyledString().getString().length;
                this.controller.setSelection(0, contentLength);
                return true;
              }
              if (this.readOnly) return false;
              const shift = event.getModifierKeyState(['shift']);
              if (event.keyCode === 2042 || event.keyText.toLowerCase() === 'z') {
                if (shift) this.redo();
                else this.undo();
                return true;
              }
              if (event.keyCode === 2041 || event.keyText.toLowerCase() === 'y') {
                this.redo();
                return true;
              }
            }
            if (!this.readOnly && event.type === KeyType.Down && this.completionItems.length > 0) {
              if (event.keyCode === 2012 || event.keyCode === 2013) {
                this.moveCompletion(event.keyCode === 2012 ? -1 : 1);
                return true;
              }
              if (event.keyCode === 2070) {
                this.clearCompletion();
                return true;
              }
              if (event.keyCode === 2049 || event.keyCode === 2054 || event.keyCode === 2119 ||
                event.keyText.toLowerCase() === 'enter') {
                this.acceptCompletion(this.completionIndex);
                return true;
              }
            }
            return false;
          })
          .onKeyEvent((event: KeyEvent) => {
            if (!this.readOnly && event.type === KeyType.Down &&
              event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
              const shift = event.getModifierKeyState(['shift']);
              if (event.keyCode === 2042 || event.keyText.toLowerCase() === 'z') {
                if (shift) this.redo();
                else this.undo();
                return true;
              }
              if (event.keyCode === 2041 || event.keyText.toLowerCase() === 'y') {
                this.redo();
                return true;
              }
            }
            if (!this.readOnly && event.type === KeyType.Down && this.completionItems.length > 0 &&
              (event.keyCode === 2012 || event.keyCode === 2013)) {
              this.moveCompletion(event.keyCode === 2012 ? -1 : 1);
              return true;
            }
            if (!this.readOnly && event.type === KeyType.Down && event.keyCode === 2070 &&
              this.completionItems.length > 0) {
              this.clearCompletion();
              return true;
            }
            if (!this.readOnly && event.type === KeyType.Down && (event.keyCode === 2054 ||
              event.keyCode === 2119 || event.keyText.toLowerCase() === 'enter')) {
              if (this.completionItems.length > 0) {
                this.acceptCompletion(this.completionIndex);
                return true;
              }
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
              if (!outdent && this.completionItems.length > 0) {
                this.acceptCompletion(this.completionIndex);
                return true;
              }
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

      if (this.completionItems.length > 0) {
        List({ scroller: this.completionScroller }) {
          ForEach(this.completionItems, (item: CodeCompletion, index: number) => {
            ListItem() {
              Row({ space: SpacingTokens.x2 }) {
                Text(item.label)
                  .fontSize(12)
                  .fontFamily('monospace')
                  .fontColor(index === this.completionIndex ? ColorTokens.brand500 : ColorTokens.textPrimary)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                if (item.secret) {
                  Text($r('app.string.field_secret'))
                    .fontSize(9)
                    .fontColor(ColorTokens.textTertiary)
                }
                if (index === this.completionIndex) {
                  Text('Enter / Tab')
                    .fontSize(10)
                    .fontColor(ColorTokens.textTertiary)
                    .padding({ left: SpacingTokens.x1, right: SpacingTokens.x1 })
                    .border({ width: 1, color: ColorTokens.borderSubtle })
                    .borderRadius(RadiusTokens.small)
                }
              }
              .width('100%')
              .height(30)
              .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
              .backgroundColor(index === this.completionIndex ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface)
              .onHover((isHover: boolean) => {
                if (isHover) this.completionIndex = index;
              })
              .onClick(() => this.acceptCompletion(index))
            }
          }, (item: CodeCompletion) => item.label)
        }
        .width(390)
        .height(Math.min(2, this.completionItems.length) * 30)
        .scrollBar(BarState.Off)
        .margin({ left: 54, bottom: SpacingTokens.x3 })
        .backgroundColor(ColorTokens.bgSurface)
        .border({ width: 1, color: ColorTokens.borderSubtle })
        .borderRadius(RadiusTokens.small)
        .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
        .clip(true)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.codeBackground)
    .borderRadius(RadiusTokens.small)
    .clip(true)
  }
}
