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
      const existing = merged[index];
      const variables = (existing.variables ?? []).map(item => item);
      (example.variables ?? []).forEach((variable) => {
        if (!variables.some(item => item.key === variable.key)) variables.push(variable);
      });
      if (example.id !== 'demo-api') {
        merged[index] = {
          id: existing.id, type: existing.type, name: existing.name, method: existing.method,
          expanded: existing.expanded, variables, children: existing.children
        };
        return;
      }
      const children = existing.children.map((node: CollectionNode) => ShellState.cloneCollection(node));
      example.children.forEach((child: CollectionNode) => {
        if (!children.some((node: CollectionNode) => node.id === child.id)) {
          children.push(ShellState.cloneCollection(child));
        }
      });
      merged[index] = {
        id: existing.id, type: existing.type, name: existing.name, method: existing.method,
        expanded: existing.expanded, variables, children
      };
    });
    return merged;
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
