import {
  AuthConfig,
  BodyType,
  EnvironmentModel,
  ExtractionRule,
  HttpMethod,
  KeyValueItem,
  RequestConfigTab,
  RequestDraft,
  RequestLifecycle,
  RequestScript,
  RequestSettings,
  ResponseModel,
  TestRule
} from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';
import { AuthEditor } from './AuthEditor';
import { BodyEditor } from './BodyEditor';
import { ExtractionEditor } from './ExtractionEditor';
import { KeyValueEditor } from './KeyValueEditor';
import { PreRequestScriptEditor } from './PreRequestScriptEditor';
import { RequestConfigTabs } from './RequestConfigTabs';
import { RequestSettingsEditor } from './RequestSettingsEditor';
import { RequestToolbar } from './RequestToolbar';
import { TestsEditor } from './TestsEditor';

@Component
export struct RequestPanel {
  @Prop request: RequestDraft;
  @Prop phone: boolean = false;
  @Prop environments: EnvironmentModel[] = [];
  @Prop response: ResponseModel;
  onChange: (request: RequestDraft) => void = () => {};
  onSave: () => void = () => {};

  private emit(method: HttpMethod, url: string, lifecycle: RequestLifecycle,
    activeConfigTab: RequestConfigTab, params: KeyValueItem[], headers: KeyValueItem[],
    auth: AuthConfig, bodyType: BodyType, bodyText: string, formItems: KeyValueItem[],
    multipartItems: KeyValueItem[], binaryFileName: string,
    settings: RequestSettings = this.request.settings,
    extractionRules: ExtractionRule[] = this.request.extractionRules,
    testRules: TestRule[] = this.request.testRules,
    preRequestScript: RequestScript = this.request.preRequestScript,
    postResponseScript: RequestScript = this.request.postResponseScript): void {
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
      preRequestScript,
      postResponseScript,
      extractionRules,
      testRules,
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
          this.request.activeConfigTab),
        onSave: this.onSave
      })
        .padding({ left: this.phone ? SpacingTokens.x3 : SpacingTokens.x4,
          right: this.phone ? SpacingTokens.x3 : SpacingTokens.x4,
          top: this.phone ? SpacingTokens.x3 : SpacingTokens.x4, bottom: SpacingTokens.x3 })

      RequestConfigTabs({
        activeTab: this.request.activeConfigTab,
        headerCount: this.enabledHeaderCount(),
        bodyHasContent: this.bodyHasContent(),
        preRequestEnabled: this.request.preRequestScript.enabled,
        postResponseEnabled: this.request.postResponseScript.enabled,
        extractionCount: this.request.extractionRules.filter((rule: ExtractionRule) => rule.enabled).length,
        testCount: this.request.testRules.filter((rule: TestRule) => rule.enabled).length,
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
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
          .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
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
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
          .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else if (this.request.activeConfigTab === 'auth') {
        AuthEditor({
          config: this.request.auth,
          onChange: (auth: AuthConfig) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
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
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else if (this.request.activeConfigTab === 'preRequest') {
        PreRequestScriptEditor({
          script: this.request.preRequestScript,
          onChange: (script: RequestScript) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, this.request.settings,
            this.request.extractionRules, this.request.testRules, script)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else if (this.request.activeConfigTab === 'postResponse') {
        PreRequestScriptEditor({
          script: this.request.postResponseScript,
          hint: $r('app.string.script_post_response_hint'),
          apiHint: $r('app.string.script_post_response_api_hint'),
          editorPlaceholder: $r('app.string.script_post_response_placeholder'),
          onChange: (script: RequestScript) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, this.request.settings,
            this.request.extractionRules, this.request.testRules, this.request.preRequestScript, script)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else if (this.request.activeConfigTab === 'extract') {
        ExtractionEditor({
          rules: this.request.extractionRules,
          environments: this.environments,
          response: this.response,
          phone: this.phone,
          onChange: (rules: ExtractionRule[]) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, this.request.settings, rules)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else if (this.request.activeConfigTab === 'tests') {
        TestsEditor({
          rules: this.request.testRules,
          phone: this.phone,
          onChange: (rules: TestRule[]) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, this.request.settings,
            this.request.extractionRules, rules)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
      } else {
        RequestSettingsEditor({
          settings: this.request.settings,
          onChange: (settings: RequestSettings) => this.emit(this.request.method, this.request.url,
            this.request.lifecycle, this.request.activeConfigTab, this.request.params, this.request.headers,
            this.request.auth, this.request.bodyType, this.request.bodyText, this.request.formItems,
            this.request.multipartItems, this.request.binaryFileName, settings)
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 6 }))
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
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
