import { RequestDraft } from '../../../models/ShellModels';
import { RequestCodeGenerator, RequestCodeLanguage } from '../../../services/RequestCodeGenerator';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { CurlCodeSurface } from '../common/CurlCodeSurface';
import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct CodeGenerationEditor {
  @Prop request: RequestDraft;
  @State language: RequestCodeLanguage = 'curl';
  onCopy: (value: string) => void = () => {};

  private code(): string {
    return RequestCodeGenerator.generate(this.request, this.language);
  }

  private languageLabel(language: RequestCodeLanguage): string {
    if (language === 'curl') return 'cURL';
    if (language === 'javascript') return 'JavaScript · Fetch';
    if (language === 'python') return 'Python · Requests';
    return 'Go · net/http';
  }

  @Builder
  private languageItem(language: RequestCodeLanguage) {
    Text(this.languageLabel(language))
      .fontSize(11)
      .fontWeight(this.language === language ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.language === language ? ColorTokens.brand600 : ColorTokens.textSecondary)
      .height(SizeTokens.controlSmall)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.language === language ? ColorTokens.bgSurface : Color.Transparent)
      .borderRadius(RadiusTokens.small)
      .onClick(() => { this.language = language; })
  }

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Text($r('app.string.generate_hint'))
        .fontSize(11)
        .fontColor(ColorTokens.textTertiary)
        .width('100%')

      Row({ space: SpacingTokens.x2 }) {
        Scroll() {
          Row() {
            this.languageItem('curl')
            this.languageItem('javascript')
            this.languageItem('python')
            this.languageItem('go')
          }
          .padding(3)
          .backgroundColor(ColorTokens.bgApp)
          .borderRadius(RadiusTokens.medium)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Button($r('app.string.generate_copy'))
          .height(SizeTokens.controlSmall)
          .fontSize(11)
          .fontColor(ColorTokens.brand600)
          .backgroundColor(ColorTokens.brand50)
          .borderRadius(RadiusTokens.small)
          .onClick(() => this.onCopy(this.code()))
      }
      .width('100%')

      if (this.language === 'curl') {
        CurlCodeSurface({ value: this.code(), readOnly: true })
          .layoutWeight(1)
      } else {
        JsonCodeSurface({
          value: this.code(),
          readOnly: true,
          syntaxHighlight: true,
          language: this.language
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4,
      top: SpacingTokens.x3, bottom: SpacingTokens.x4 })
    .alignItems(HorizontalAlign.Start)
  }
}
