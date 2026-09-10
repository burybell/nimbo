import { NimboWindow } from '../app/NimboWindow';

PersistentStorage.persistProp('workspace.splitRatio', 0.48);
PersistentStorage.persistProp('collection.sidebarWidth', 260);
PersistentStorage.persistProp('nimbo.localData', '');

@Entry
@Component
struct Index {
  build() {
    Column() {
      NimboWindow()
    }
    .width('100%')
    .height('100%')
  }
}
