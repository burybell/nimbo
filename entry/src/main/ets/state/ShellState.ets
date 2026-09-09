import { CollectionNode, RequestTabModel } from '../models/ShellModels';
import { DEMO_COLLECTIONS, INITIAL_TABS } from '../mock/ShellMockData';

export class ShellState {
  static createInitialTabs(): RequestTabModel[] {
    return INITIAL_TABS.slice();
  }

  static createInitialCollections(): CollectionNode[] {
    return DEMO_COLLECTIONS.map((node: CollectionNode) => ShellState.cloneCollection(node));
  }

  private static cloneCollection(node: CollectionNode): CollectionNode {
    return {
      id: node.id,
      type: node.type,
      name: node.name,
      method: node.method,
      expanded: node.expanded,
      children: node.children.map((child: CollectionNode) => ShellState.cloneCollection(child))
    };
  }
}
