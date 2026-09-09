import { RequestSettings } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct RequestSettingsEditor {
  @Prop settings: RequestSettings;
  onChange: (settings: RequestSettings) => void = () => {};

  private emit(timeoutMs: number, followRedirects: boolean,
    sslVerification: boolean, useCookieJar: boolean): void {
    this.onChange({ timeoutMs, followRedirects, sslVerification, useCookieJar });
  }

  @Builder
  private switchRow(title: ResourceStr, description: ResourceStr, value: boolean,
    onChange: (value: boolean) => void) {
    Row({ space: SpacingTokens.x4 }) {
      Column({ space: SpacingTokens.x1 }) {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text(description)
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(ColorTokens.brand500)
        .onChange(onChange)
    }
    .width('100%')
    .padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }

  build() {
    Scroll() {
      Column({ space: SpacingTokens.x2 }) {
        Column({ space: SpacingTokens.x2 }) {
          Text($r('app.string.timeout_title'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Select([
            { value: '5 seconds' },
            { value: '15 seconds' },
            { value: '30 seconds' },
            { value: '60 seconds' },
            { value: '120 seconds' }
          ])
            .selected(this.settings.timeoutMs === 5000 ? 0 : this.settings.timeoutMs === 15000 ? 1 :
              this.settings.timeoutMs === 60000 ? 3 : this.settings.timeoutMs === 120000 ? 4 : 2)
            .value(`${this.settings.timeoutMs / 1000} seconds`)
            .height(SizeTokens.controlMedium)
            .width(180)
            .backgroundColor(ColorTokens.bgApp)
            .borderRadius(RadiusTokens.small)
            .onSelect((index: number) => {
              const values: number[] = [5000, 15000, 30000, 60000, 120000];
              this.emit(values[index], this.settings.followRedirects,
                this.settings.sslVerification, this.settings.useCookieJar);
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        this.switchRow($r('app.string.redirect_title'), $r('app.string.request_redirect_description'),
          this.settings.followRedirects, (value: boolean) => this.emit(this.settings.timeoutMs, value,
            this.settings.sslVerification, this.settings.useCookieJar))
        this.switchRow($r('app.string.request_ssl_title'), $r('app.string.request_ssl_description'),
          this.settings.sslVerification, (value: boolean) => this.emit(this.settings.timeoutMs,
            this.settings.followRedirects, value, this.settings.useCookieJar))

        if (!this.settings.sslVerification) {
          Text($r('app.string.request_ssl_warning'))
            .fontSize(12)
            .fontColor(ColorTokens.httpDelete)
            .width('100%')
            .padding(SpacingTokens.x3)
            .backgroundColor(ColorTokens.statusDangerBackground)
            .borderRadius(RadiusTokens.small)
        }

        this.switchRow($r('app.string.cookie_jar_title'), $r('app.string.cookie_jar_description'),
          this.settings.useCookieJar, (value: boolean) => this.emit(this.settings.timeoutMs,
            this.settings.followRedirects, this.settings.sslVerification, value))
      }
      .width('100%')
      .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, bottom: SpacingTokens.x4 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }
}
