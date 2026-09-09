export type NavigationDestination = 'workspace' | 'collections' | 'environments' | 'history' | 'settings';
export type CollectionNodeType = 'collection' | 'folder' | 'request';

export interface NavigationItemModel {
  id: NavigationDestination;
  label: string;
  icon: string;
}

export interface CollectionNode {
  id: string;
  type: CollectionNodeType;
  name: string;
  method?: string;
  expanded: boolean;
  children: CollectionNode[];
}

export interface RequestTabModel {
  id: string;
  name: string;
  method: string;
  dirty: boolean;
  pinned: boolean;
  loading: boolean;
}

