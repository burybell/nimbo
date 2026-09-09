import { CollectionNode } from '../../../models/ShellModels';
import { CollectionTree } from './CollectionTree';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct CollectionSidebar {
  @Prop widthValue: number = SizeTokens.collectionSidebarWidth;
  @Link nodes: CollectionNode[];
  onOpenRequest: (node: CollectionNode) => void = () => {};

  build() {
    Column() {
      Row() {
        Text('Collections')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.textPrimary)
        Blank()
        Text('+')
          .fontSize(19)
          .fontColor(ColorTokens.textSecondary)
          .width(SizeTokens.controlSmall)
          .height(SizeTokens.controlSmall)
          .textAlign(TextAlign.Center)
        Text('⋯')
          .fontSize(18)
          .fontColor(ColorTokens.textSecondary)
          .width(SizeTokens.controlSmall)
          .height(SizeTokens.controlSmall)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(SizeTokens.controlLarge)

      Row({ space: SpacingTokens.x2 }) {
        Text('⌕')
          .fontSize(16)
          .fontColor(ColorTokens.textTertiary)
        Text('Search requests…')
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
      }
      .width('100%')
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
      .backgroundColor(ColorTokens.bgApp)
      .borderRadius(RadiusTokens.medium)
      .margin({ bottom: SpacingTokens.x3 })

      Scroll() {
        CollectionTree({ nodes: $nodes, onOpenRequest: this.onOpenRequest })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
    }
    .width(this.widthValue)
    .height('100%')
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3, top: SpacingTokens.x2 })
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { left: 1, right: 1 }, color: ColorTokens.borderSubtle })
  }
}
