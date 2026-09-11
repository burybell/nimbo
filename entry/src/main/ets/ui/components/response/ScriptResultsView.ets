import { ScriptExecutionResult, ScriptExecutionStatus, ScriptPhase } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ScriptResultsView {
  @Prop results: ScriptExecutionResult[] = [];

  private phaseLabel(phase: ScriptPhase): ResourceStr {
    return phase === 'preRequest' ? $r('app.string.script_phase_pre_request') :
      $r('app.string.script_phase_post_response');
  }

  private statusLabel(status: ScriptExecutionStatus): ResourceStr {
    if (status === 'success') return $r('app.string.script_status_success');
    if (status === 'timeout') return $r('app.string.script_status_timeout');
    if (status === 'memoryLimit') return $r('app.string.script_status_memory_limit');
    return $r('app.string.script_status_error');
  }

  private statusColor(status: ScriptExecutionStatus): ResourceColor {
    return status === 'success' ? ColorTokens.statusSuccess : ColorTokens.httpDelete;
  }

  build() {
    if (this.results.length === 0) {
      Column({ space: SpacingTokens.x2 }) {
        Text($r('app.string.script_results_empty'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text($r('app.string.script_results_empty_hint'))
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Column({ space: SpacingTokens.x3 }) {
          ForEach(this.results, (result: ScriptExecutionResult, resultIndex: number) => {
            Column({ space: SpacingTokens.x3 }) {
              Row({ space: SpacingTokens.x2 }) {
                Text(result.status === 'success' ? '✓' : '×')
                  .width(24)
                  .height(24)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
                  .fontColor(this.statusColor(result.status))
                  .backgroundColor(result.status === 'success' ? ColorTokens.brand50 :
                    ColorTokens.statusDangerBackground)
                  .borderRadius(12)
                Column({ space: 2 }) {
                  Text(this.phaseLabel(result.phase))
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorTokens.textPrimary)
                  Text(this.statusLabel(result.status))
                    .fontSize(11)
                    .fontColor(this.statusColor(result.status))
                }
                .alignItems(HorizontalAlign.Start)
                Blank()
                Text(`${result.durationMs} ms`)
                  .fontSize(11)
                  .fontFamily('monospace')
                  .fontColor(ColorTokens.textTertiary)
              }
              .width('100%')

              if (result.error.length > 0) {
                Column({ space: SpacingTokens.x1 }) {
                  Text($r('app.string.script_error_detail'))
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorTokens.httpDelete)
                  Text(result.error)
                    .fontSize(11)
                    .fontFamily('monospace')
                    .fontColor(ColorTokens.textSecondary)
                    .copyOption(CopyOptions.LocalDevice)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(SpacingTokens.x3)
                .backgroundColor(ColorTokens.statusDangerBackground)
                .borderRadius(RadiusTokens.small)
              }

              Column({ space: SpacingTokens.x2 }) {
                Text($r('app.string.script_console'))
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorTokens.textSecondary)
                if (result.logs.length === 0) {
                  Text($r('app.string.script_console_empty'))
                    .fontSize(11)
                    .fontColor(ColorTokens.codeLineNumber)
                } else {
                  ForEach(result.logs, (line: string, logIndex: number) => {
                    Row({ space: SpacingTokens.x2 }) {
                      Text((logIndex + 1).toString())
                        .width(24)
                        .fontSize(10)
                        .fontFamily('monospace')
                        .fontColor(ColorTokens.codeLineNumber)
                        .textAlign(TextAlign.End)
                      Text(line)
                        .layoutWeight(1)
                        .fontSize(11)
                        .fontFamily('monospace')
                        .fontColor(ColorTokens.codeText)
                        .copyOption(CopyOptions.LocalDevice)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)
                  }, (line: string, logIndex: number) => `${resultIndex}-${logIndex}-${line}`)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(SpacingTokens.x3)
              .backgroundColor(ColorTokens.codeBackground)
              .borderRadius(RadiusTokens.small)
            }
            .width('100%')
            .padding(SpacingTokens.x3)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderSubtle })
            .borderRadius(RadiusTokens.medium)
          }, (result: ScriptExecutionResult, index: number) =>
            `${index}-${result.phase}-${result.status}-${result.durationMs}-${result.error}`)
        }
        .width('100%')
        .padding(SpacingTokens.x4)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
    }
  }
}
