import { HttpMethod, RequestLifecycle } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MethodSelector } from './MethodSelector';
import { SendButton } from './SendButton';
import { UrlInput } from './UrlInput';

@Component
export struct RequestToolbar {
  @Prop method: HttpMethod = 'GET';
  @Prop url: string = '';
  @Prop lifecycle: RequestLifecycle = 'idle';
  @Prop phone: boolean = false;
  onMethodChange: (value: HttpMethod) => void = () => {};
  onUrlChange: (value: string) => void = () => {};
  onSend: () => void = () => {};
  onCancel: () => void = () => {};
  onSave: () => void = () => {};

  private sendAfterEditorCommit(): void {
    setTimeout(() => this.onSend(), 0);
  }

  private saveAfterEditorCommit(): void {
    setTimeout(() => this.onSave(), 0);
  }

  @Builder
  saveButton() {
    Button($r('app.string.action_save'))
      .height(SizeTokens.controlLarge)
      .fontSize(13)
      .fontColor(ColorTokens.brand600)
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .borderRadius(RadiusTokens.medium)
      .onClick(() => this.saveAfterEditorCommit())
  }

  build() {
    Column({ space: SpacingTokens.x2 }) {
      if (this.phone) {
        Column({ space: SpacingTokens.x2 }) {
          UrlInput({ value: this.url, standalone: true, onChange: this.onUrlChange,
            onSubmit: () => this.sendAfterEditorCommit() })
            .width('100%')
          Row({ space: SpacingTokens.x2 }) {
            MethodSelector({ value: this.method, fluid: true, onChange: this.onMethodChange })
              .layoutWeight(1)
            this.saveButton()
            SendButton({ state: this.lifecycle, fluid: true,
              onSend: () => this.sendAfterEditorCommit(), onCancel: this.onCancel })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
      } else {
        Row({ space: SpacingTokens.x2 }) {
          Row() {
            MethodSelector({ value: this.method, embedded: true, onChange: this.onMethodChange })
            UrlInput({ value: this.url, embedded: true, onChange: this.onUrlChange,
              onSubmit: () => this.sendAfterEditorCommit() })
              .layoutWeight(1)
          }
          .height(SizeTokens.controlLarge)
          .layoutWeight(1)
          .backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium)
          .clip(true)
          this.saveButton()
          SendButton({ state: this.lifecycle,
            onSend: () => this.sendAfterEditorCommit(), onCancel: this.onCancel })
        }
        .width('100%')
      }
    }
    .width('100%')
  }
}
