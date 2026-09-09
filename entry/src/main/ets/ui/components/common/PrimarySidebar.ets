import { NavigationDestination, NavigationItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { NimboButton } from './NimboButton';

@Component
export struct PrimarySidebar {
  @Prop compact: boolean = false;
  @Prop activeDestination: NavigationDestination = 'collections';
  onDestinationChange: (destination: NavigationDestination) => void = () => {};
  onCreateRequest: () => void = () => {};

  private mainItems: NavigationItemModel[] = [
    { id: 'workspace', label: 'Workspace', icon: '⌂' },
    { id: 'collections', label: 'Collections', icon: '▣' },
    { id: 'environments', label: 'Environments', icon: '◎' },
    { id: 'history', label: 'History', icon: '◷' }
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
    .backgroundColor(item.id === this.activeDestination ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
    .borderRadius(RadiusTokens.medium)
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
        NimboButton({ label: 'New', icon: '+', primary: true, onPress: this.onCreateRequest })
          .width('100%')
      }

      Column({ space: SpacingTokens.x1 }) {
        ForEach(this.mainItems, (item: NavigationItemModel) => {
          this.navItem(item)
        }, (item: NavigationItemModel) => item.id)
      }
      .width('100%')
      .margin({ top: SpacingTokens.x5 })

      Blank()

      this.navItem({ id: 'settings', label: 'Settings', icon: '⚙' })
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

