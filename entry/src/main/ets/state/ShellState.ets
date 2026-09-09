import { CollectionNode, RequestTabModel } from '../models/ShellModels';
import { DEMO_COLLECTIONS, INITIAL_TABS } from '../mock/ShellMockData';

export class ShellState {
  static createInitialTabs(): RequestTabModel[] {
    return INITIAL_TABS.slice();
  }

  static createInitialCollections(): CollectionNode[] {
    return DEMO_COLLECTIONS;
  }
}
