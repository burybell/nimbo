import { CurlCodec, CurlImportResult } from '../../../services/CurlCodec';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct ImportCurlDialog {
  @State curlText: string = "curl -X GET 'https://api.example.com/users'";
  @State state: string = 'idle';
  @State errorText: string = '';
  onCancel: () => void = () => {};
  onImport: (result: CurlImportResult) => void = () => {};

  private importCurl(): void {
    try {
      const result = CurlCodec.parse(this.curlText);
      this.state = 'importing';
      setTimeout(() => this.onImport(result), 120);
    } catch (error) {
      this.state = 'invalid';
      this.errorText = `${error}`.replace('Error: ', '');
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim).onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text($r('app.string.import_curl')).fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
            Text($r('app.string.curl_paste_hint')).fontSize(12).fontColor(ColorTokens.textTertiary)
          }
          Blank()
          Text('×').fontSize(20).fontColor(ColorTokens.textTertiary).onClick(this.onCancel)
        }
        .width('100%')
        TextArea({ text: this.curlText, placeholder: 'curl https://api.example.com/users' })
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor(ColorTokens.textPrimary)
          .height(210)
          .padding(SpacingTokens.x3)
          .backgroundColor(ColorTokens.bgApp)
          .border({ width: 1, color: this.state === 'invalid' ? ColorTokens.httpDelete : ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium)
          .onChange((value: string) => { this.curlText = value; this.state = 'idle'; this.errorText = ''; })
        if (this.errorText.length > 0) {
          Row({ space: SpacingTokens.x2 }) {
            Text('!').fontSize(12).fontColor(ColorTokens.httpDelete)
            Text(this.errorText).fontSize(12).fontColor(ColorTokens.httpDelete)
          }.width('100%')
        }
        Row({ space: SpacingTokens.x3 }) {
          Text($r('app.string.curl_values_hint'))
            .fontSize(11).fontColor(ColorTokens.textTertiary)
          Blank()
          Button($r('app.string.action_cancel')).height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textPrimary)
            .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.medium).onClick(this.onCancel)
          Button(this.state === 'importing' ? $r('app.string.importing') : $r('app.string.import_action'))
            .height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textOnBrand)
            .backgroundColor(ColorTokens.brand500).borderRadius(RadiusTokens.medium)
            .enabled(this.state !== 'importing').onClick(() => this.importCurl())
        }.width('100%')
      }
      .width(620)
      .padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 8 }))
        .combine(TransitionEffect.scale({ x: 0.96, y: 0.96 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
    .transition(TransitionEffect.OPACITY
      .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }
}
