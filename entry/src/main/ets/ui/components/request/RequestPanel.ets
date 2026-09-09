import {
  AuthConfig,
  BodyType,
  HttpMethod,
  KeyValueItem,
  RequestConfigTab,
  RequestDraft,
  RequestLifecycle,
  RequestSettings
} from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { AuthEditor } from './AuthEditor';
import { BodyEditor } from './BodyEditor';
import { KeyValueEditor } from './KeyValueEditor';
import { RequestConfigTabs } from './RequestConfigTabs';
import { RequestSettingsEditor } from './RequestSettingsEditor';
import { RequestToolbar } from './RequestToolbar';

@Component
export struct RequestPanel {
  @Prop request: RequestDraft;
  @Prop phone: boolean = false;
  onChange: (request: RequestDraft) => void = () => {};

  private emit(method: HttpMethod, url: string, lifecycle: RequestLifecycle,
    activeConfigTab: RequestConfigTab, params: KeyValueItem[], headers: KeyValueItem[],
    auth: AuthConfig, bodyType: BodyType, bodyText: string, formItems: KeyValueItem[],
    multipartItems: KeyValueItem[], binaryFileName: string,
    settings: RequestSettings = this.request.settings): void {
    this.onChange({
      method,
      url,
      lifecycle,
      activeConfigTab,
      params,
      headers,
      auth,
      bodyType,
      bodyText,
      formItems,
      multipartItems,
      binaryFileName,
      settings
    });
  }

  private emitCore(method: HttpMethod, url: string, lifecycle: RequestLifecycle,
    activeConfigTab: RequestConfigTab): void {
    this.emit(method, url, lifecycle, activeConfigTab, this.request.params, this.request.headers,
      this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
      this.request.multipartItems, this.request.binaryFileName);
  }

  private bodyHasContent(): boolean {
    if (this.request.bodyType === 'form') return this.request.formItems.length > 0;
    if (this.request.bodyType === 'multipart') return this.request.multipartItems.length > 0;
    if (this.request.bodyType === 'binary') return this.request.binaryFileName.length > 0;
    return this.request.bodyType !== 'none' && this.request.bodyText.length > 0;
  }

  private enabledHeaderCount(): number {
    return this.request.headers.filter((item: KeyValueItem) => item.enabled).length;
  }

  build() {
    Column() {
      RequestToolbar({
        method: this.request.method,
        url: this.request.url,
        lifecycle: this.request.lifecycle,
        phone: this.phone,
        onMethodChange: (method: HttpMethod) => this.emitCore(method, this.request.url,
          this.request.lifecycle, this.request.activeConfigTab),
        onUrlChange: (url: string) => this.emitCore(this.request.method, url,
          this.request.lifecycle, this.request.activeConfigTab),
        onSend: () => this.emitCore(this.request.method, this.request.url, 'sending',
          this.request.activeConfigTab),
        onCancel: () => this.emitCore(this.request.method, this.request.url, 'idle',
          this.request.activeConfigTab)
      })
        .padding({ left: this.phone ? SpacingTokens.x3 : SpacingTokens.x4,
          right: this.phone ? SpacingTokens.x3 : SpacingTokens.x4,
          top: this.phone ? SpacingTokens.x3 : SpacingTokens.x4, bottom: SpacingTokens.x3 })

      RequestConfigTabs({
        activeTab: this.request.activeConfigTab,
        headerCount: this.enabledHeaderCount(),
        bodyHasContent: this.bodyHasContent(),
        onChange: (tab: RequestConfigTab) => this.emitCore(this.request.method, this.request.url,
          this.request.lifecycle, tab)
      })

      if (this.request.activeConfigTab === 'params') {
        Scroll() {
          KeyValueEditor({
            items: this.request.params,
            mode: 'params',
            showDescription: true,
            onChange: (items: KeyValueItem[]) => this.emit(this.request.method, this.request.url,
              this.request.lifecycle, this.request.activeConfigTab, items, this.request.headers,
              this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
              this.request.multipartItems, this.request.binaryFileName)
          })
          .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)
      } else if (this.request.activeConfigTab === 'headers') {
        Scroll() {
          KeyValueEditor({
            items: this.request.headers,
            mode: 'headers',
            showDescription: true,
            onChange: (items: KeyValueItem[]) => this.emit(this.request.method, this.request.url,
              this.request.lifecycle, this.request.activeConfigTab, this.request.params, items,
              this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
              this.request.multipartItems, this.request.binaryFileName)
          })
          .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)
      } else if (this.request.activeConfigTab === 'auth') {
        AuthEditor({
          config: this.request.auth,
          onChange: (auth: AuthConfig) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName)
        })
          .layoutWeight(1)
      } else if (this.request.activeConfigTab === 'body') {
        BodyEditor({
          bodyType: this.request.bodyType,
          bodyText: this.request.bodyText,
          formItems: this.request.formItems,
          multipartItems: this.request.multipartItems,
          binaryFileName: this.request.binaryFileName,
          onTypeChange: (bodyType: BodyType) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName),
          onTextChange: (bodyText: string) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName),
          onFormChange: (formItems: KeyValueItem[]) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, formItems,
            this.request.multipartItems, this.request.binaryFileName),
          onMultipartChange: (multipartItems: KeyValueItem[]) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            multipartItems, this.request.binaryFileName),
          onBinaryFileChange: (binaryFileName: string) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, binaryFileName)
        })
          .layoutWeight(1)
      } else {
        RequestSettingsEditor({
          settings: this.request.settings,
          onChange: (settings: RequestSettings) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, settings)
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgWorkspace)
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyCode === 2054 &&
        event.getModifierKeyState !== undefined && event.getModifierKeyState(['ctrl'])) {
        this.emitCore(this.request.method, this.request.url,
          this.request.lifecycle === 'sending' ? 'idle' : 'sending', this.request.activeConfigTab);
        return true;
      }
      return false;
    })
  }
}
