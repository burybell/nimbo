import { LengthMetrics } from '@kit.ArkUI';
import { KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface VariableCandidate {
  key: string;
  secret: boolean;
}

@Component
export struct VariableTextInput {
  @Watch('handleExternalValue') @Prop value: string = '';
  @Prop variables: KeyValueItem[] = [];
  @Prop placeholder: ResourceStr = $r('app.string.field_value_placeholder');
  @Prop inputId: string = '';
  @Prop fontSize: number = 12;
  @Prop controlHeight: number = SizeTokens.controlMedium;
  @Prop fillColor: ResourceColor = ColorTokens.bgWorkspace;
  onChange: (value: string) => void = () => {};
  onLoseFocus: () => void = () => {};
  private controller: RichEditorStyledStringController = new RichEditorStyledStringController();
  private displayedValue: string = '';
  private applyingStyle: boolean = false;
  private listenerRegistered: boolean = false;
  private highlightTimer: number = -1;
  @State candidates: VariableCandidate[] = [];
  @State candidateIndex: number = 0;
  @State completionStart: number = 0;

  private enabledVariable(name: string): boolean {
    const normalized = name.trim().toLowerCase();
    return this.variables.some((item: KeyValueItem) => item.enabled &&
      item.key.trim().toLowerCase() === normalized);
  }

  private styledValue(source: string): StyledString {
    const styles: StyleOptions[] = [];
    if (source.length > 0) {
      styles.push({ start: 0, length: source.length, styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({ fontColor: ColorTokens.textPrimary,
          fontFamily: 'HarmonyOS Sans SC', fontSize: LengthMetrics.fp(this.fontSize) }) });
    }
    let offset = 0;
    while (offset < source.length) {
      const start = source.indexOf('{{', offset);
      if (start < 0) break;
      const closing = source.indexOf('}}', start + 2);
      const end = closing < 0 ? source.length : closing + 2;
      const name = source.substring(start + 2, closing < 0 ? source.length : closing);
      const valid = closing < 0 || this.enabledVariable(name);
      styles.push({ start, length: end - start, styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({ fontColor: valid ? ColorTokens.brand600 : ColorTokens.httpDelete,
          fontFamily: 'monospace', fontSize: LengthMetrics.fp(this.fontSize), fontWeight: FontWeight.Medium }) });
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
    if (this.highlightTimer >= 0) clearTimeout(this.highlightTimer);
    this.highlightTimer = -1;
    const caret = preserveCaret ? this.controller.getCaretOffset() : source.length;
    this.displayedValue = source;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(source));
    this.controller.setCaretOffset(Math.min(caret, source.length));
    this.applyingStyle = false;
  }

  private clearCandidates(): void {
    this.candidates = [];
    this.candidateIndex = 0;
  }

  private refreshCandidates(): void {
    const caret = this.controller.getCaretOffset();
    const source = this.controller.getStyledString().getString();
    const start = source.lastIndexOf('{{', Math.max(0, caret - 1));
    if (start < 0 || source.substring(start + 2, caret).includes('}}')) {
      this.clearCandidates();
      return;
    }
    const prefix = source.substring(start + 2, caret);
    if (prefix.includes('{') || prefix.includes('}') || prefix.includes(' ') || prefix.includes('/')) {
      this.clearCandidates();
      return;
    }
    const normalized = prefix.toLowerCase();
    this.completionStart = start;
    this.candidateIndex = 0;
    this.candidates = this.variables.filter((item: KeyValueItem) => item.enabled &&
      item.key.trim().length > 0 && item.key.trim().toLowerCase().startsWith(normalized)).slice(0, 6)
      .map((item: KeyValueItem): VariableCandidate => ({ key: item.key.trim(), secret: item.secret }));
  }

  private replaceValue(start: number, end: number, replacement: string): void {
    const current = this.controller.getStyledString().getString();
    const next = current.substring(0, start) + replacement + current.substring(end);
    const caret = start + replacement.length;
    this.clearCandidates();
    this.displayedValue = next;
    this.applyingStyle = true;
    this.controller.setStyledString(this.styledValue(next));
    this.controller.setCaretOffset(caret);
    this.applyingStyle = false;
    this.onChange(next);
    setTimeout(() => {
      if (this.inputId.length > 0) focusControl.requestFocus(this.inputId);
      this.controller.setCaretOffset(caret);
    }, 0);
  }

  private acceptCandidate(): void {
    if (this.candidateIndex < 0 || this.candidateIndex >= this.candidates.length) return;
    const caret = this.controller.getCaretOffset();
    const source = this.controller.getStyledString().getString();
    let end = caret;
    if (source.substring(caret).startsWith('}}')) end += 2;
    else if (source.substring(caret).startsWith('}')) end += 1;
    this.replaceValue(this.completionStart, end, `{{${this.candidates[this.candidateIndex].key}}}`);
  }

  private consumeLineBreak(value: string): boolean {
    if (!value.includes('\n') && !value.includes('\r')) return true;
    if (this.candidates.length > 0) this.acceptCandidate();
    return false;
  }

  private contentChanged(): void {
    if (this.applyingStyle) return;
    const content = this.controller.getStyledString().getString().replace(/[\r\n]/g, '');
    if (content !== this.displayedValue) {
      this.displayedValue = content;
      this.onChange(content);
    }
    setTimeout(() => this.refreshCandidates(), 0);
    if (this.highlightTimer >= 0) clearTimeout(this.highlightTimer);
    this.highlightTimer = setTimeout(() => this.applyStyledValue(this.displayedValue, true), 100);
  }

  private registerListener(): void {
    if (this.listenerRegistered) return;
    this.listenerRegistered = true;
    this.controller.onContentChanged({
      onWillChange: (change: StyledStringChangeValue): boolean =>
        this.consumeLineBreak(change.replacementString.getString()),
      onDidChange: (_before: TextRange, _after: TextRange): void => this.contentChanged()
    });
  }

  private handleExternalValue(): void {
    if (this.value !== this.displayedValue) {
      this.clearCandidates();
      this.applyStyledValue(this.value, true);
    }
  }

  @Builder
  private candidateMenu() {
    Column() {
      ForEach(this.candidates, (item: VariableCandidate, index: number) => {
        Row({ space: SpacingTokens.x2 }) {
          Text(`{{${item.key}}}`)
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor(index === this.candidateIndex ? ColorTokens.brand600 : ColorTokens.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (item.secret) {
            Text($r('app.string.field_secret')).fontSize(9).fontColor(ColorTokens.textTertiary)
          }
        }
        .width('100%')
        .height(32)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        .backgroundColor(index === this.candidateIndex ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface)
        .onHover((hovered: boolean) => { if (hovered) this.candidateIndex = index; })
        .onClick(() => { this.candidateIndex = index; this.acceptCandidate(); })
      }, (item: VariableCandidate) => item.key)
    }
    .width(280)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.medium)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
  }

  build() {
    RichEditor({ controller: this.controller })
      .id(this.inputId)
      .height(this.controlHeight)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 5, bottom: 4 })
      .backgroundColor(this.fillColor)
      .caretColor(ColorTokens.brand500)
      .selectedBackgroundColor(ColorTokens.codeSelection)
      .copyOptions(CopyOptions.LocalDevice)
      .placeholder(this.placeholder, { fontColor: ColorTokens.textTertiary })
      .aboutToIMEInput((value: RichEditorInsertValue) => this.consumeLineBreak(value.insertValue))
      .onKeyEvent((event: KeyEvent) => {
        if (event.type !== KeyType.Down) return false;
        if (this.candidates.length > 0 && (event.keyCode === 2012 || event.keyCode === 2013)) {
          this.candidateIndex = (this.candidateIndex + (event.keyCode === 2012 ? -1 : 1) +
            this.candidates.length) % this.candidates.length;
          return true;
        }
        if (this.candidates.length > 0 && (event.keyCode === 2049 || event.keyCode === 2054 ||
          event.keyCode === 2119 || event.keyText.toLowerCase() === 'enter')) {
          this.acceptCandidate();
          return true;
        }
        if (event.keyCode === 2070 && this.candidates.length > 0) {
          this.clearCandidates();
          return true;
        }
        return false;
      })
      .onAppear(() => {
        this.registerListener();
        this.applyStyledValue(this.value, false);
        setTimeout(() => {
          this.refreshCandidates();
          if (this.value.startsWith('{{') && this.inputId.length > 0) {
            focusControl.requestFocus(this.inputId);
            this.controller.setCaretOffset(this.value.length);
          }
        }, 0);
      })
      .onBlur(() => this.onLoseFocus())
      .focusBox({ strokeWidth: LengthMetrics.vp(0) })
      .bindPopup(this.candidates.length > 0, {
        builder: this.candidateMenu,
        placement: Placement.BottomLeft,
        popupColor: Color.Transparent,
        enableArrow: false,
        autoCancel: true,
        targetSpace: SpacingTokens.x1
      })
  }
}
