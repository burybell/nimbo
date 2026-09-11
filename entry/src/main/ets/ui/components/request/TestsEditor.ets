import { TestRule, TestRuleKind } from '../../../models/ShellModels';
import { LengthMetrics } from '@kit.ArkUI';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct TestsEditor {
  @Prop rules: TestRule[] = [];
  @Prop phone: boolean = false;
  private nextRuleNumber: number = 1;
  onChange: (rules: TestRule[]) => void = () => {};

  private kinds(): TestRuleKind[] {
    return ['statusEquals', 'durationLessThan', 'headerExists', 'headerEquals',
      'jsonPathExists', 'jsonPathEquals'];
  }

  private options(): SelectOption[] {
    return [
      { value: $r('app.string.test_status_equals') },
      { value: $r('app.string.test_duration_less_than') },
      { value: $r('app.string.test_header_exists') },
      { value: $r('app.string.test_header_equals') },
      { value: $r('app.string.test_jsonpath_exists') },
      { value: $r('app.string.test_jsonpath_equals') }
    ];
  }

  private label(kind: TestRuleKind): ResourceStr {
    if (kind === 'statusEquals') return $r('app.string.test_status_equals');
    if (kind === 'durationLessThan') return $r('app.string.test_duration_less_than');
    if (kind === 'headerExists') return $r('app.string.test_header_exists');
    if (kind === 'headerEquals') return $r('app.string.test_header_equals');
    if (kind === 'jsonPathExists') return $r('app.string.test_jsonpath_exists');
    return $r('app.string.test_jsonpath_equals');
  }

  private index(kind: TestRuleKind): number {
    return this.kinds().indexOf(kind);
  }

  private needsTarget(kind: TestRuleKind): boolean {
    return kind === 'headerExists' || kind === 'headerEquals' ||
      kind === 'jsonPathExists' || kind === 'jsonPathEquals';
  }

  private needsExpected(kind: TestRuleKind): boolean {
    return kind === 'statusEquals' || kind === 'durationLessThan' ||
      kind === 'headerEquals' || kind === 'jsonPathEquals';
  }

  private targetPlaceholder(kind: TestRuleKind): ResourceStr | string {
    return kind === 'headerExists' || kind === 'headerEquals' ?
      $r('app.string.test_header_name') : '$.data.id';
  }

  private expectedPlaceholder(kind: TestRuleKind): ResourceStr {
    if (kind === 'statusEquals') return $r('app.string.test_status_code');
    if (kind === 'durationLessThan') return $r('app.string.test_milliseconds');
    return $r('app.string.test_expected_value');
  }

  private update(rule: TestRule): void {
    this.onChange(this.rules.map((item: TestRule) => item.id === rule.id ? rule : item));
  }

  private current(id: string): TestRule | undefined {
    return this.rules.find((rule: TestRule) => rule.id === id);
  }

  private setEnabled(id: string, enabled: boolean): void {
    const rule = this.current(id);
    if (rule !== undefined) this.update({ id: rule.id, enabled, kind: rule.kind,
      target: rule.target, expected: rule.expected });
  }

  private setKind(id: string, kind: TestRuleKind): void {
    const rule = this.current(id);
    if (rule !== undefined) this.update({ id: rule.id, enabled: rule.enabled, kind,
      target: '', expected: kind === 'statusEquals' ? '200' : '' });
  }

  private setTarget(id: string, target: string): void {
    const rule = this.current(id);
    if (rule !== undefined) this.update({ id: rule.id, enabled: rule.enabled, kind: rule.kind,
      target, expected: rule.expected });
  }

  private setExpected(id: string, expected: string): void {
    const rule = this.current(id);
    if (rule !== undefined) this.update({ id: rule.id, enabled: rule.enabled, kind: rule.kind,
      target: rule.target, expected });
  }

  private add(): void {
    this.nextRuleNumber += 1;
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
      this.onChange([...this.rules, {
        id: `test-${Date.now()}-${this.nextRuleNumber}`,
        enabled: true,
        kind: 'statusEquals',
        target: '',
        expected: '200'
      }]);
    });
  }

  private remove(id: string): void {
    this.onChange(this.rules.filter((rule: TestRule) => rule.id !== id));
  }

  @Builder
  private ruleCard(rule: TestRule) {
    Flex({ direction: this.phone ? FlexDirection.Column : FlexDirection.Row,
      alignItems: this.phone ? ItemAlign.Start : ItemAlign.Center,
      justifyContent: FlexAlign.Start, space: { main: LengthMetrics.vp(8) } }) {
      Checkbox().select(rule.enabled).selectedColor(ColorTokens.brand500)
        .onChange((enabled: boolean) => this.setEnabled(rule.id, enabled))
      Select(this.options()).selected(this.index(rule.kind)).value(this.label(rule.kind))
        .height(SizeTokens.controlMedium).width(this.phone ? '100%' : 190)
        .font({ size: 11 }).optionFont({ size: 11 }).selectedOptionFont({ size: 11 })
        .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
        .onSelect((index: number) => this.setKind(rule.id, this.kinds()[index]))
      if (this.needsTarget(rule.kind)) {
        TextInput({ text: rule.target, placeholder: this.targetPlaceholder(rule.kind) })
          .height(SizeTokens.controlMedium).layoutWeight(1).fontSize(11)
          .fontFamily(rule.kind === 'jsonPathExists' || rule.kind === 'jsonPathEquals' ? 'monospace' : '')
          .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
          .onChange((target: string) => this.setTarget(rule.id, target))
      }
      if (this.needsExpected(rule.kind)) {
        TextInput({ text: rule.expected, placeholder: this.expectedPlaceholder(rule.kind) })
          .height(SizeTokens.controlMedium).layoutWeight(1).fontSize(11)
          .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
          .onChange((expected: string) => this.setExpected(rule.id, expected))
      }
      Text('×').width(SizeTokens.controlMedium).height(SizeTokens.controlMedium).fontSize(17)
        .textAlign(TextAlign.Center).fontColor(ColorTokens.textTertiary)
        .onClick(() => this.remove(rule.id))
    }
    .width('100%').padding(SpacingTokens.x3)
    .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.medium)
    .border({ width: 1, color: ColorTokens.borderSubtle })
  }

  build() {
    Scroll() {
      Column({ space: SpacingTokens.x3 }) {
        Text($r('app.string.tests_hint')).fontSize(12).fontColor(ColorTokens.textTertiary).width('100%')
        ForEach(this.rules, (rule: TestRule) => this.ruleCard(rule),
          (rule: TestRule) => `${rule.id}-${rule.kind}`)
        Button($r('app.string.tests_add')).height(SizeTokens.controlMedium).fontSize(12)
          .backgroundColor(ColorTokens.bgSurfaceHover).fontColor(ColorTokens.brand600)
          .onClick(() => this.add())
      }
      .width('100%').padding(SpacingTokens.x4).alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
  }
}
