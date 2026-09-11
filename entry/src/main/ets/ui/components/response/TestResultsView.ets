import { TestResult, TestResultMessage } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct TestResultsView {
  @Prop results: TestResult[] = [];

  private passedCount(): number {
    return this.results.filter((result: TestResult) => result.status === 'passed').length;
  }

  private statusLabel(result: TestResult): ResourceStr {
    if (result.status === 'passed') return $r('app.string.test_passed');
    if (result.status === 'notRun') return $r('app.string.test_not_run');
    return $r('app.string.test_failed');
  }

  private messageLabel(message: TestResultMessage): ResourceStr {
    if (message === 'configurationInvalid') return $r('app.string.test_message_configuration_invalid');
    if (message === 'statusMatched') return $r('app.string.test_message_status_matched');
    if (message === 'statusMismatch') return $r('app.string.test_message_status_mismatch');
    if (message === 'durationMatched') return $r('app.string.test_message_duration_matched');
    if (message === 'durationMismatch') return $r('app.string.test_message_duration_mismatch');
    if (message === 'durationUnavailable') return $r('app.string.test_message_duration_unavailable');
    if (message === 'headerPresent') return $r('app.string.test_message_header_present');
    if (message === 'headerMissing') return $r('app.string.test_message_header_missing');
    if (message === 'headerMatched') return $r('app.string.test_message_header_matched');
    if (message === 'headerMismatch') return $r('app.string.test_message_header_mismatch');
    if (message === 'jsonPathMatched') return $r('app.string.test_message_jsonpath_matched');
    if (message === 'jsonPathMismatch') return $r('app.string.test_message_jsonpath_mismatch');
    if (message === 'jsonPathNoMatch') return $r('app.string.test_message_jsonpath_no_match');
    if (message === 'invalidJson') return $r('app.string.test_message_invalid_json');
    if (message === 'invalidJsonPath') return $r('app.string.test_message_invalid_jsonpath');
    return $r('app.string.test_message_response_unavailable');
  }

  build() {
    if (this.results.length === 0) {
      Column({ space: SpacingTokens.x2 }) {
        Text($r('app.string.tests_no_results')).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text($r('app.string.tests_no_results_hint')).fontSize(12).fontColor(ColorTokens.textTertiary)
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Column({ space: SpacingTokens.x3 }) {
          Row({ space: SpacingTokens.x2 }) {
            Text(`${this.passedCount()} / ${this.results.length}`)
              .fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(this.passedCount() === this.results.length ?
                ColorTokens.statusSuccess : ColorTokens.httpDelete)
            Text($r('app.string.tests_passed_summary')).fontSize(12).fontColor(ColorTokens.textSecondary)
          }.width('100%')
          ForEach(this.results, (result: TestResult) => {
            Row({ space: SpacingTokens.x3 }) {
              Text(result.status === 'passed' ? '✓' : (result.status === 'failed' ? '×' : '—'))
                .width(24).height(24).fontSize(14).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
                .fontColor(result.status === 'passed' ? ColorTokens.statusSuccess :
                  (result.status === 'failed' ? ColorTokens.httpDelete : ColorTokens.textTertiary))
                .backgroundColor(result.status === 'passed' ? ColorTokens.brand50 : ColorTokens.bgSurfaceHover)
                .borderRadius(12)
              Column({ space: 2 }) {
                Text(this.statusLabel(result)).fontSize(12).fontWeight(FontWeight.Medium)
                  .fontColor(result.status === 'passed' ? ColorTokens.statusSuccess :
                    (result.status === 'failed' ? ColorTokens.httpDelete : ColorTokens.textSecondary))
                Text(this.messageLabel(result.message)).fontSize(11).fontColor(ColorTokens.textSecondary)
                if (result.expected.length > 0) {
                  Row({ space: 3 }) {
                    Text($r('app.string.test_expected')).fontSize(11).fontColor(ColorTokens.textTertiary)
                    Text(`: ${result.expected}`).fontSize(11).fontFamily('monospace')
                      .fontColor(ColorTokens.textTertiary).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                if (result.actual.length > 0) {
                  Row({ space: 3 }) {
                    Text($r('app.string.test_actual')).fontSize(11).fontColor(ColorTokens.textTertiary)
                    Text(`: ${result.actual}`).fontSize(11).fontFamily('monospace')
                      .fontColor(ColorTokens.textTertiary).maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            }
            .width('100%').padding(SpacingTokens.x3).alignItems(VerticalAlign.Top)
            .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.medium)
            .border({ width: 1, color: ColorTokens.borderSubtle })
          }, (result: TestResult) =>
            `${result.ruleId}-${result.status}-${result.actual}-${result.expected}-${result.message}`)
        }.width('100%').padding(SpacingTokens.x4).alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%').scrollBar(BarState.Auto).align(Alignment.TopStart)
    }
  }
}
