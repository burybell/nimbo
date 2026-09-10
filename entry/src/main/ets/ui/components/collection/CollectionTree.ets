import { CollectionNode, ContextMenuItemModel } from '../../../models/ShellModels';
import { NimboContextMenu } from '../common/NimboContextMenu';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct CollectionTree {
  @Link nodes: CollectionNode[];
  @Prop alwaysShowActions: boolean = false;
  @State hoveredNodeId: string = '';
  @State hoveredMenuNodeId: string = '';
  @State menuNodeId: string = '';
  @State menuOffsetX: number = SizeTokens.controlSmall / 2;
  @State menuOffsetY: number = -SizeTokens.controlSmall / 2;
  onOpenRequest: (node: CollectionNode) => void = () => {};
  onToggleNode: (id: string) => void = () => {};
  onCreateRequest: (parentId: string) => void = () => {};
  onCreateFolder: (parentId: string) => void = () => {};
  onRenameFolder: (node: CollectionNode) => void = () => {};
  onRenameRequest: (node: CollectionNode) => void = () => {};
  onDuplicateRequest: (node: CollectionNode) => void = () => {};
  onDeleteNode: (node: CollectionNode) => void = () => {};
  private folderMenuItems: ContextMenuItemModel[] = [
    { id: 'create-request', label: $r('app.string.search_new_request'), icon: '+', dangerous: false },
    { id: 'create-folder', label: $r('app.string.folder_create'), icon: '▱', dangerous: false },
    { id: 'rename', label: $r('app.string.action_rename'), icon: '✎', dangerous: false },
    { id: 'delete', label: $r('app.string.action_delete'), icon: '×', dangerous: true }
  ];
  private requestMenuItems: ContextMenuItemModel[] = [
    { id: 'rename', label: $r('app.string.request_rename'), icon: '✎', dangerous: false },
    { id: 'duplicate', label: $r('app.string.request_duplicate'), icon: '⧉', dangerous: false },
    { id: 'delete', label: $r('app.string.action_delete'), icon: '×', dangerous: true }
  ];

  private methodColor(method: string): ResourceColor {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private nodeIndent(depth: number): number {
    return SpacingTokens.x2 + Math.min(depth, 5) * SpacingTokens.x6;
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

  private findNode(nodes: CollectionNode[], id: string): CollectionNode | undefined {
    for (let index = 0; index < nodes.length; index += 1) {
      if (nodes[index].id === id) return nodes[index];
      const nested = this.findNode(nodes[index].children, id);
      if (nested) return nested;
    }
    return undefined;
  }

  private handleMenu(action: string): void {
    const node = this.findNode(this.nodes, this.menuNodeId);
    if (!node) return;
    this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
      this.menuNodeId = '';
    });
    if (action === 'create-request') this.onCreateRequest(node.id);
    if (action === 'create-folder') this.onCreateFolder(node.id);
    if (action === 'rename') {
      if (node.type === 'request') {
        this.onRenameRequest(node);
      } else {
        this.onRenameFolder(node);
      }
    }
    if (action === 'duplicate') this.onDuplicateRequest(node);
    if (action === 'delete') this.onDeleteNode(node);
  }

  @Builder
  private activeMenu() {
    if (this.menuNodeId.length > 0) {
      NimboContextMenu({
        items: this.findNode(this.nodes, this.menuNodeId)?.type === 'request' ?
          this.requestMenuItems : this.folderMenuItems,
        onSelect: (action: string) => this.handleMenu(action),
        onDismiss: () => {
          this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
            this.menuNodeId = '';
          });
        }
      })
    }
  }

  @Builder
  treeNode(node: CollectionNode, depth: number) {
    Column() {
      Row({ space: SpacingTokens.x1 }) {
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
          Image(node.expanded ? $r('app.media.folder_open') : $r('app.media.folder'))
            .width(16)
            .height(16)
            .objectFit(ImageFit.Contain)
        }
        Text(node.name)
          .fontSize(13)
          .fontWeight(node.type === 'collection' ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(ColorTokens.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('⋯')
            .fontSize(18)
            .fontColor(node.id === this.hoveredMenuNodeId || node.id === this.menuNodeId ?
              ColorTokens.brand500 : ColorTokens.textTertiary)
            .width(SizeTokens.controlSmall)
            .height(SizeTokens.controlSmall)
            .textAlign(TextAlign.Center)
            .stateStyles({
              normal: { .opacity(this.alwaysShowActions || node.id === this.hoveredNodeId ||
                node.id === this.menuNodeId ? 1 : 0.68) },
              pressed: { .fontColor(ColorTokens.brand600).opacity(1) }
            })
            .onHover((hovered: boolean) => { this.hoveredMenuNodeId = hovered ? node.id : ''; })
            .onMouse((event: MouseEvent) => {
              if (event.action === MouseAction.Press) {
                this.menuOffsetX = event.x;
                this.menuOffsetY = event.y - SizeTokens.controlSmall;
              }
            })
            .onClick(() => {
              this.menuNodeId = this.menuNodeId === node.id ? '' : node.id;
            })
            .bindPopup(this.menuNodeId === node.id, {
              builder: this.activeMenu,
              placement: Placement.BottomLeft,
              offset: { x: this.menuOffsetX, y: this.menuOffsetY },
              popupColor: Color.Transparent,
              enableArrow: false,
              autoCancel: true,
              targetSpace: 0,
              onStateChange: (event: PopupVisibilityEvent) => {
                if (!event.isVisible && this.menuNodeId === node.id) this.menuNodeId = '';
              }
            })
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
