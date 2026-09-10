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

  @Builder
  saveButton() {
    Button($r('app.string.action_save'))
      .height(SizeTokens.controlLarge)
      .fontSize(13)
      .fontColor(ColorTokens.brand600)
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .borderRadius(RadiusTokens.medium)
      .onClick(this.onSave)
  }

  build() {
    Column({ space: SpacingTokens.x2 }) {
      if (this.phone) {
        Column({ space: SpacingTokens.x2 }) {
          UrlInput({ value: this.url, onChange: this.onUrlChange, onSubmit: this.onSend })
            .width('100%')
          Row({ space: SpacingTokens.x2 }) {
            MethodSelector({ value: this.method, fluid: true, onChange: this.onMethodChange })
              .layoutWeight(1)
            this.saveButton()
            SendButton({ state: this.lifecycle, fluid: true, onSend: this.onSend, onCancel: this.onCancel })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
      } else {
        Row() {
          MethodSelector({ value: this.method, onChange: this.onMethodChange })
          UrlInput({ value: this.url, onChange: this.onUrlChange, onSubmit: this.onSend })
            .layoutWeight(1)
          this.saveButton()
          SendButton({ state: this.lifecycle, onSend: this.onSend, onCancel: this.onCancel })
        }
        .width('100%')
      }
    }
    .width('100%')
  }
}
