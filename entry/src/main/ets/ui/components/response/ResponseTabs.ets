import { ResponseTab } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ResponseTabs {
  @Prop activeTab: ResponseTab = 'body';
  @Prop headerCount: number = 0;
  @Prop cookieCount: number = 0;
  onChange: (tab: ResponseTab) => void = () => {};

  @Builder
  private tabItem(tab: ResponseTab, label: ResourceStr, count: number = 0) {
    Row({ space: SpacingTokens.x1 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(this.activeTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeTab === tab ? ColorTokens.textPrimary : ColorTokens.textSecondary)
      if (count > 0) {
        Text(count.toString())
          .fontSize(10)
          .fontColor(ColorTokens.textTertiary)
      }
    }
    .height(38)
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
    .border({
      width: { bottom: this.activeTab === tab ? 2 : 0 },
      color: this.activeTab === tab ? ColorTokens.brand500 : ColorTokens.borderSubtle
    })
    .onClick(() => this.onChange(tab))
  }

  build() {
    Row() {
      this.tabItem('body', $r('app.string.tab_body'))
      this.tabItem('headers', $r('app.string.tab_headers'), this.headerCount)
      this.tabItem('cookies', $r('app.string.tab_cookies'), this.cookieCount)
      this.tabItem('timeline', $r('app.string.tab_timeline'))
    }
    .height(38)
  }
}
