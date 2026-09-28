import { BodyType, KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { JsonCodeSurface } from '../common/JsonCodeSurface';
import { JsonEditor } from './JsonEditor';

@Component
export struct SseBodyEditor {
  @Prop bodyType: BodyType = 'none';
  @Prop bodyText: string = '';
  @Prop variables: KeyValueItem[] = [];
  onTypeChange: (bodyType: BodyType) => void = () => {};
  onTextChange: (value: string) => void = () => {};

  @Builder
  private typeItem(type: BodyType, label: ResourceStr) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.bodyType === type ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.bodyType === type ? ColorTokens.brand600 : ColorTokens.textSecondary)
      .height(SizeTokens.controlSmall)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .textAlign(TextAlign.Center)
      .backgroundColor(this.bodyType === type ? ColorTokens.bgSurface : ColorTokens.bgApp)
      .borderRadius(RadiusTokens.small)
      .onClick(() => this.onTypeChange(type))
  }

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Row() {
        this.typeItem('none', $r('app.string.body_none'))
        this.typeItem('json', 'JSON')
        this.typeItem('text', $r('app.string.body_text'))
      }
      .padding(3)
      .backgroundColor(ColorTokens.bgApp)
      .borderRadius(RadiusTokens.medium)

      if (this.bodyType === 'none') {
        Column({ space: SpacingTokens.x2 }) {
          Text($r('app.string.body_empty_title')).fontSize(14).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text($r('app.string.sse_body_empty_description')).fontSize(12).fontColor(ColorTokens.textTertiary)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.bodyType === 'json') {
        JsonEditor({ value: this.bodyText, variables: this.variables, onChange: this.onTextChange })
          .layoutWeight(1)
      } else {
        JsonCodeSurface({ value: this.bodyText, variables: this.variables, syntaxHighlight: false,
          placeholder: $r('app.string.body_text_placeholder'), onChange: this.onTextChange })
          .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x3,
      bottom: SpacingTokens.x4 })
    .alignItems(HorizontalAlign.Start)
  }
}
