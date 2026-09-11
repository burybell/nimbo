import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';
import filePicker from '@ohos.file.picker';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
import { PostmanCodec, PostmanImportResult } from '../../../services/PostmanCodec';
import { OpenApiCodec, OpenApiImportResult } from '../../../services/OpenApiCodec';

@Component
export struct ApiFileImportDialog {
  @State step: string = 'select';
  @State dragging: boolean = false;
  @State fileName: string = '';
  @State importName: string = '';
  @State formatName: string = '';
  @State requestCount: number = 0;
  @State folderCount: number = 0;
  @State environmentCount: number = 0;
  @State warningText: string = '';
  @State errorText: string = '';
  private postmanResult: PostmanImportResult | undefined = undefined;
  private openApiResult: OpenApiImportResult | undefined = undefined;
  onCancel: () => void = () => {};
  onComplete: () => void = () => {};
  onImportPostman: (result: PostmanImportResult) => void = () => {};
  onImportOpenApi: (result: OpenApiImportResult) => void = () => {};

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

  private resetResult(): void {
    this.postmanResult = undefined;
    this.openApiResult = undefined;
    this.requestCount = 0;
    this.folderCount = 0;
    this.environmentCount = 0;
    this.warningText = '';
  }

  private analyze(text: string): void {
    let probe: Record<string, Object>;
    try {
      probe = JSON.parse(text) as Record<string, Object>;
    } catch (_error) {
      throw new Error('The selected file is not valid JSON.');
    }
    if (Object.keys(probe).includes('openapi') || Object.keys(probe).includes('swagger')) {
      const result = OpenApiCodec.parse(text);
      this.openApiResult = result;
      this.importName = result.name;
      this.formatName = result.specification;
      this.requestCount = result.requestCount;
      this.folderCount = result.folderCount;
      this.warningText = result.warnings.join('\n');
      return;
    }
    const result = PostmanCodec.parse(text);
    this.postmanResult = result;
    this.importName = result.name;
    this.formatName = result.environments.length > 0 ? 'Postman Environment' : 'Postman Collection v2';
    this.requestCount = result.requestCount;
    this.folderCount = result.folderCount;
    this.environmentCount = result.environments.length;
    this.warningText = result.warnings.join('\n');
  }

  private async processUri(uri: string): Promise<void> {
    try {
      this.resetResult();
      this.fileName = this.displayName(uri);
      this.errorText = '';
      this.step = 'analyzing';
      this.analyze(await this.readText(uri));
      this.step = 'preview';
    } catch (error) {
      this.resetResult();
      this.errorText = `${error}`.replace('Error: ', '');
      this.step = 'select';
    }
  }

  private async selectFile(): Promise<void> {
    try {
      const picker = new filePicker.DocumentViewPicker();
      const uris = await picker.select();
      if (uris.length > 0) await this.processUri(uris[0]);
    } catch (error) {
      this.errorText = `${error}`.replace('Error: ', '');
    }
  }

  private acceptDrop(event: DragEvent): void {
    this.dragging = false;
    try {
      const records = event.getData().getRecords();
      const file = records.find((record: unifiedDataChannel.UnifiedRecord) =>
        record instanceof unifiedDataChannel.File) as unifiedDataChannel.File | undefined;
      if (file === undefined || file.uri.length === 0) {
        this.errorText = 'Drop a readable JSON file.';
        return;
      }
      this.processUri(file.uri);
    } catch (_error) {
      this.errorText = 'The dropped file could not be read.';
    }
  }

  private importFile(): void {
    if (this.postmanResult !== undefined) this.onImportPostman(this.postmanResult);
    if (this.openApiResult !== undefined) this.onImportOpenApi(this.openApiResult);
    if (this.postmanResult !== undefined || this.openApiResult !== undefined) this.step = 'result';
  }

