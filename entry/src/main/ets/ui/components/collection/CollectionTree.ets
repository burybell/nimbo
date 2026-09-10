import { CollectionNode } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct CollectionTree {
  @Link nodes: CollectionNode[];
  @Prop alwaysShowActions: boolean = false;
  @State hoveredNodeId: string = '';
  onOpenRequest: (node: CollectionNode) => void = () => {};
  onToggleNode: (id: string) => void = () => {};
  onCreateFolder: (parentId: string) => void = () => {};
  onRenameRequest: (node: CollectionNode) => void = () => {};

  private methodColor(method: string): ResourceColor {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private nodeIndent(depth: number): number {
    return SpacingTokens.x2 + Math.min(depth, 5) * SpacingTokens.x8;
  }

  private treeKey(node: CollectionNode): string {
    let childrenKey = '';
    node.children.forEach((child: CollectionNode) => { childrenKey += `|${this.treeKey(child)}`; });
    return `${node.id}-${node.expanded}-${node.name}-${node.method}-${childrenKey}`;
  }

  private toggleNode(node: CollectionNode): void {
    if (node.type === 'request') {
      this.onOpenRequest(node);
      return;
    }
    this.onToggleNode(node.id);
  }

  @Builder
  treeNode(node: CollectionNode, depth: number) {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        if (node.type === 'request') {
          Text(node.method ?? 'GET')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.methodColor(node.method ?? 'GET'))
            .width(42)
        } else {
          Text('›')
            .fontSize(15)
            .fontColor(ColorTokens.textSecondary)
            .width(14)
            .rotate({ angle: node.expanded ? 90 : 0 })
            .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve })
          Text(node.type === 'collection' ? '▣' : '□')
            .fontSize(14)
            .fontColor(ColorTokens.textSecondary)
            .width(14)
        }
        Text(node.name)
          .fontSize(13)
          .fontWeight(node.type === 'collection' ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(ColorTokens.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        if (node.type === 'request') {
          Image($r('app.media.edit'))
            .width(14)
            .height(14)
            .objectFit(ImageFit.Contain)
            .padding(5)
            .width(SizeTokens.controlSmall)
            .height(SizeTokens.controlSmall)
            .borderRadius(RadiusTokens.small)
            .stateStyles({
              normal: { .backgroundColor(ColorTokens.bgSurfaceHover).opacity(0.82) },
              pressed: { .backgroundColor(ColorTokens.bgSurfaceActive).opacity(1) }
            })
            .onClick(() => this.onRenameRequest(node))
        }
        if (node.type !== 'request' && depth < 10 &&
          (this.alwaysShowActions || node.id === this.hoveredNodeId)) {
          Text('+')
            .fontSize(17)
            .fontColor(ColorTokens.brand600)
            .width(SizeTokens.controlSmall)
            .height(SizeTokens.controlSmall)
            .textAlign(TextAlign.Center)
            .borderRadius(RadiusTokens.small)
            .onClick(() => this.onCreateFolder(node.id))
        }
      }
      .width('100%')
      .height(SizeTokens.controlMedium)
      .padding({ left: this.nodeIndent(depth), right: SpacingTokens.x2 })
      .backgroundColor(node.id === this.hoveredNodeId ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface)
      .borderRadius(RadiusTokens.small)
      .onHover((hovered: boolean) => { this.hoveredNodeId = hovered ? node.id : ''; })
      .onClick(() => this.toggleNode(node))

      if (node.expanded) {
        ForEach(node.children, (child: CollectionNode) => {
          this.treeNode(child, depth + 1)
        }, (child: CollectionNode) => this.treeKey(child))
      }
    }
    .width('100%')
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -4 }))
      .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
  }

  build() {
    Column() {
      ForEach(this.nodes, (node: CollectionNode) => {
        this.treeNode(node, 0)
      }, (node: CollectionNode) => this.treeKey(node))
    }
    .width('100%')
  }
}
