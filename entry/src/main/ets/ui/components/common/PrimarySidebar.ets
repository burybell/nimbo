import { ContextMenuItemModel, NavigationDestination, NavigationItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { NimboButton } from './NimboButton';
import { NimboContextMenu } from './NimboContextMenu';

@Component
export struct PrimarySidebar {
  @Prop compact: boolean = false;
  @Prop activeDestination: NavigationDestination = 'collections';
  onDestinationChange: (destination: NavigationDestination) => void = () => {};
  onCreateRequest: () => void = () => {};
  onImportCurl: () => void = () => {};
  onImportPostman: () => void = () => {};
  @State importMenuOpen: boolean = false;
  @State hoveredItemId: string = '';
  private importItems: ContextMenuItemModel[] = [
    { id: 'curl', label: $r('app.string.import_curl'), icon: '>_', dangerous: false },
    { id: 'postman', label: $r('app.string.import_postman'), icon: 'P', dangerous: false }
  ];

  private handleImport(action: string): void {
    this.importMenuOpen = false;
    if (action === 'curl') this.onImportCurl();
    if (action === 'postman') this.onImportPostman();
  }

  private mainItems: NavigationItemModel[] = [
    { id: 'workspace', label: $r('app.string.nav_workspace'), icon: '⌂' },
    { id: 'collections', label: $r('app.string.nav_collections'), icon: '▣' },
    { id: 'environments', label: $r('app.string.nav_environments'), icon: '◎' },
    { id: 'history', label: $r('app.string.nav_history'), icon: '◷' }
  ];

  @Builder
  navItem(item: NavigationItemModel) {
    Row({ space: SpacingTokens.x3 }) {
      Text(item.icon)
        .fontSize(17)
        .fontColor(item.id === this.activeDestination ? ColorTokens.brand500 : ColorTokens.textSecondary)
        .width(20)
        .textAlign(TextAlign.Center)
      if (!this.compact) {
        Text(item.label)
          .fontSize(13)
          .fontWeight(item.id === this.activeDestination ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(item.id === this.activeDestination ? ColorTokens.brand600 : ColorTokens.textSecondary)
      }
    }
    .width('100%')
    .height(SizeTokens.controlLarge)
    .padding({ left: this.compact ? SpacingTokens.x2 : SpacingTokens.x3 })
    .justifyContent(this.compact ? FlexAlign.Center : FlexAlign.Start)
    .backgroundColor(item.id === this.activeDestination ? ColorTokens.bgSurfaceActive :
      (item.id === this.hoveredItemId ? ColorTokens.bgSurfaceHover : ColorTokens.bgSidebar))
    .borderRadius(RadiusTokens.medium)
    .onHover((hovered: boolean) => { this.hoveredItemId = hovered ? item.id : ''; })
    .onClick(() => this.onDestinationChange(item.id))
  }

  build() {
    Column() {
      if (this.compact) {
        Button('+')
          .width(SizeTokens.controlLarge)
          .height(SizeTokens.controlLarge)
          .fontSize(20)
          .fontColor(ColorTokens.textOnBrand)
          .backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.medium)
          .onClick(this.onCreateRequest)
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Row({ space: SpacingTokens.x1 }) {
            NimboButton({ label: $r('app.string.action_new'), icon: '+', primary: true,
              onPress: this.onCreateRequest })
              .layoutWeight(1)
            Button() {
              Image($r('app.media.chevron_down'))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
            }
              .width(34)
              .height(SizeTokens.controlLarge)
              .backgroundColor(ColorTokens.brand500)
              .borderRadius(RadiusTokens.medium)
              .stateStyles({
                normal: { .opacity(1) },
                pressed: { .opacity(0.82) }
              })
              .onClick(() => { this.importMenuOpen = !this.importMenuOpen; })
          }
          .width('100%')

          if (this.importMenuOpen) {
            NimboContextMenu({ items: this.importItems, accentIcons: true,
              onSelect: (action: string) => this.handleImport(action) })
              .position({ x: 0, y: SizeTokens.controlLarge + SpacingTokens.x2 })
              .zIndex(10)
          }
        }
        .width('100%')
        .height(SizeTokens.controlLarge)
        .clip(false)
        .zIndex(10)
      }

      Column({ space: SpacingTokens.x1 }) {
        ForEach(this.mainItems, (item: NavigationItemModel) => {
          this.navItem(item)
        }, (item: NavigationItemModel) => item.id)
      }
      .width('100%')
      .margin({ top: SpacingTokens.x5 })

      Blank()

      this.navItem({ id: 'settings', label: $r('app.string.nav_settings'), icon: '⚙' })
    }
    .width(this.compact ? SizeTokens.primarySidebarCompactWidth : SizeTokens.primarySidebarWidth)
    .height('100%')
    .padding({
      left: this.compact ? SpacingTokens.x2 : SpacingTokens.x3,
      right: this.compact ? SpacingTokens.x2 : SpacingTokens.x3,
      top: SpacingTokens.x3,
      bottom: SpacingTokens.x3
    })
    .backgroundColor(ColorTokens.bgSidebar)
  }
}
