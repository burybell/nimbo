import { RequestTabModel } from '../../../models/ShellModels';
import { RequestTabBar } from './RequestTabBar';
import { NimboEmptyState } from '../common/NimboEmptyState';
import { ColorTokens } from '../../tokens/ColorTokens';

@Component
export struct Workspace {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  onSelectTab: (id: string) => void = () => {};
  onCloseTab: (id: string) => void = () => {};
  onCreateTab: () => void = () => {};

  build() {
    Column() {
      RequestTabBar({
        tabs: $tabs,
        activeTabId: $activeTabId,
        onSelect: this.onSelectTab,
        onClose: this.onCloseTab,
        onCreate: this.onCreateTab
      })

      if (this.tabs.length === 0) {
        NimboEmptyState({
          title: 'What do you want to test?',
          description: 'Create a request to start a local API workspace.'
        })
          .layoutWeight(1)
      } else {
        NimboEmptyState({
          title: 'Request ready',
          description: 'Choose a collection request or create a new tab.'
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTokens.bgWorkspace)
  }
}
