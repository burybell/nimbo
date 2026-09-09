import { HttpMethod } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ImportCurlDialog {
  @State curlText: string = "curl -X GET 'https://api.example.com/users'";
  @State state: string = 'idle';
  @State errorText: string = '';
  onCancel: () => void = () => {};
  onImport: (method: HttpMethod, url: string) => void = () => {};

  private parsedMethod(): HttpMethod {
    const upper = this.curlText.toUpperCase();
    if (upper.includes('-X POST')) return 'POST';
    if (upper.includes('-X PUT')) return 'PUT';
    if (upper.includes('-X PATCH')) return 'PATCH';
    if (upper.includes('-X DELETE')) return 'DELETE';
    if (upper.includes('-X HEAD')) return 'HEAD';
    if (upper.includes('-X OPTIONS')) return 'OPTIONS';
    return 'GET';
  }

  private parsedUrl(): string {
    const words = this.curlText.replaceAll('\n', ' ').split(' ');
    for (let index = 0; index < words.length; index += 1) {
      const clean = words[index].trim().replaceAll("'", '').replaceAll('"', '');
      if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    }
    return '';
  }

  private importCurl(): void {
    if (!this.curlText.trim().toLowerCase().startsWith('curl')) {
      this.state = 'invalid';
      this.errorText = 'Line 1: expected a command beginning with curl.';
      return;
    }
    const url = this.parsedUrl();
    if (url.length === 0) {
      this.state = 'invalid';
      this.errorText = 'Line 1: no valid http:// or https:// URL was found.';
      return;
    }
    this.state = 'importing';
    setTimeout(() => this.onImport(this.parsedMethod(), url), 350);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#520F1422').onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text('Import cURL').fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
            Text('Paste a cURL command to create a request.').fontSize(12).fontColor(ColorTokens.textTertiary)
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
          Text('Headers and body values are kept in the request draft.')
            .fontSize(11).fontColor(ColorTokens.textTertiary)
          Blank()
          Button('Cancel').height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textPrimary)
            .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.medium).onClick(this.onCancel)
          Button(this.state === 'importing' ? 'Importing…' : 'Import')
            .height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textOnBrand)
            .backgroundColor(ColorTokens.brand500).borderRadius(RadiusTokens.medium)
            .enabled(this.state !== 'importing').onClick(() => this.importCurl())
        }.width('100%')
      }
      .width(620)
      .padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: '#33000000', offsetY: 8 })
    }
    .width('100%').height('100%')
  }
}
