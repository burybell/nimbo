import { RequestTabModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct RequestTabBar {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  onSelect: (id: string) => void = () => {};
  onClose: (id: string) => void = () => {};
  onCreate: () => void = () => {};

  private methodColor(method: string): string {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  build() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: RequestTabModel) => {
            Row({ space: SpacingTokens.x2 }) {
              Text(tab.method)
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.methodColor(tab.method))
              Text(tab.name)
                .fontSize(12)
                .fontColor(ColorTokens.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              if (tab.dirty) {
                Text('●')
                  .fontSize(7)
                  .fontColor(ColorTokens.textSecondary)
              }
              Text('×')
                .fontSize(15)
                .fontColor(ColorTokens.textTertiary)
                .width(20)
                .height(20)
                .textAlign(TextAlign.Center)
                .onClick(() => this.onClose(tab.id))
            }
            .height(SizeTokens.requestTabBarHeight)
            .constraintSize({ minWidth: 148, maxWidth: 220 })
            .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
            .backgroundColor(tab.id === this.activeTabId ? ColorTokens.bgWorkspace : ColorTokens.bgApp)
            .border({
              width: { top: tab.id === this.activeTabId ? 2 : 0, right: 1 },
              color: tab.id === this.activeTabId ? ColorTokens.brand500 : ColorTokens.borderSubtle
            })
            .onClick(() => this.onSelect(tab.id))
          }, (tab: RequestTabModel) => tab.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      Text('+')
        .fontSize(20)
        .fontColor(ColorTokens.textSecondary)
        .width(SizeTokens.requestTabBarHeight)
        .height(SizeTokens.requestTabBarHeight)
        .textAlign(TextAlign.Center)
        .backgroundColor(ColorTokens.bgApp)
        .onClick(this.onCreate)

      Blank()
    }
    .width('100%')
    .height(SizeTokens.requestTabBarHeight)
    .backgroundColor(ColorTokens.bgApp)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
