import { ContextMenuItemModel, HistoryGroup, HistoryItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { NimboContextMenu } from '../common/NimboContextMenu';

@Component
export struct HistoryPage {
  @Prop items: HistoryItemModel[] = [];
  @State activeGroup: HistoryGroup = 'Today';
  @State menuId: string = '';
  onOpen: (item: HistoryItemModel) => void = () => {};
  onCopy: (message: string) => void = () => {};
  onDelete: (id: string) => void = () => {};
  onClear: () => void = () => {};
  private groups: HistoryGroup[] = ['Today', 'Yesterday', 'Previous 7 Days', 'Older'];
  private menuItems: ContextMenuItemModel[] = [
    { id: 'open', label: 'Open request', icon: '↗', dangerous: false },
    { id: 'copy-url', label: 'Copy URL', icon: '⧉', dangerous: false },
    { id: 'copy-curl', label: 'Copy as cURL', icon: '⌘', dangerous: false },
    { id: 'delete', label: 'Delete', icon: '×', dangerous: true }
  ];

  private statusColor(status: number): string {
    if (status >= 200 && status < 300) return ColorTokens.statusSuccess;
    if (status >= 400 && status < 500) return ColorTokens.statusClientError;
    if (status >= 500) return ColorTokens.statusServerError;
    return ColorTokens.statusInfo;
  }

  private methodColor(method: string): string {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private handleMenu(action: string, item: HistoryItemModel): void {
    this.menuId = '';
    if (action === 'open') this.onOpen(item);
    if (action === 'copy-url') this.onCopy('Copied');
    if (action === 'copy-curl') this.onCopy('Copied');
    if (action === 'delete') this.onDelete(item.id);
  }

  build() {
    Row() {
      Column() {
        Text('History')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
          .width('100%')
          .height(48)
          .padding({ left: SpacingTokens.x3 })
        ForEach(this.groups, (group: HistoryGroup) => {
          Row() {
            Text(group)
              .fontSize(13)
              .fontColor(group === this.activeGroup ? ColorTokens.brand600 : ColorTokens.textSecondary)
            Blank()
            Text(`${this.items.filter((item: HistoryItemModel) => item.group === group).length}`)
              .fontSize(11)
              .fontColor(ColorTokens.textTertiary)
          }
          .width('100%')
          .height(40)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .backgroundColor(group === this.activeGroup ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
          .borderRadius(RadiusTokens.medium)
          .onClick(() => { this.activeGroup = group; })
        }, (group: HistoryGroup) => group)
        Blank()
        Button('Clear History')
          .width('100%')
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .backgroundColor(ColorTokens.bgSidebar)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium)
          .onClick(this.onClear)
      }
      .width(220)
      .height('100%')
      .padding(SpacingTokens.x2)
      .backgroundColor(ColorTokens.bgSidebar)
      .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

      Column() {
        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text(this.activeGroup)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text('Requests stay local to this device.')
              .fontSize(12)
              .fontColor(ColorTokens.textTertiary)
          }
          Blank()
          Text(`${this.items.filter((item: HistoryItemModel) => item.group === this.activeGroup).length} requests`)
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
        }
        .width('100%')
        .height(76)
        .padding({ left: SpacingTokens.x6, right: SpacingTokens.x6 })
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        Scroll() {
          Column() {
            ForEach(this.items.filter((item: HistoryItemModel) => item.group === this.activeGroup),
              (item: HistoryItemModel) => {
                Column() {
                  Row({ space: SpacingTokens.x4 }) {
                    Text(item.time).width(60).fontSize(12).fontColor(ColorTokens.textTertiary)
                    Text(item.method).width(58).fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(this.methodColor(item.method))
                    Text(item.url).layoutWeight(1).fontSize(13).fontColor(ColorTokens.textPrimary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item.status}`).width(42).fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(this.statusColor(item.status))
                    Text(item.duration).width(68).fontSize(12).fontColor(ColorTokens.textSecondary)
                    Text('⋯').width(32).height(32).textAlign(TextAlign.Center).fontSize(18)
                      .fontColor(ColorTokens.textSecondary)
                      .onClick(() => { this.menuId = this.menuId === item.id ? '' : item.id; })
                  }
                  .width('100%')
                  .height(52)
                  .padding({ left: SpacingTokens.x5, right: SpacingTokens.x3 })
                  .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
                  .onClick(() => this.onOpen(item))
                  if (this.menuId === item.id) {
                    Row() {
                      Blank()
                      NimboContextMenu({ items: this.menuItems, onSelect: (action: string) => this.handleMenu(action, item) })
                    }
                    .width('100%')
                    .padding({ right: SpacingTokens.x4, bottom: SpacingTokens.x2 })
                  }
                }
                .width('100%')
              }, (item: HistoryItemModel) => item.id)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(ColorTokens.bgWorkspace)
    }
    .width('100%')
    .height('100%')
  }
}
