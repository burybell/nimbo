import { ContextMenuItemModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct NimboContextMenu {
  @Prop items: ContextMenuItemModel[] = [];
  @Prop accentIcons: boolean = false;
  @Prop widthValue: number = 184;
  @State hoveredItemId: string = '';
  onSelect: (id: string) => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    Column() {
      ForEach(this.items, (item: ContextMenuItemModel, index: number) => {
        if (item.dangerous && index > 0) {
          Divider().color(ColorTokens.borderSubtle).margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x1 })
        }
        Row({ space: SpacingTokens.x3 }) {
          Text(item.icon)
            .width(this.accentIcons ? 24 : 18)
            .height(this.accentIcons ? 24 : 18)
            .fontSize(this.accentIcons ? 11 : 14)
            .fontWeight(this.accentIcons ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(item.dangerous ? ColorTokens.httpDelete :
              (this.accentIcons ? ColorTokens.brand600 : ColorTokens.textSecondary))
            .textAlign(TextAlign.Center)
            .backgroundColor(this.accentIcons ? ColorTokens.brand50 : ColorTokens.bgSurface)
            .borderRadius(RadiusTokens.small)
          Text(item.label)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(item.dangerous ? ColorTokens.httpDelete : ColorTokens.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
    .width(this.widthValue)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
    .transition(TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ y: -4 }))
      .combine(TransitionEffect.scale({ x: 0.96, y: 0.96, centerX: '0%', centerY: '0%' }))
      .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
    .onHover((hovered: boolean) => {
      if (!hovered) this.onDismiss();
    })
  }
}
