import { ResponseErrorModel, ResponseErrorType } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ErrorPanel {
  @Prop error: ResponseErrorModel;
  @State showDetails: boolean = false;
  onRetry: () => void = () => {};
  onCopyDiagnostic: () => void = () => {};

  private title(): ResourceStr {
    if (this.error.type === 'invalidUrl') return $r('app.string.error_invalid_url');
    if (this.error.type === 'dns') return $r('app.string.error_dns');
    if (this.error.type === 'connectionRefused') return $r('app.string.error_connection');
    if (this.error.type === 'connectionReset') return $r('app.string.error_connection_reset');
    if (this.error.type === 'timeout') return $r('app.string.error_timeout');
    if (this.error.type === 'tls') return $r('app.string.error_tls');
    if (this.error.type === 'proxy') return $r('app.string.error_proxy');
    if (this.error.type === 'script') return $r('app.string.error_script');
    if (this.error.type === 'variable') return $r('app.string.error_variable');
    if (this.error.type === 'file') return $r('app.string.error_file');
    if (this.error.type === 'cancelled') return $r('app.string.error_cancelled');
    return $r('app.string.error_request_failed');
  }

  private summary(): ResourceStr {
    if (this.error.type === 'invalidUrl') return $r('app.string.error_summary_invalid_url');
    if (this.error.type === 'dns') return $r('app.string.error_summary_dns');
    if (this.error.type === 'connectionRefused') return $r('app.string.error_summary_connection');
    if (this.error.type === 'connectionReset') return $r('app.string.error_summary_reset');
    if (this.error.type === 'timeout') return $r('app.string.error_summary_timeout');
    if (this.error.type === 'tls') return $r('app.string.error_summary_tls');
    if (this.error.type === 'proxy') return $r('app.string.error_summary_proxy');
    if (this.error.type === 'script') return $r('app.string.error_summary_script');
    if (this.error.type === 'variable') return $r('app.string.error_summary_variable');
    if (this.error.type === 'file') return $r('app.string.error_summary_file');
    if (this.error.type === 'cancelled') return $r('app.string.error_cancelled_message');
    return $r('app.string.error_summary_unknown');
  }

  private causeFor(type: ResponseErrorType): ResourceStr {
    if (type === 'invalidUrl') return $r('app.string.error_cause_invalid_url');
    if (type === 'dns') return $r('app.string.error_cause_dns');
    if (type === 'connectionRefused') return $r('app.string.error_cause_connection');
    if (type === 'connectionReset') return $r('app.string.error_cause_reset');
    if (type === 'timeout') return $r('app.string.error_cause_timeout');
    if (type === 'tls') return $r('app.string.error_cause_tls');
    if (type === 'proxy') return $r('app.string.error_cause_proxy');
    if (type === 'script') return $r('app.string.error_cause_script');
    if (type === 'variable') return $r('app.string.error_cause_variable');
    if (type === 'file') return $r('app.string.error_cause_file');
    return $r('app.string.error_cause_unknown');
  }

  private checkFor(type: ResponseErrorType): ResourceStr {
    if (type === 'invalidUrl') return $r('app.string.error_check_invalid_url');
    if (type === 'dns') return $r('app.string.error_check_dns');
    if (type === 'connectionRefused') return $r('app.string.error_check_connection');
    if (type === 'connectionReset') return $r('app.string.error_check_reset');
    if (type === 'timeout') return $r('app.string.error_check_timeout');
    if (type === 'tls') return $r('app.string.error_check_tls');
    if (type === 'proxy') return $r('app.string.error_check_proxy');
    if (type === 'script') return $r('app.string.error_check_script');
    if (type === 'variable') return $r('app.string.error_check_variable');
    if (type === 'file') return $r('app.string.error_check_file');
    return $r('app.string.error_check_unknown');
  }

  private stage(): ResourceStr {
    if (this.error.stage === 'validation') return $r('app.string.error_stage_validation');
    if (this.error.stage === 'dns') return $r('app.string.error_stage_dns');
    if (this.error.stage === 'connect') return $r('app.string.error_stage_connect');
    if (this.error.stage === 'tls') return $r('app.string.error_stage_tls');
    if (this.error.stage === 'send') return $r('app.string.error_stage_send');
    if (this.error.stage === 'receive') return $r('app.string.error_stage_receive');
    if (this.error.stage === 'script') return $r('app.string.error_stage_script');
    if (this.error.stage === 'file') return $r('app.string.error_stage_file');
    return $r('app.string.error_stage_unknown');
  }

  private variableList(): string {
    return this.error.unresolvedVariables?.map((name: string) => `{{${name}}}`).join(', ') ?? '';
  }

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Row({ space: SpacingTokens.x3 }) {
        Text('!')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.statusServerError)
          .width(36).height(36).textAlign(TextAlign.Center)
          .backgroundColor(ColorTokens.statusDangerBackground).borderRadius(18)
        Column({ space: SpacingTokens.x1 }) {
          Text(this.title()).fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary)
          Text(this.summary()).fontSize(12).fontColor(ColorTokens.textSecondary)
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
        if (this.error.code.length > 0) {
          Text(this.error.code)
            .fontSize(10).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
            .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.statusDangerBackground).borderRadius(RadiusTokens.small)
        }
      }
      .width('100%').alignItems(VerticalAlign.Top)

      if ((this.error.host?.length ?? 0) > 0 || this.error.method !== undefined) {
        Column({ space: SpacingTokens.x2 }) {
          Row({ space: SpacingTokens.x2 }) {
            Text(this.error.method ?? '-').fontSize(11).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.brand600)
            Text(this.error.host ?? '-').fontSize(11).fontColor(ColorTokens.textPrimary)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          Row({ space: SpacingTokens.x4 }) {
            Text(this.stage()).fontSize(10).fontColor(ColorTokens.textSecondary)
            Row({ space: SpacingTokens.x1 }) {
              Text($r('app.string.error_elapsed_label')).fontSize(10).fontColor(ColorTokens.textTertiary)
              Text(`${this.error.durationMs ?? 0} ms`).fontSize(10).fontColor(ColorTokens.textTertiary)
            }
            Row({ space: SpacingTokens.x1 }) {
              Text($r('app.string.error_timeout_label')).fontSize(10).fontColor(ColorTokens.textTertiary)
              Text(`${this.error.timeoutMs ?? 0} ms`).fontSize(10).fontColor(ColorTokens.textTertiary)
            }
          }
          .width('100%')
        }
        .width('100%').padding(SpacingTokens.x3).alignItems(HorizontalAlign.Start)
        .backgroundColor(ColorTokens.bgWorkspace)
        .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.small)
      }

      if (this.error.type === 'variable' && this.variableList().length > 0) {
        Text(this.variableList())
          .width('100%').fontSize(12).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
          .padding(SpacingTokens.x3).backgroundColor(ColorTokens.statusDangerBackground)
          .borderRadius(RadiusTokens.small)
      }

      Column({ space: SpacingTokens.x1 }) {
        Text($r('app.string.error_possible_causes')).fontSize(11).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text(this.causeFor(this.error.type)).fontSize(11).fontColor(ColorTokens.textSecondary)
      }
      .width('100%').alignItems(HorizontalAlign.Start)

      Column({ space: SpacingTokens.x1 }) {
        Text($r('app.string.error_suggested_checks')).fontSize(11).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text(this.checkFor(this.error.type)).fontSize(11).fontColor(ColorTokens.textSecondary)
      }
      .width('100%').alignItems(HorizontalAlign.Start)

      if (this.showDetails) {
        Column({ space: SpacingTokens.x2 }) {
          Text($r('app.string.error_technical_details')).fontSize(11).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text(`${this.error.type} · ${this.error.code || '-'}`)
            .fontSize(11).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
          Text(this.error.details)
            .fontSize(11).fontFamily('monospace').fontColor(ColorTokens.textSecondary)
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%').padding(SpacingTokens.x3).alignItems(HorizontalAlign.Start)
        .backgroundColor(ColorTokens.codeBackground).borderRadius(RadiusTokens.small)
      }

      Row({ space: SpacingTokens.x2 }) {
        Button($r('app.string.action_retry'))
          .fontSize(11).height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.small).onClick(this.onRetry)
        Button($r('app.string.error_copy_diagnostic'))
          .fontSize(11).height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textSecondary).backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.small).onClick(this.onCopyDiagnostic)
        Button(this.showDetails ? $r('app.string.hide_details') : $r('app.string.details'))
          .fontSize(11).height(SizeTokens.controlMedium)
          .fontColor(ColorTokens.textSecondary).backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.small)
          .onClick(() => { this.showDetails = !this.showDetails; })
      }
      .width('100%')
    }
    .width('100%').constraintSize({ maxWidth: 760 }).padding(SpacingTokens.x4)
    .alignItems(HorizontalAlign.Start).backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
  }
}
