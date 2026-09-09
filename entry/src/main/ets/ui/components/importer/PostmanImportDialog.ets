import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct PostmanImportDialog {
  @State step: string = 'select';
  @State fileName: string = '';
  onCancel: () => void = () => {};
  onComplete: () => void = () => {};

  private selectFile(): void {
    this.fileName = 'Nimbo Demo.postman_collection.json';
    this.step = 'analyzing';
    setTimeout(() => { this.step = 'preview'; }, 650);
  }

  private importFile(): void {
    this.step = 'result';
  }

  @Builder
  content() {
    if (this.step === 'select') {
      Column({ space: SpacingTokens.x4 }) {
        Text('⇧').fontSize(34).fontColor(ColorTokens.brand500)
        Text('Select a Postman export').fontSize(16).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text('Supports Collection v2, v2.1, and Environment JSON.')
          .fontSize(12).fontColor(ColorTokens.textTertiary)
        Button('Select File').height(SizeTokens.controlLarge).fontSize(13).fontColor(ColorTokens.textOnBrand)
          .backgroundColor(ColorTokens.brand500).borderRadius(RadiusTokens.medium).onClick(() => this.selectFile())
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    } else if (this.step === 'analyzing') {
      Column({ space: SpacingTokens.x4 }) {
        LoadingProgress().width(34).height(34).color(ColorTokens.brand500)
        Text('Analyzing import…').fontSize(16).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text(this.fileName).fontSize(12).fontColor(ColorTokens.textTertiary)
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    } else if (this.step === 'preview') {
      Column({ space: SpacingTokens.x3 }) {
        Text('Import Preview').fontSize(15).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary).width('100%')
        Row() { Text('Collection Name').fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text('Nimbo Demo API').fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text('Requests').fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text('18').fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text('Folders').fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text('4').fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text('Environments').fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text('1').fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text('Unsupported features').fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text('1 OAuth configuration').fontSize(13).fontColor(ColorTokens.statusClientError) }.width('100%').height(36)
      }.width('100%').padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    } else {
      Column({ space: SpacingTokens.x4 }) {
        Text('✓').fontSize(34).fontColor(ColorTokens.statusSuccess)
        Text('Import complete').fontSize(17).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text('17 / 18 requests imported').fontSize(14).fontColor(ColorTokens.textPrimary)
        Text('1 request contains unsupported OAuth configuration.')
          .fontSize(12).fontColor(ColorTokens.statusClientError)
        Text('View Details').fontSize(12).fontColor(ColorTokens.brand600)
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#520F1422').onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Row() {
          Text('Import from Postman').fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
          Blank()
          Text('×').fontSize(20).fontColor(ColorTokens.textTertiary).onClick(this.onCancel)
        }.width('100%')
        Row({ space: SpacingTokens.x2 }) {
          Text('1  Select').fontSize(11).fontColor(this.step === 'select' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text('2  Analyze').fontSize(11).fontColor(this.step === 'analyzing' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text('3  Preview').fontSize(11).fontColor(this.step === 'preview' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text('4  Result').fontSize(11).fontColor(this.step === 'result' ? ColorTokens.brand600 : ColorTokens.textTertiary)
        }.width('100%')
        this.content()
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          if (this.step !== 'analyzing') {
            Button(this.step === 'result' ? 'Done' : 'Cancel').height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
              .onClick(this.step === 'result' ? this.onComplete : this.onCancel)
          }
          if (this.step === 'preview') {
            Button('Import').height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textOnBrand)
              .backgroundColor(ColorTokens.brand500).borderRadius(RadiusTokens.medium).onClick(() => this.importFile())
          }
        }.width('100%')
      }
      .width(580)
      .padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: '#33000000', offsetY: 8 })
    }
    .width('100%').height('100%')
  }
}
