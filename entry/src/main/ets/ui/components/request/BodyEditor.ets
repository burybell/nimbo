import { BodyType, KeyValueItem } from '../../../models/ShellModels';
import filePicker from '@ohos.file.picker';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { JsonEditor } from './JsonEditor';
import { KeyValueEditor } from './KeyValueEditor';

@Component
export struct BodyEditor {
  @Prop bodyType: BodyType = 'none';
  @Prop bodyText: string = '';
  @Prop formItems: KeyValueItem[] = [];
  @Prop multipartItems: KeyValueItem[] = [];
  @Prop binaryFileName: string = '';
  onTypeChange: (bodyType: BodyType) => void = () => {};
  onTextChange: (value: string) => void = () => {};
  onFormChange: (items: KeyValueItem[]) => void = () => {};
  onMultipartChange: (items: KeyValueItem[]) => void = () => {};
  onBinaryFileChange: (uri: string) => void = () => {};

  private async selectBinaryFile(): Promise<void> {
    try {
      const picker = new filePicker.DocumentViewPicker();
      const uris = await picker.select();
      if (uris.length > 0) {
        this.onBinaryFileChange(uris[0]);
      }
    } catch (_error) {
      // Cancelling the system picker keeps the previous selection.
    }
  }

  @Builder
  private typeItem(type: BodyType, label: string) {
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
        this.typeItem('none', 'None')
        this.typeItem('json', 'JSON')
        this.typeItem('text', 'Text')
        this.typeItem('form', 'Form')
        this.typeItem('multipart', 'Multipart')
        this.typeItem('binary', 'Binary')
      }
      .padding(3)
      .backgroundColor(ColorTokens.bgApp)
      .borderRadius(RadiusTokens.medium)

      if (this.bodyType === 'none') {
        Column({ space: SpacingTokens.x2 }) {
          Text('No request body')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text('Select a body type when the endpoint expects payload data.')
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.bodyType === 'json') {
        JsonEditor({ value: this.bodyText, onChange: this.onTextChange })
          .layoutWeight(1)
      } else if (this.bodyType === 'text') {
        TextArea({ text: this.bodyText, placeholder: 'Plain text request body' })
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor(ColorTokens.textPrimary)
          .height('100%')
          .padding(SpacingTokens.x3)
          .backgroundColor(ColorTokens.bgWorkspace)
          .border({ width: 1, color: ColorTokens.borderSubtle })
          .borderRadius(RadiusTokens.small)
          .layoutWeight(1)
          .onChange((value: string) => this.onTextChange(value))
      } else if (this.bodyType === 'form') {
        KeyValueEditor({
          items: this.formItems,
          mode: 'form',
          showDescription: true,
          onChange: this.onFormChange
        })
      } else if (this.bodyType === 'multipart') {
        KeyValueEditor({
          items: this.multipartItems,
          mode: 'multipart',
          showDescription: true,
          showType: true,
          onChange: this.onMultipartChange
        })
      } else {
        Column({ space: SpacingTokens.x3 }) {
          Text('Binary file')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text(this.binaryFileName.length > 0 ? this.binaryFileName : 'No file selected')
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Button(this.binaryFileName.length > 0 ? 'Choose Another File' : 'Choose File')
            .fontSize(12)
            .fontColor(ColorTokens.brand600)
            .height(SizeTokens.controlMedium)
            .backgroundColor(ColorTokens.brand50)
            .borderRadius(RadiusTokens.small)
            .onClick(() => this.selectBinaryFile())
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4, top: SpacingTokens.x3, bottom: SpacingTokens.x4 })
    .alignItems(HorizontalAlign.Start)
  }
}