  @Builder
  private summaryRow(label: ResourceStr, value: string) {
    Row() {
      Text(label).fontSize(12).fontColor(ColorTokens.textTertiary)
      Blank()
      Text(value).fontSize(13).fontColor(ColorTokens.textPrimary)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.width('100%').height(34)
  }

  @Builder
  private content() {
    if (this.step === 'select') {
      Column({ space: SpacingTokens.x3 }) {
        Text('{ }').fontSize(28).fontWeight(FontWeight.Medium).fontColor(ColorTokens.brand500)
        Text($r('app.string.api_import_select_title')).fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text($r('app.string.api_import_support_hint')).fontSize(12).fontColor(ColorTokens.textTertiary)
          .textAlign(TextAlign.Center)
        Text($r('app.string.api_import_drop_hint')).fontSize(12).fontColor(ColorTokens.brand600)
        Button($r('app.string.select_file')).height(SizeTokens.controlLarge).fontSize(13)
          .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.medium).onClick(() => this.selectFile())
        if (this.errorText.length > 0) {
          Text(this.errorText).fontSize(12).fontColor(ColorTokens.httpDelete).textAlign(TextAlign.Center)
        }
      }
      .width('100%').height(280).justifyContent(FlexAlign.Center)
      .backgroundColor(this.dragging ? ColorTokens.bgSurfaceActive : ColorTokens.bgWorkspace)
      .border({ width: this.dragging ? 2 : 1,
        color: this.dragging ? ColorTokens.borderFocus : ColorTokens.borderSubtle,
        style: BorderStyle.Dashed })
      .borderRadius(RadiusTokens.large)
      .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
      .onDragEnter((_event: DragEvent) => { this.dragging = true; })
      .onDragLeave((_event: DragEvent) => { this.dragging = false; })
      .onDrop((event: DragEvent) => this.acceptDrop(event))
    } else if (this.step === 'analyzing') {
      Column({ space: SpacingTokens.x4 }) {
        LoadingProgress().width(34).height(34).color(ColorTokens.brand500)
        Text($r('app.string.analyzing_import')).fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text(this.fileName).fontSize(12).fontColor(ColorTokens.textTertiary)
      }.width('100%').height(280).justifyContent(FlexAlign.Center)
    } else if (this.step === 'preview') {
      Column({ space: SpacingTokens.x2 }) {
        Text($r('app.string.import_preview')).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary).width('100%')
        this.summaryRow($r('app.string.api_import_format'), this.formatName)
        this.summaryRow($r('app.string.collection_name'), this.importName)
        this.summaryRow($r('app.string.requests'), this.requestCount.toString())
        this.summaryRow($r('app.string.folders'), this.folderCount.toString())
        this.summaryRow($r('app.string.nav_environments'), this.environmentCount.toString())
        Row() {
          Text($r('app.string.unsupported_features')).fontSize(12).fontColor(ColorTokens.textTertiary)
          Blank()
          Text(this.warningText.length > 0 ? '!' : '0').fontSize(13)
            .fontColor(this.warningText.length > 0 ? ColorTokens.statusClientError : ColorTokens.statusSuccess)
        }.width('100%').height(34)
        if (this.warningText.length > 0) {
          Text(this.warningText).fontSize(11).fontColor(ColorTokens.statusClientError).maxLines(3)
        }
      }.width('100%').padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    } else {
      Column({ space: SpacingTokens.x4 }) {
        Text('✓').fontSize(34).fontColor(ColorTokens.statusSuccess)
        Text($r('app.string.import_complete')).fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
        Text(this.formatName).fontSize(13).fontColor(ColorTokens.textSecondary)
      }.width('100%').height(280).justifyContent(FlexAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim).onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Row() {
          Text($r('app.string.api_import_title')).fontSize(18).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Blank()
          Text('×').fontSize(20).fontColor(ColorTokens.textTertiary).onClick(this.onCancel)
        }.width('100%')
        Row({ space: SpacingTokens.x2 }) {
          Text($r('app.string.step_select')).fontSize(11)
            .fontColor(this.step === 'select' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_analyze')).fontSize(11)
            .fontColor(this.step === 'analyzing' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_preview')).fontSize(11)
            .fontColor(this.step === 'preview' ? ColorTokens.brand600 : ColorTokens.textTertiary)
          Text('—').fontColor(ColorTokens.borderDefault)
          Text($r('app.string.step_result')).fontSize(11)
            .fontColor(this.step === 'result' ? ColorTokens.brand600 : ColorTokens.textTertiary)
        }.width('100%')
        this.content()
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          if (this.step !== 'analyzing') {
            Button(this.step === 'result' ? $r('app.string.action_done') : $r('app.string.action_cancel'))
              .height(SizeTokens.controlMedium).fontSize(13).fontColor(ColorTokens.textPrimary)
              .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderDefault })
              .borderRadius(RadiusTokens.medium).onClick(this.step === 'result' ? this.onComplete : this.onCancel)
          }
          if (this.step === 'preview') {
            Button($r('app.string.import_action')).height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
              .borderRadius(RadiusTokens.medium).onClick(() => this.importFile())
          }
        }.width('100%')
      }
      .width(600).padding(SpacingTokens.x6).backgroundColor(ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.large).shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 }))
        .combine(TransitionEffect.scale({ x: 0.96, y: 0.96 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
    .transition(TransitionEffect.OPACITY.animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }
}
