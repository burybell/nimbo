import { ContextMenuItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct NimboContextMenu {
  @Prop items: ContextMenuItemModel[] = [];
  @State hoveredItemId: string = '';
  onSelect: (id: string) => void = () => {};

  build() {
    Column() {
      ForEach(this.items, (item: ContextMenuItemModel, index: number) => {
        if (item.dangerous && index > 0) {
          Divider().color(ColorTokens.borderSubtle).margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x1 })
        }
        Row({ space: SpacingTokens.x3 }) {
          Text(item.icon)
            .width(18)
            .fontSize(14)
            .fontColor(item.dangerous ? ColorTokens.httpDelete : ColorTokens.textSecondary)
            .textAlign(TextAlign.Center)
          Text(item.label)
            .fontSize(13)
            .fontColor(item.dangerous ? ColorTokens.httpDelete : ColorTokens.textPrimary)
        }
        .width('100%')
        .height(34)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x4 })
        .backgroundColor(item.id === this.hoveredItemId ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface)
        .borderRadius(RadiusTokens.medium)
        .onHover((hovered: boolean) => { this.hoveredItemId = hovered ? item.id : ''; })
        .onClick(() => this.onSelect(item.id))
      }, (item: ContextMenuItemModel) => item.id)
    }
    .width(184)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
  }
}
