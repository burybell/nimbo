import { EnvironmentModel, ExtractionResult, ExtractionRule, ResponseModel } from '../../../models/ShellModels';
import { JsonPathResult, JsonPathService } from '../../../services/JsonPathService';
import { LengthMetrics } from '@kit.ArkUI';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct ExtractionEditor {
  @Prop rules: ExtractionRule[] = [];
  @Prop environments: EnvironmentModel[] = [];
  @Prop response: ResponseModel;
  @Prop phone: boolean = false;
  @State previewRuleId: string = '';
  @State previewStatus: string = '';
  @State previewValue: string = '';
  private nextRuleNumber: number = 1;
  onChange: (rules: ExtractionRule[]) => void = () => {};

  private update(rule: ExtractionRule): void {
    this.onChange(this.rules.map((item: ExtractionRule) => item.id === rule.id ? rule : item));
  }

  private changed(rule: ExtractionRule, enabled: boolean, variableName: string, jsonPath: string,
    environmentId: string, secret: boolean, overwrite: boolean): ExtractionRule {
    return { id: rule.id, enabled, variableName, jsonPath, environmentId, secret, overwrite };
  }

  private add(): void {
    this.nextRuleNumber += 1;
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
      this.onChange([...this.rules, {
        id: `extract-${Date.now()}-${this.nextRuleNumber}`,
        enabled: true,
        variableName: '',
        jsonPath: '$.',
        environmentId: '',
        secret: false,
        overwrite: false
      }]);
    });
  }

  private remove(id: string): void {
    this.onChange(this.rules.filter((rule: ExtractionRule) => rule.id !== id));
  }

  private environmentIndex(id: string): number {
    const index = this.environments.findIndex((environment: EnvironmentModel) => environment.id === id);
    return index < 0 ? 0 : index + 1;
  }

  private environmentOptions(): SelectOption[] {
    const placeholder: SelectOption = { value: $r('app.string.extraction_select_environment') };
    return [placeholder, ...this.environments.map((environment: EnvironmentModel) => {
      const option: SelectOption = { value: environment.name };
      return option;
    })];
  }

  private environmentName(id: string): ResourceStr {
    const environment = this.environments.find((item: EnvironmentModel) => item.id === id);
    return environment === undefined ? $r('app.string.extraction_select_environment') : environment.name;
  }

  private lastResult(id: string): ExtractionResult | undefined {
    return this.response.extractionResults.find((result: ExtractionResult) => result.ruleId === id);
  }

  private preview(rule: ExtractionRule): void {
    this.previewRuleId = rule.id;
    if (this.response.body.length === 0) {
      this.previewStatus = 'empty';
      this.previewValue = '';
      return;
    }
    const result: JsonPathResult = JsonPathService.evaluate(this.response.body, rule.jsonPath);
    this.previewStatus = result.status;
    this.previewValue = result.value;
  }

  private hasResult(rule: ExtractionRule): boolean {
    return this.previewRuleId === rule.id || this.lastResult(rule.id) !== undefined;
  }

  private resultLabel(rule: ExtractionRule): ResourceStr {
    if (this.previewRuleId === rule.id) {
      if (this.previewStatus === 'success') return $r('app.string.extraction_preview_value');
      if (this.previewStatus === 'empty') return $r('app.string.extraction_no_response');
      if (this.previewStatus === 'noMatch') return $r('app.string.extraction_no_match');
      if (this.previewStatus === 'invalidJson') return $r('app.string.extraction_invalid_json');
      return $r('app.string.extraction_invalid_path');
    }
    const result = this.lastResult(rule.id);
    if (result === undefined) return '';
    if (result.status === 'success') return $r('app.string.extraction_saved');
    if (result.status === 'conflict') return $r('app.string.extraction_conflict');
    if (result.status === 'targetMissing') return $r('app.string.extraction_target_missing');
    if (result.status === 'notRun') return $r('app.string.extraction_not_run');
    if (result.status === 'noMatch') return $r('app.string.extraction_no_match');
    if (result.status === 'invalidJson') return $r('app.string.extraction_invalid_json');
    return $r('app.string.extraction_invalid_path');
  }

  private resultValue(rule: ExtractionRule): string {
    if (this.previewRuleId === rule.id && this.previewStatus === 'success') return this.previewValue;
    const result = this.lastResult(rule.id);
    return result !== undefined && result.status === 'success' ? result.value : '';
  }

  private resultSuccess(rule: ExtractionRule): boolean {
    if (this.previewRuleId === rule.id) return this.previewStatus === 'success';
    return this.lastResult(rule.id)?.status === 'success';
  }

  @Builder
  private flag(label: ResourceStr, value: boolean, onChange: (value: boolean) => void) {
    Row({ space: SpacingTokens.x1 }) {
      Checkbox().select(value).selectedColor(ColorTokens.brand500).onChange(onChange)
      Text(label).fontSize(11).fontColor(ColorTokens.textSecondary)
    }
  }

  @Builder
  private ruleCard(rule: ExtractionRule) {
    Column({ space: SpacingTokens.x2 }) {
      Flex({ direction: this.phone ? FlexDirection.Column : FlexDirection.Row,
        alignItems: this.phone ? ItemAlign.Start : ItemAlign.Center,
        justifyContent: FlexAlign.Start, space: { main: LengthMetrics.vp(SpacingTokens.x2) } }) {
        Checkbox().select(rule.enabled).selectedColor(ColorTokens.brand500)
          .onChange((enabled: boolean) => this.update(this.changed(rule, enabled, rule.variableName,
            rule.jsonPath, rule.environmentId, rule.secret, rule.overwrite)))
        TextInput({ text: rule.variableName, placeholder: $r('app.string.extraction_variable') })
          .height(SizeTokens.controlMedium).layoutWeight(1).fontSize(12)
          .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
          .onChange((variableName: string) => this.update(this.changed(rule, rule.enabled, variableName,
            rule.jsonPath, rule.environmentId, rule.secret, rule.overwrite)))
        TextInput({ text: rule.jsonPath, placeholder: '$.data.accessToken' })
          .height(SizeTokens.controlMedium).layoutWeight(1).fontSize(12).fontFamily('monospace')
          .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
          .onChange((jsonPath: string) => this.update(this.changed(rule, rule.enabled, rule.variableName,
            jsonPath, rule.environmentId, rule.secret, rule.overwrite)))
        Select(this.environmentOptions())
          .selected(this.environmentIndex(rule.environmentId))
          .value(this.environmentName(rule.environmentId))
          .height(SizeTokens.controlMedium).width(this.phone ? '100%' : 150)
          .backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.small)
          .onSelect((index: number) => this.update(this.changed(rule, rule.enabled, rule.variableName,
            rule.jsonPath, index === 0 ? '' : this.environments[index - 1].id, rule.secret, rule.overwrite)))
        Button($r('app.string.extraction_preview')).height(SizeTokens.controlMedium).fontSize(11)
          .backgroundColor(ColorTokens.bgSurfaceHover).fontColor(ColorTokens.textPrimary)
          .onClick(() => this.preview(rule))
        Button('×').width(SizeTokens.controlMedium).height(SizeTokens.controlMedium).fontSize(16)
          .backgroundColor(Color.Transparent).fontColor(ColorTokens.textTertiary)
          .onClick(() => this.remove(rule.id))
      }
      .width('100%')

      Row({ space: SpacingTokens.x5 }) {
        this.flag($r('app.string.extraction_secret'), rule.secret,
          (secret: boolean) => this.update(this.changed(rule, rule.enabled, rule.variableName,
            rule.jsonPath, rule.environmentId, secret, rule.overwrite)))
        this.flag($r('app.string.extraction_overwrite'), rule.overwrite,
          (overwrite: boolean) => this.update(this.changed(rule, rule.enabled, rule.variableName,
            rule.jsonPath, rule.environmentId, rule.secret, overwrite)))
      }
      .padding({ left: this.phone ? 0 : 32 })

      if (this.hasResult(rule)) {
        Row({ space: SpacingTokens.x1 }) {
          Text(this.resultLabel(rule)).fontSize(11)
            .fontColor(this.resultSuccess(rule) ? ColorTokens.statusSuccess : ColorTokens.httpDelete)
          if (this.resultValue(rule).length > 0) {
            Text(`: ${this.resultValue(rule)}`).fontSize(11).fontFamily('monospace')
              .fontColor(this.resultSuccess(rule) ? ColorTokens.statusSuccess : ColorTokens.httpDelete)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .padding({ left: this.phone ? 0 : 32 })
      }
    }
    .width('100%').padding(SpacingTokens.x3)
    .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.medium)
    .border({ width: 1, color: ColorTokens.borderSubtle })
  }

  build() {
    Scroll() {
      Column({ space: SpacingTokens.x3 }) {
        Text($r('app.string.extraction_hint')).fontSize(12).fontColor(ColorTokens.textTertiary).width('100%')
        ForEach(this.rules, (rule: ExtractionRule) => this.ruleCard(rule), (rule: ExtractionRule) => rule.id)
        Button($r('app.string.extraction_add')).height(SizeTokens.controlMedium).fontSize(12)
          .backgroundColor(ColorTokens.bgSurfaceHover).fontColor(ColorTokens.brand600)
          .onClick(() => this.add())
      }
      .width('100%').padding(SpacingTokens.x4).alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
  }
}
