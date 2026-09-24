import { NavigationDestination, NavigationItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct PrimarySidebar {
  @Prop compact: boolean = false;
  @Prop activeDestination: NavigationDestination = 'collections';
  onDestinationChange: (destination: NavigationDestination) => void = () => {};
  onCreateRequest: () => void = () => {};
  @State hoveredItemId: string = '';

  private mainItems: NavigationItemModel[] = [
    { id: 'workspace', label: $r('app.string.nav_workspace'),
      icon: $r('app.media.nav_workspace'), activeIcon: $r('app.media.nav_workspace_active') },
    { id: 'collections', label: $r('app.string.nav_collections'),
      icon: $r('app.media.nav_collections'), activeIcon: $r('app.media.nav_collections_active') },
    { id: 'environments', label: $r('app.string.nav_environments'),
      icon: $r('app.media.nav_environments'), activeIcon: $r('app.media.nav_environments_active') },
    { id: 'history', label: $r('app.string.nav_history'),
      icon: $r('app.media.nav_history'), activeIcon: $r('app.media.nav_history_active') }
  ];

  @Builder
  navItem(item: NavigationItemModel) {
    Row({ space: SpacingTokens.x3 }) {
      Image(item.id === this.activeDestination ? item.activeIcon : item.icon)
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
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
    .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
    .onHover((hovered: boolean) => { this.hoveredItemId = hovered ? item.id : ''; })
    .onClick(() => this.onDestinationChange(item.id))
  }

  build() {
    Column() {
      if (this.compact) {
        Button() {
          Image($r('app.media.add_white'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
        }
          .width(SizeTokens.controlLarge)
          .height(SizeTokens.controlLarge)
          .backgroundColor(ColorTokens.brand500)
          .borderRadius(RadiusTokens.medium)
          .onClick(this.onCreateRequest)
      } else {
        Button() {
          Row({ space: SpacingTokens.x2 }) {
            Image($r('app.media.add_white'))
              .width(18)
              .height(18)
              .objectFit(ImageFit.Contain)
            Text($r('app.string.action_new'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textOnBrand)
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(SizeTokens.controlLarge)
        .backgroundColor(ColorTokens.brand500)
        .borderRadius(RadiusTokens.medium)
        .stateStyles({
          normal: { .backgroundColor(ColorTokens.brand500) },
          pressed: { .backgroundColor(ColorTokens.brand600) }
        })
        .onClick(this.onCreateRequest)
      }

      Column({ space: SpacingTokens.x1 }) {
        ForEach(this.mainItems, (item: NavigationItemModel) => {
          this.navItem(item)
        }, (item: NavigationItemModel) => item.id)
      }
      .width('100%')
      .margin({ top: SpacingTokens.x5 })

      Blank()
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
