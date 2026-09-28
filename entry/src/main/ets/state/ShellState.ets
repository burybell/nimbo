import { CollectionNode, RequestTabModel } from '../models/ShellModels';
import { DEMO_COLLECTIONS, INITIAL_TABS } from '../mock/ShellMockData';

export class ShellState {
  static createInitialTabs(): RequestTabModel[] {
    return INITIAL_TABS.slice();
  }

  static createInitialCollections(): CollectionNode[] {
    return DEMO_COLLECTIONS.map((node: CollectionNode) => ShellState.cloneCollection(node));
  }

  static mergeExampleCatalog(collections: CollectionNode[]): CollectionNode[] {
    const merged = collections.map((node: CollectionNode) => ShellState.cloneCollection(node));
    DEMO_COLLECTIONS.forEach((example: CollectionNode) => {
      const index = merged.findIndex((node: CollectionNode) => node.id === example.id);
      if (index < 0) {
        merged.push(ShellState.cloneCollection(example));
        return;
      }
      merged[index] = ShellState.mergeExampleNode(merged[index], example);
    });
    return merged;
  }

  private static mergeExampleNode(existing: CollectionNode, example: CollectionNode): CollectionNode {
    const variables = (existing.variables ?? []).map(item => item);
    (example.variables ?? []).forEach((variable) => {
      if (!variables.some(item => item.key === variable.key)) variables.push(variable);
    });
    const children = existing.children.map((node: CollectionNode) => ShellState.cloneCollection(node));
    example.children.forEach((child: CollectionNode) => {
      const index = children.findIndex((node: CollectionNode) => node.id === child.id);
      if (index < 0) children.push(ShellState.cloneCollection(child));
      else children[index] = ShellState.mergeExampleNode(children[index], child);
    });
    return {
      id: existing.id, type: existing.type, name: existing.name, method: existing.method,
      expanded: existing.expanded, variables, children
    };
  }

  private static cloneCollection(node: CollectionNode): CollectionNode {
    return {
      id: node.id,
      type: node.type,
      name: node.name,
      method: node.method,
      expanded: node.expanded,
      variables: node.variables ?? [],
      children: node.children.map((child: CollectionNode) => ShellState.cloneCollection(child))
    };
  }
}
