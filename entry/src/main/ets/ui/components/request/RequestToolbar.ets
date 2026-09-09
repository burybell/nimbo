import { HttpMethod, RequestLifecycle } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { MethodSelector } from './MethodSelector';
import { SendButton } from './SendButton';
import { UrlInput } from './UrlInput';

@Component
export struct RequestToolbar {
  @Prop method: HttpMethod = 'GET';
  @Prop url: string = '';
  @Prop lifecycle: RequestLifecycle = 'idle';
  onMethodChange: (value: HttpMethod) => void = () => {};
  onUrlChange: (value: string) => void = () => {};
  onSend: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Column({ space: SpacingTokens.x2 }) {
      if (this.lifecycle === 'sending') {
        Row({ space: SpacingTokens.x2 }) {
          LoadingProgress()
            .width(12)
            .height(12)
            .color(ColorTokens.brand500)
          Text($r('app.string.sending'))
            .fontSize(12)
            .fontColor(ColorTokens.brand600)
        }
        .width('100%')
      }

      Row() {
        MethodSelector({ value: this.method, onChange: this.onMethodChange })
        UrlInput({ value: this.url, onChange: this.onUrlChange, onSubmit: this.onSend })
          .layoutWeight(1)
        SendButton({ state: this.lifecycle, onSend: this.onSend, onCancel: this.onCancel })
      }
      .width('100%')
    }
    .width('100%')
  }
}
