import { ContextMenuItemModel, HistoryGroup, HistoryItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { NimboContextMenu } from '../common/NimboContextMenu';

@Component
export struct HistoryPage {
  @Prop items: HistoryItemModel[] = [];
  @Prop phone: boolean = false;
  @State activeGroup: HistoryGroup = 'Today';
  @State menuId: string = '';
  onOpen: (item: HistoryItemModel) => void = () => {};
  onCopy: (item: HistoryItemModel, asCurl: boolean) => void = () => {};
  onDelete: (id: string) => void = () => {};
  onClear: () => void = () => {};
  private groups: HistoryGroup[] = ['Today', 'Yesterday', 'Previous 7 Days', 'Older'];
  private menuItems: ContextMenuItemModel[] = [
    { id: 'open', label: $r('app.string.history_open_request'), icon: '↗', dangerous: false },
    { id: 'copy-url', label: $r('app.string.history_copy_url'), icon: '⧉', dangerous: false },
    { id: 'copy-curl', label: $r('app.string.history_copy_curl'), icon: '⌘', dangerous: false },
    { id: 'delete', label: $r('app.string.action_delete'), icon: '×', dangerous: true }
  ];

  private groupLabel(group: HistoryGroup): ResourceStr {
    if (group === 'Today') return $r('app.string.history_today');
    if (group === 'Yesterday') return $r('app.string.history_yesterday');
    if (group === 'Previous 7 Days') return $r('app.string.history_previous_days');
    return $r('app.string.history_older');
  }

  private statusColor(status: number): ResourceColor {
    if (status >= 200 && status < 300) return ColorTokens.statusSuccess;
    if (status >= 400 && status < 500) return ColorTokens.statusClientError;
    if (status >= 500) return ColorTokens.statusServerError;
    return ColorTokens.statusInfo;
  }

  private methodColor(method: string): ResourceColor {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private handleMenu(action: string, item: HistoryItemModel): void {
    this.menuId = '';
    if (action === 'open') this.onOpen(item);
    if (action === 'copy-url') this.onCopy(item, false);
    if (action === 'copy-curl') this.onCopy(item, true);
    if (action === 'delete') this.onDelete(item.id);
  }

  build() {
    if (this.phone) {
      Column() {
        Scroll() {
          Row({ space: SpacingTokens.x2 }) {
            ForEach(this.groups, (group: HistoryGroup) => {
              Text(this.groupLabel(group))
                .fontSize(12)
                .fontColor(group === this.activeGroup ? ColorTokens.brand600 : ColorTokens.textSecondary)
                .height(40)
                .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
                .backgroundColor(group === this.activeGroup ? ColorTokens.bgSurfaceActive : ColorTokens.bgSurface)
                .borderRadius(RadiusTokens.medium)
                .onClick(() => { this.activeGroup = group; })
            }, (group: HistoryGroup) => group)
          }
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        }
        .width('100%').height(56).scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .backgroundColor(ColorTokens.bgSidebar)

        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text(this.groupLabel(this.activeGroup)).fontSize(18).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text($r('app.string.history_local_hint')).fontSize(11).fontColor(ColorTokens.textTertiary)
          }
          Blank()
          Button($r('app.string.action_clear_history')).fontSize(11).fontColor(ColorTokens.httpDelete)
            .backgroundColor(ColorTokens.bgSurface).border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.medium).onClick(this.onClear)
        }
        .width('100%').height(68).padding({ left: SpacingTokens.x4, right: SpacingTokens.x3 })
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        Scroll() {
          Column() {
            ForEach(this.items.filter((item: HistoryItemModel) => item.group === this.activeGroup),
              (item: HistoryItemModel) => {
                Column({ space: SpacingTokens.x2 }) {
                  Row({ space: SpacingTokens.x3 }) {
                    Text(item.method).fontSize(11).fontWeight(FontWeight.Medium)
                      .fontColor(this.methodColor(item.method))
                    Text(item.url).layoutWeight(1).fontSize(13).fontColor(ColorTokens.textPrimary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item.status}`).fontSize(12).fontWeight(FontWeight.Medium)
                      .fontColor(this.statusColor(item.status))
                  }
                  .width('100%')
                  Row() {
                    Text(item.time).fontSize(11).fontColor(ColorTokens.textTertiary)
                    Blank()
                    Text(item.duration).fontSize(11).fontColor(ColorTokens.textSecondary)
                  }
                  .width('100%')
                }
                .width('100%').height(64).padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
                .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
                .onClick(() => this.onOpen(item))
              }, (item: HistoryItemModel) => item.id)
          }
          .width('100%')
        }
        .layoutWeight(1).width('100%')
      }
      .width('100%').height('100%').backgroundColor(ColorTokens.bgWorkspace)
    } else {
    Row() {
      Column() {
        Text($r('app.string.nav_history'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
          .width('100%')
          .height(48)
          .padding({ left: SpacingTokens.x3 })
        ForEach(this.groups, (group: HistoryGroup) => {
          Row() {
            Text(this.groupLabel(group))
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
        Button($r('app.string.action_clear_history'))
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
            Text(this.groupLabel(this.activeGroup))
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text($r('app.string.history_local_hint'))
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
}
