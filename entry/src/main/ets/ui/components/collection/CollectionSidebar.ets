import { CollectionNode } from '../../../models/ShellModels';
import { CollectionTree } from './CollectionTree';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct CollectionSidebar {
  @Prop widthValue: number = SizeTokens.collectionSidebarWidth;
  @Link nodes: CollectionNode[];
  @Prop dismissible: boolean = false;
  onOpenRequest: (node: CollectionNode) => void = () => {};
  onToggleNode: (id: string) => void = () => {};
  onCreateCollection: () => void = () => {};
  onCreateFolder: (parentId: string) => void = () => {};
  onDismiss: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text($r('app.string.nav_collections'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary)
        Blank()
        Text('+')
          .fontSize(20)
          .fontColor(ColorTokens.brand600)
          .width(SizeTokens.controlSmall)
          .height(SizeTokens.controlSmall)
          .textAlign(TextAlign.Center)
          .borderRadius(RadiusTokens.small)
          .stateStyles({
            normal: { .backgroundColor(ColorTokens.bgSurface) },
            pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) }
          })
          .onClick(this.onCreateCollection)
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
          Button($r('app.string.collection_create'))
            .height(SizeTokens.controlMedium)
            .fontSize(12)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium)
            .onClick(this.onCreateCollection)
        }
        .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      } else {
        Scroll() {
          CollectionTree({
            nodes: $nodes,
            alwaysShowActions: this.dismissible,
            onOpenRequest: this.onOpenRequest,
            onToggleNode: this.onToggleNode,
            onCreateFolder: this.onCreateFolder
          })
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
