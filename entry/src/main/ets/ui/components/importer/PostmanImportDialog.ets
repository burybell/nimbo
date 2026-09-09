import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import filePicker from '@ohos.file.picker';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { PostmanCodec, PostmanImportResult } from '../../../services/PostmanCodec';

@Component
export struct PostmanImportDialog {
  @State step: string = 'select';
  @State fileName: string = '';
  @State importName: string = '';
  @State requestCount: number = 0;
  @State folderCount: number = 0;
  @State environmentCount: number = 0;
  @State warningText: string = '';
  @State errorText: string = '';
  private parsedResult: PostmanImportResult | undefined = undefined;
  onCancel: () => void = () => {};
  onComplete: () => void = () => {};
  onImport: (result: PostmanImportResult) => void = () => {};

  private displayName(uri: string): string {
    const slash = uri.lastIndexOf('/');
    const name = slash < 0 ? uri : uri.substring(slash + 1);
    try { return decodeURIComponent(name); } catch (_error) { return name; }
  }

  private async readText(uri: string): Promise<string> {
    let descriptor = -1;
    try {
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
      descriptor = file.fd;
      const stat = await fileIo.stat(descriptor);
      if (stat.size > 10 * 1024 * 1024) throw new Error('The selected file exceeds the 10 MB import limit.');
      const buffer = new ArrayBuffer(stat.size);
      const bytesRead = await fileIo.read(descriptor, buffer);
      return new util.TextDecoder().decodeToString(new Uint8Array(buffer.slice(0, bytesRead)));
    } catch (error) {
      if (error instanceof Error) throw error;
      throw new Error('The selected file could not be read.');
    } finally {
      if (descriptor >= 0) {
        try { fileIo.closeSync(descriptor); } catch (_error) {}
      }
    }
  }

  private async selectFile(): Promise<void> {
    try {
      const picker = new filePicker.DocumentViewPicker();
      const uris = await picker.select();
      if (uris.length === 0) return;
      this.fileName = this.displayName(uris[0]);
      this.errorText = '';
      this.step = 'analyzing';
      const text = await this.readText(uris[0]);
      const result = PostmanCodec.parse(text);
      this.parsedResult = result;
      this.importName = result.name;
      this.requestCount = result.requestCount;
      this.folderCount = result.folderCount;
      this.environmentCount = result.environments.length;
      this.warningText = result.warnings.join('\n');
      this.step = 'preview';
    } catch (error) {
      this.parsedResult = undefined;
      this.errorText = `${error}`.replace('Error: ', '');
      this.step = 'select';
    }
  }

  private importFile(): void {
    if (!this.parsedResult) return;
    this.onImport(this.parsedResult);
    this.step = 'result';
  }

  @Builder
  content() {
    if (this.step === 'select') {
      Column({ space: SpacingTokens.x4 }) {
        Text('⇧').fontSize(34).fontColor(ColorTokens.brand500)
        Text($r('app.string.postman_select_title')).fontSize(16).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text($r('app.string.postman_support_hint'))
          .fontSize(12).fontColor(ColorTokens.textTertiary)
        Button($r('app.string.select_file')).height(SizeTokens.controlLarge).fontSize(13).fontColor(ColorTokens.textOnBrand)
          .backgroundColor(ColorTokens.brand500).borderRadius(RadiusTokens.medium).onClick(() => this.selectFile())
        if (this.errorText.length > 0) {
          Text(this.errorText).fontSize(12).fontColor(ColorTokens.httpDelete).textAlign(TextAlign.Center)
        }
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    } else if (this.step === 'analyzing') {
      Column({ space: SpacingTokens.x4 }) {
        LoadingProgress().width(34).height(34).color(ColorTokens.brand500)
        Text($r('app.string.analyzing_import')).fontSize(16).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Text(this.fileName).fontSize(12).fontColor(ColorTokens.textTertiary)
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    } else if (this.step === 'preview') {
      Column({ space: SpacingTokens.x3 }) {
        Text($r('app.string.import_preview')).fontSize(15).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary).width('100%')
        Row() { Text($r('app.string.collection_name')).fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text(this.importName).fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text($r('app.string.requests')).fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text(this.requestCount.toString()).fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text($r('app.string.folders')).fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text(this.folderCount.toString()).fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text($r('app.string.nav_environments')).fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text(this.environmentCount.toString()).fontSize(13).fontColor(ColorTokens.textPrimary) }.width('100%').height(36)
        Row() { Text($r('app.string.unsupported_features')).fontSize(12).fontColor(ColorTokens.textTertiary); Blank(); Text(this.parsedResult ? this.parsedResult.warnings.length.toString() : '0').fontSize(13).fontColor(this.warningText.length > 0 ? ColorTokens.statusClientError : ColorTokens.statusSuccess) }.width('100%').height(36)
        if (this.warningText.length > 0) {
          Text(this.warningText).fontSize(11).fontColor(ColorTokens.statusClientError).maxLines(3)
        }
      }.width('100%').padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    } else {
      Column({ space: SpacingTokens.x4 }) {
        Text('✓').fontSize(34).fontColor(ColorTokens.statusSuccess)
        Text($r('app.string.import_complete')).fontSize(17).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
        Row({ space: SpacingTokens.x2 }) {
          Text(this.requestCount.toString()).fontSize(14).fontColor(ColorTokens.textPrimary)
          Text($r('app.string.requests')).fontSize(14).fontColor(ColorTokens.textPrimary)
          Text('·').fontSize(14).fontColor(ColorTokens.textTertiary)
          Text(this.environmentCount.toString()).fontSize(14).fontColor(ColorTokens.textPrimary)
          Text($r('app.string.nav_environments')).fontSize(14).fontColor(ColorTokens.textPrimary)
        }
        if (this.warningText.length > 0) {
          Text(this.warningText).fontSize(12).fontColor(ColorTokens.statusClientError).maxLines(3)
        }
      }.width('100%').height(260).justifyContent(FlexAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor('#520F1422').onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Row() {
          Text($r('app.string.postman_title')).fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
          Blank()
          Text('×').fontSize(20).fontColor(ColorTokens.textTertiary).onClick(this.onCancel)
        }.width('100%')
        Row({ space: SpacingTokens.x2 }) {
          Text($r('app.string.step_select')).fontSize(11).fontColor(this.step === 'select' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_analyze')).fontSize(11).fontColor(this.step === 'analyzing' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_preview')).fontSize(11).fontColor(this.step === 'preview' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_result')).fontSize(11).fontColor(this.step === 'result' ? ColorTokens.brand600 : ColorTokens.textTertiary)
        }.width('100%')
        this.content()
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          if (this.step !== 'analyzing') {
            Button(this.step === 'result' ? $r('app.string.action_done') : $r('app.string.action_cancel')).height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
              .onClick(this.step === 'result' ? this.onComplete : this.onCancel)
          }
          if (this.step === 'preview') {
            Button($r('app.string.import_action')).height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textOnBrand)
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
