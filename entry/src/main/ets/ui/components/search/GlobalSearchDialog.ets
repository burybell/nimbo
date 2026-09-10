import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

export interface GlobalSearchItem {
  id: string;
  title: ResourceStr;
  subtitle: ResourceStr;
  keywords: string;
  icon: string;
}

@Component
export struct GlobalSearchDialog {
  @Prop items: GlobalSearchItem[] = [];
  @State query: string = '';
  onCancel: () => void = () => {};
  onSelect: (item: GlobalSearchItem) => void = () => {};

  aboutToAppear(): void {
    setTimeout(() => {
      focusControl.requestFocus('nimboGlobalSearchInput');
    }, 50);
  }

  private filteredItems(): GlobalSearchItem[] {
    const query = this.query.trim().toLowerCase();
    if (query.length === 0) return this.items.slice(0, 12);
    return this.items.filter((item: GlobalSearchItem) => item.keywords.toLowerCase().includes(query)).slice(0, 20);
  }

  private submitFirst(): void {
    const items = this.filteredItems();
    if (items.length > 0) this.onSelect(items[0]);
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim)
        .onClick(this.onCancel)

      Column() {
        Row({ space: SpacingTokens.x3 }) {
          Text('⌕').fontSize(20).fontColor(ColorTokens.textTertiary)
          TextInput({ text: this.query, placeholder: $r('app.string.global_search_placeholder') })
            .id('nimboGlobalSearchInput')
            .layoutWeight(1)
            .height(SizeTokens.controlLarge)
            .fontSize(15)
            .fontColor(ColorTokens.textPrimary)
            .backgroundColor(Color.Transparent)
            .defaultFocus(true)
            .onChange((value: string) => { this.query = value; })
            .onSubmit(() => this.submitFirst())
          Text('ESC').fontSize(10).fontColor(ColorTokens.textTertiary)
            .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 3, bottom: 3 })
            .backgroundColor(ColorTokens.bgWorkspace).borderRadius(RadiusTokens.small)
        }
        .width('100%').height(58).padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        if (this.filteredItems().length === 0) {
          Column({ space: SpacingTokens.x2 }) {
            Text('⌕').fontSize(26).fontColor(ColorTokens.textTertiary)
            Text($r('app.string.global_search_empty')).fontSize(13).fontColor(ColorTokens.textSecondary)
          }.width('100%').height(150).justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: SpacingTokens.x1 }) {
              ForEach(this.filteredItems(), (item: GlobalSearchItem, index: number) => {
                Row({ space: SpacingTokens.x3 }) {
                  Text(item.icon).fontSize(16)
                    .fontColor(index === 0 ? ColorTokens.brand500 : ColorTokens.textTertiary)
                    .width(24).textAlign(TextAlign.Center)
                  Column({ space: 2 }) {
                    Text(item.title).fontSize(13).fontWeight(FontWeight.Medium)
                      .fontColor(ColorTokens.textPrimary).width('100%').maxLines(1)
                    Text(item.subtitle).fontSize(11).fontColor(ColorTokens.textTertiary)
                      .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.layoutWeight(1)
                  if (index === 0) {
                    Text('↵').fontSize(12).fontColor(ColorTokens.textTertiary)
                  }
                }
                .width('100%').height(52).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
                .backgroundColor(index === 0 ? ColorTokens.bgSurfaceActive : Color.Transparent)
                .borderRadius(RadiusTokens.medium)
                .stateStyles({ normal: {}, pressed: { .backgroundColor(ColorTokens.bgSurfaceHover) } })
                .onClick(() => this.onSelect(item))
              }, (item: GlobalSearchItem) => item.id)
            }.width('100%').padding(SpacingTokens.x2)
          }.width('100%').constraintSize({ maxHeight: 430 })
        }
      }
      .width('90%').constraintSize({ maxWidth: 620 }).margin({ top: 88 })
      .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.large)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .shadow({ radius: 24, color: ColorTokens.shadowDefault, offsetY: 10 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -8 }))
        .combine(TransitionEffect.scale({ x: 0.98, y: 0.98 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down && event.keyText.toLowerCase() === 'escape') {
        this.onCancel();
        return true;
      }
      return false;
    })
  }
}
