import { CollectionNode } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct CollectionTree {
  @Link nodes: CollectionNode[];
  onOpenRequest: (node: CollectionNode) => void = () => {};

  private methodColor(method: string): string {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private toggleNode(node: CollectionNode): void {
    if (node.type === 'request') {
      this.onOpenRequest(node);
      return;
    }
    node.expanded = !node.expanded;
    this.nodes = [...this.nodes];
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
          Text(node.expanded ? '⌄' : '›')
            .fontSize(15)
            .fontColor(ColorTokens.textSecondary)
            .width(14)
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
        Text('⋯')
          .fontSize(16)
          .fontColor(ColorTokens.textTertiary)
          .visibility(node.type === 'request' ? Visibility.Visible : Visibility.Hidden)
      }
      .width('100%')
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x2 + depth * SpacingTokens.x3, right: SpacingTokens.x2 })
      .borderRadius(RadiusTokens.small)
      .onClick(() => this.toggleNode(node))

      if (node.expanded) {
        ForEach(node.children, (child: CollectionNode) => {
          this.treeNode(child, depth + 1)
        }, (child: CollectionNode) => child.id)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      ForEach(this.nodes, (node: CollectionNode) => {
        this.treeNode(node, 0)
      }, (node: CollectionNode) => node.id)
    }
    .width('100%')
  }
}

