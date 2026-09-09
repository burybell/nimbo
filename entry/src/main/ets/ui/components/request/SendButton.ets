import { RequestLifecycle } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct SendButton {
  @Prop state: RequestLifecycle = 'idle';
  onSend: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Button() {
      Row({ space: SpacingTokens.x2 }) {
        if (this.state === 'sending') {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(ColorTokens.textOnBrand)
        }
        Text(this.state === 'sending' ? $r('app.string.action_cancel') : $r('app.string.action_send'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textOnBrand)
      }
      .justifyContent(FlexAlign.Center)
    }
    .height(SizeTokens.controlLarge)
    .width(108)
    .backgroundColor(this.state === 'sending' ? ColorTokens.httpDelete : ColorTokens.brand500)
    .borderRadius({ topRight: RadiusTokens.medium, bottomRight: RadiusTokens.medium })
    .stateStyles({
      normal: { .opacity(1) },
      pressed: { .opacity(0.82) }
    })
    .onClick(() => {
      if (this.state === 'sending') {
        this.onCancel();
      } else {
        this.onSend();
      }
    })
  }
}
