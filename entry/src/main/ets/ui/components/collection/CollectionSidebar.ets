import { CollectionNode } from '../../../models/ShellModels';
import { CollectionTree } from './CollectionTree';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct CollectionSidebar {
  @Prop widthValue: number = SizeTokens.collectionSidebarWidth;
  @Link nodes: CollectionNode[];
  @Prop dismissible: boolean = false;
  onOpenRequest: (node: CollectionNode) => void = () => {};
  onChange: () => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text($r('app.string.nav_collections'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary)
        Blank()
        if (this.dismissible) {
          Text('×')
            .fontSize(18)
            .fontColor(ColorTokens.textSecondary)
            .width(SizeTokens.controlSmall)
            .height(SizeTokens.controlSmall)
            .textAlign(TextAlign.Center)
            .stateStyles({
              normal: { .backgroundColor(ColorTokens.bgSurface) },
              pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) }
            })
            .onClick(this.onDismiss)
        }
      }
      .width('100%')
      .height(SizeTokens.controlLarge)

      if (this.nodes.length === 0) {
        Column({ space: SpacingTokens.x2 }) {
          Text('▣').fontSize(24).fontColor(ColorTokens.textTertiary)
          Text($r('app.string.collection_empty_title')).fontSize(13).fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Text($r('app.string.collection_empty_description')).fontSize(11).fontColor(ColorTokens.textTertiary)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      } else {
        Scroll() {
          CollectionTree({ nodes: $nodes, onOpenRequest: this.onOpenRequest, onChange: this.onChange })
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)
      }
    }
    .width(this.widthValue)
    .height('100%')
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: SpacingTokens.x2 })
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { left: 1, right: 1 }, color: ColorTokens.borderSubtle })
  }
}
