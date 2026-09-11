import { ResponseModel, ResponseTab } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { ResponseSummary } from './ResponseSummary';
import { ResponseTabs } from './ResponseTabs';

@Component
export struct ResponseHeader {
  @Prop response: ResponseModel;
  @Prop activeTab: ResponseTab = 'body';
  onTabChange: (tab: ResponseTab) => void = () => {};

  build() {
    Row() {
      ResponseTabs({
        activeTab: this.activeTab,
        headerCount: this.response.headers.length,
        cookieCount: this.response.cookies.length,
        scriptCount: this.response.scriptResults.length,
        testCount: this.response.testResults.length,
        onChange: this.onTabChange
      })
      .layoutWeight(1)
      if (this.response.status === 'sending') {
        Row({ space: SpacingTokens.x2 }) {
          LoadingProgress()
            .width(13)
            .height(13)
            .color(ColorTokens.brand500)
          Text($r('app.string.sending'))
            .fontSize(12)
            .fontColor(ColorTokens.brand600)
        }
      } else if (this.response.statusCode > 0) {
        ResponseSummary({
          statusCode: this.response.statusCode,
          statusText: this.response.statusText,
          duration: this.response.duration,
          responseSize: this.response.size,
          protocol: this.response.protocol
        })
      }
    }
    .width('100%')
    .height(39)
    .padding({ left: SpacingTokens.x1, right: SpacingTokens.x3 })
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
