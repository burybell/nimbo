import { NavigationDestination, NavigationItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct MobileNavigation {
  @Prop activeDestination: NavigationDestination = 'workspace';
  onDestinationChange: (destination: NavigationDestination) => void = () => {};
  private items: NavigationItemModel[] = [
    { id: 'workspace', label: $r('app.string.nav_workspace'), icon: '⌂' },
    { id: 'collections', label: $r('app.string.nav_collections'), icon: '▣' },
    { id: 'environments', label: $r('app.string.nav_environments'), icon: '◎' },
    { id: 'history', label: $r('app.string.nav_history'), icon: '◷' },
    { id: 'settings', label: $r('app.string.nav_settings'), icon: '⚙' }
  ];

  build() {
    Row() {
      ForEach(this.items, (item: NavigationItemModel) => {
        Column({ space: SpacingTokens.x1 }) {
          Text(item.icon)
            .fontSize(17)
            .fontColor(item.id === this.activeDestination ? ColorTokens.brand500 : ColorTokens.textTertiary)
          Text(item.label)
            .fontSize(10)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(item.id === this.activeDestination ? ColorTokens.brand600 : ColorTokens.textSecondary)
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
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
