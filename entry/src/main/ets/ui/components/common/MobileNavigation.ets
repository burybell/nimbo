import { NavigationDestination, NavigationItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct MobileNavigation {
  @Prop activeDestination: NavigationDestination = 'workspace';
  onDestinationChange: (destination: NavigationDestination) => void = () => {};
  private items: NavigationItemModel[] = [
    { id: 'workspace', label: $r('app.string.nav_workspace'),
      icon: $r('app.media.nav_workspace'), activeIcon: $r('app.media.nav_workspace_active') },
    { id: 'collections', label: $r('app.string.nav_collections'),
      icon: $r('app.media.nav_collections'), activeIcon: $r('app.media.nav_collections_active') },
    { id: 'environments', label: $r('app.string.nav_environments'),
      icon: $r('app.media.nav_environments'), activeIcon: $r('app.media.nav_environments_active') },
    { id: 'history', label: $r('app.string.nav_history'),
      icon: $r('app.media.nav_history'), activeIcon: $r('app.media.nav_history_active') },
    { id: 'settings', label: $r('app.string.nav_settings'),
      icon: $r('app.media.nav_settings'), activeIcon: $r('app.media.nav_settings_active') }
  ];

  build() {
    Row() {
      ForEach(this.items, (item: NavigationItemModel) => {
        Column({ space: SpacingTokens.x1 }) {
          Image(item.id === this.activeDestination ? item.activeIcon : item.icon)
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
          Text(item.label)
            .fontSize(10)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(item.id === this.activeDestination ? ColorTokens.brand600 : ColorTokens.textSecondary)
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
        .onClick(() => this.onDestinationChange(item.id))
      }, (item: NavigationItemModel) => item.id)
    }
    .width('100%')
    .height(56)
    .padding({ left: SpacingTokens.x1, right: SpacingTokens.x1 })
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { top: 1 }, color: ColorTokens.borderSubtle })
  }
}
