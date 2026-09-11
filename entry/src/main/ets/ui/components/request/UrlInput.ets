import { LengthMetrics } from '@kit.ArkUI';
import { KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface UrlVariableCompletion {
  key: string;
  secret: boolean;
}

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct UrlInput {
  @Watch('handleExternalValue') @Prop value: string = '';
  @Prop variables: KeyValueItem[] = [];
  @Prop standalone: boolean = false;
  @Prop embedded: boolean = false;
  onChange: (value: string) => void = () => {};
  onSubmit: () => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';
  private applyingStyle: boolean = false;
  private listenerRegistered: boolean = false;
  private highlightTimer: number = -1;
  private submitPending: boolean = false;
  @State completionItems: UrlVariableCompletion[] = [];
  @State completionIndex: number = 0;
  @State completionStart: number = 0;

  private enabledVariable(name: string): KeyValueItem | undefined {
    const normalized = name.trim().toLowerCase();
    return this.variables.find((item: KeyValueItem) => item.enabled &&
      item.key.trim().toLowerCase() === normalized);
  }

  private styledValue(source: string): StyledString {
    const styles: StyleOptions[] = [];
    if (source.length > 0) {
      styles.push({ start: 0, length: source.length, styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({ fontColor: ColorTokens.textPrimary,
          fontFamily: 'HarmonyOS Sans SC', fontSize: LengthMetrics.fp(14) }) });
    }
    let offset = 0;
    while (offset < source.length) {
      const start = source.indexOf('{{', offset);
      if (start < 0) break;
      const closing = source.indexOf('}}', start + 2);
      const end = closing < 0 ? source.length : closing + 2;
      const name = source.substring(start + 2, closing < 0 ? source.length : closing);
      const valid = closing < 0 || this.enabledVariable(name) !== undefined;
      styles.push({ start, length: end - start, styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({ fontColor: valid ? ColorTokens.brand600 : ColorTokens.httpDelete,
          fontFamily: 'monospace', fontSize: LengthMetrics.fp(13), fontWeight: FontWeight.Medium }) });
      styles.push({ start, length: end - start, styledKey: StyledStringKey.BACKGROUND_COLOR,
        styledValue: new BackgroundColorStyle({
          color: valid ? ColorTokens.brand50 : ColorTokens.statusDangerBackground, radius: 3
        }) });
      if (closing < 0) break;
      offset = end;
    }
    return new StyledString(source, styles);
  }

  private applyStyledValue(source: string, preserveCaret: boolean): void {
    if (this.highlightTimer >= 0) {
      clearTimeout(this.highlightTimer);
      this.highlightTimer = -1;
    }
    const caret = preserveCaret ? this.controller.getCaretOffset() : source.length;
    this.displayedValue = source;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(source));
    this.controller.setCaretOffset(Math.min(caret, source.length));
    this.applyingStyle = false;
  }

  private scheduleHighlight(): void {
    if (this.highlightTimer >= 0) clearTimeout(this.highlightTimer);
    this.highlightTimer = setTimeout(() => {
      this.highlightTimer = -1;
      const source = this.controller.getStyledString().getString();
      if (source === this.displayedValue) this.applyStyledValue(source, true);
    }, 100);
  }

  private clearCompletion(): void {
    this.completionItems = [];
    this.completionIndex = 0;
  }

  private refreshCompletion(): void {
    const caret = this.controller.getCaretOffset();
    const source = this.controller.getStyledString().getString();
    const start = source.lastIndexOf('{{', Math.max(0, caret - 1));
    if (start < 0 || source.substring(start + 2, caret).includes('}}')) {
      this.clearCompletion();
      return;
    }
    const prefix = source.substring(start + 2, caret);
    if (prefix.includes('{') || prefix.includes('}') || prefix.includes(' ') || prefix.includes('/')) {
      this.clearCompletion();
      return;
    }
    const normalized = prefix.toLowerCase();
    const matches = this.variables.filter((item: KeyValueItem) => item.enabled && item.key.trim().length > 0 &&
      item.key.trim().toLowerCase().startsWith(normalized)).slice(0, 6)
      .map((item: KeyValueItem): UrlVariableCompletion => ({ key: item.key.trim(), secret: item.secret }));
    this.completionStart = start;
    this.completionIndex = 0;
    this.completionItems = matches;
  }

  private scheduleCompletion(): void {
    setTimeout(() => this.refreshCompletion(), 0);
  }

  private replaceValue(start: number, end: number, replacement: string): void {
    const current = this.controller.getStyledString().getString();
    const next = current.substring(0, start) + replacement + current.substring(end);
    const caret = start + replacement.length;
    this.clearCompletion();
    this.displayedValue = next;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(next));
    this.controller.setCaretOffset(caret);
    this.applyingStyle = false;
    this.onChange(next);
    setTimeout(() => {
      focusControl.requestFocus('nimboRequestUrlInput');
      this.controller.setCaretOffset(caret);
    }, 0);
  }

  private acceptCompletion(index: number): void {
    if (index < 0 || index >= this.completionItems.length) return;
    const caret = this.controller.getCaretOffset();
    const source = this.controller.getStyledString().getString();
    let end = caret;
    if (source.substring(caret).startsWith('}}')) end += 2;
    else if (source.substring(caret).startsWith('}')) end += 1;
    this.replaceValue(this.completionStart, end, `{{${this.completionItems[index].key}}}`);
  }

  private moveCompletion(step: number): void {
    if (this.completionItems.length === 0) return;
    this.completionIndex = (this.completionIndex + step + this.completionItems.length) %
      this.completionItems.length;
  }

  private completeProtocol(): boolean {
    const current = this.controller.getStyledString().getString();
    let completion = '';
    if (current === 'h') completion = 'http://';
    if (current === 'hs') completion = 'https://';
    if (completion.length === 0) return false;
    this.replaceValue(0, current.length, completion);
    return true;
  }

  private submitOnce(): void {
    if (this.submitPending) return;
    this.submitPending = true;
    this.onSubmit();
    setTimeout(() => { this.submitPending = false; }, 0);
  }

  private beforeInput(value: RichEditorInsertValue): boolean {
    if (!value.insertValue.includes('\n') && !value.insertValue.includes('\r')) return true;
    if (this.completionItems.length > 0) this.acceptCompletion(this.completionIndex);
    else this.submitOnce();
    return false;
  }

  private beforeContentChange(change: StyledStringChangeValue): boolean {
    const replacement = change.replacementString.getString();
    if (!replacement.includes('\n') && !replacement.includes('\r')) return true;
    if (this.completionItems.length > 0) this.acceptCompletion(this.completionIndex);
    else this.submitOnce();
    return false;
  }

  private contentChanged(): void {
    if (this.applyingStyle) return;
    const content = this.controller.getStyledString().getString().replace(/\r?\n/g, '');
    if (content !== this.displayedValue) {
      this.displayedValue = content;
      this.onChange(content);
    }
    this.scheduleCompletion();
    this.scheduleHighlight();
  }

  private registerContentListener(): void {
    if (this.listenerRegistered) return;
    this.listenerRegistered = true;
    this.controller.onContentChanged({
      onWillChange: (change: StyledStringChangeValue): boolean => this.beforeContentChange(change),
      onDidChange: (_before: TextRange, _after: TextRange): void => this.contentChanged()
    });
  }

  private handleExternalValue(): void {
    if (this.value !== this.displayedValue) {
      this.clearCompletion();
      this.applyStyledValue(this.value, true);
    }
  }

  @Builder
  private completionMenu() {
    Column() {
      ForEach(this.completionItems, (item: UrlVariableCompletion, index: number) => {
        Row({ space: SpacingTokens.x2 }) {
          Text(`{{${item.key}}}`)
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor(index === this.completionIndex ? ColorTokens.brand600 : ColorTokens.textPrimary)
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
              .fontSize(9)
              .fontColor(ColorTokens.textTertiary)
          }
        }
        .width('100%')
        .height(32)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        .backgroundColor(index === this.completionIndex ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface)
        .onHover((hovered: boolean) => { if (hovered) this.completionIndex = index; })
        .onClick(() => this.acceptCompletion(index))
      }, (item: UrlVariableCompletion) => item.key)
    }
    .width(300)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.medium)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
  }

  build() {
    RichEditor({ controller: this.controller })
      .id('nimboRequestUrlInput')
      .height(SizeTokens.controlLarge)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: 8, bottom: 6 })
      .backgroundColor(this.embedded ? Color.Transparent : ColorTokens.bgSurface)
      .caretColor(ColorTokens.brand500)
      .selectedBackgroundColor(ColorTokens.codeSelection)
      .copyOptions(CopyOptions.LocalDevice)
      .placeholder($r('app.string.request_url_placeholder'), { fontColor: ColorTokens.textTertiary })
      .aboutToIMEInput((value: RichEditorInsertValue) => this.beforeInput(value))
      .onKeyEvent((event: KeyEvent) => {
        if (event.type !== KeyType.Down) return false;
        if (this.completionItems.length > 0 && (event.keyCode === 2012 || event.keyCode === 2013)) {
          this.moveCompletion(event.keyCode === 2012 ? -1 : 1);
          return true;
        }
        if (event.keyCode === 2070 && this.completionItems.length > 0) {
          this.clearCompletion();
          return true;
        }
        if (event.keyCode === 2049) {
          if (this.completionItems.length > 0) {
            this.acceptCompletion(this.completionIndex);
            return true;
          }
          return this.completeProtocol();
        }
        if (event.keyCode === 2054 || event.keyCode === 2119 ||
          event.keyText.toLowerCase() === 'enter') {
          if (this.completionItems.length > 0) this.acceptCompletion(this.completionIndex);
          else this.submitOnce();
          return true;
        }
        return false;
      })
      .onAppear(() => {
        this.registerContentListener();
        this.applyStyledValue(this.value, false);
      })
      .border({ width: this.embedded ? 0 : (this.standalone ? 1 : { top: 1, right: 1, bottom: 1 }),
        color: ColorTokens.borderDefault })
      .borderRadius(this.embedded ? 0 : (this.standalone ? RadiusTokens.medium :
        { topRight: RadiusTokens.medium, bottomRight: RadiusTokens.medium }))
      .focusBox({ strokeWidth: LengthMetrics.vp(0) })
      .bindPopup(this.completionItems.length > 0, {
        builder: this.completionMenu,
        placement: Placement.BottomLeft,
        popupColor: Color.Transparent,
        enableArrow: false,
        autoCancel: true,
        targetSpace: SpacingTokens.x1,
        onStateChange: (event: PopupVisibilityEvent) => {
          if (!event.isVisible && this.completionItems.length > 0) this.clearCompletion();
        }
      })
  }
}
