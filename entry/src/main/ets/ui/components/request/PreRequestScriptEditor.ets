import { RequestScript } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct PreRequestScriptEditor {
  @Prop script: RequestScript = { enabled: false, source: '' };
  @Prop hint: ResourceStr = $r('app.string.script_pre_request_hint');
  @Prop apiHint: ResourceStr = $r('app.string.script_pre_request_api_hint');
  @Prop editorPlaceholder: ResourceStr = $r('app.string.script_pre_request_placeholder');
  onChange: (script: RequestScript) => void = () => {};

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Row({ space: SpacingTokens.x3 }) {
        Column({ space: SpacingTokens.x1 }) {
          Text($r('app.string.script_enabled'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text(this.hint)
            .fontSize(11)
            .fontColor(ColorTokens.textTertiary)
          Text(this.apiHint)
            .fontSize(11)
            .fontFamily('monospace')
            .fontColor(ColorTokens.textTertiary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Toggle({ type: ToggleType.Switch, isOn: this.script.enabled })
          .selectedColor(ColorTokens.brand500)
          .onChange((enabled: boolean) => this.onChange({ enabled, source: this.script.source }))
      }
      .width('100%')
      .padding(SpacingTokens.x3)
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderSubtle })
      .borderRadius(RadiusTokens.medium)

      JsonCodeSurface({
        value: this.script.source,
        language: 'javascript',
        placeholder: this.editorPlaceholder,
        onChange: (source: string) => this.onChange({ enabled: this.script.enabled, source })
      })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(SpacingTokens.x4)
    .alignItems(HorizontalAlign.Start)
  }
}
