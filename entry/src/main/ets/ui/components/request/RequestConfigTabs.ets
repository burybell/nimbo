import { RequestConfigTab } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct RequestConfigTabs {
  @Prop activeTab: RequestConfigTab = 'params';
  @Prop headerCount: number = 0;
  @Prop bodyHasContent: boolean = false;
  @Prop extractionCount: number = 0;
  onChange: (tab: RequestConfigTab) => void = () => {};

  @Builder
  private tabItem(tab: RequestConfigTab, label: ResourceStr, suffix: string = '') {
    Row({ space: SpacingTokens.x1 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(this.activeTab === tab ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.activeTab === tab ? ColorTokens.textPrimary : ColorTokens.textSecondary)
      if (suffix.length > 0) {
        Text(suffix)
          .fontSize(10)
          .fontColor(tab === 'body' ? ColorTokens.brand500 : ColorTokens.textSecondary)
          .padding(tab === 'headers' ? { left: 5, right: 5, top: 1, bottom: 1 } : 0)
          .backgroundColor(tab === 'headers' ? ColorTokens.bgSurfaceHover : ColorTokens.bgWorkspace)
          .borderRadius(8)
      }
    }
    .height(40)
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
    .border({
      width: { bottom: this.activeTab === tab ? 2 : 0 },
      color: this.activeTab === tab ? ColorTokens.brand500 : ColorTokens.borderSubtle
    })
    .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
    .onClick(() => {
      this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }, () => {
        this.onChange(tab);
      });
    })
  }

  build() {
    Row() {
      this.tabItem('params', $r('app.string.tab_params'))
      this.tabItem('headers', $r('app.string.tab_headers'), this.headerCount > 0 ? this.headerCount.toString() : '')
      this.tabItem('auth', $r('app.string.tab_auth'))
      this.tabItem('body', $r('app.string.tab_body'), this.bodyHasContent ? '●' : '')
      this.tabItem('extract', $r('app.string.tab_extract'),
        this.extractionCount > 0 ? this.extractionCount.toString() : '')
      this.tabItem('settings', $r('app.string.nav_settings'))
      Blank()
    }
    .width('100%')
    .height(41)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
