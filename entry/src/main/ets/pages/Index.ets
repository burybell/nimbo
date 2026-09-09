import { NimboWindow } from '../app/NimboWindow';

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
