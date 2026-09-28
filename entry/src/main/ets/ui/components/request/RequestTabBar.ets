import { ContextMenuItemModel, RequestTabModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';
import { NimboContextMenu } from '../common/NimboContextMenu';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct RequestTabBar {
  @Link tabs: RequestTabModel[];
  @Link activeTabId: string;
  onSelect: (id: string) => void = () => {};
  onClose: (id: string) => void = () => {};
  onCloseAll: () => void = () => {};
  onCreate: () => void = () => {};
  onRename: (id: string, name: string) => void = () => {};
  @State hoveredTabId: string = '';
  @State menuTabId: string = '';
  @State menuOffsetX: number = 0;
  @State menuOffsetY: number = 0;
  @State editingTabId: string = '';
  @State editingName: string = '';

  private beginRename(tab: RequestTabModel): void {
    this.editingTabId = tab.id;
    this.editingName = tab.name;
  }

  private commitRename(tab: RequestTabModel): void {
    if (this.editingTabId !== tab.id) return;
    const name = this.editingName.trim();
    this.editingTabId = '';
    this.editingName = '';
    if (name.length > 0 && name !== tab.name) this.onRename(tab.id, name);
  }

  private cancelRename(): void {
    this.editingTabId = '';
    this.editingName = '';
  }

  private menuItems(): ContextMenuItemModel[] {
    return [
      { id: 'close-current', label: $r('app.string.tab_menu_close_current'), icon: '×', dangerous: false },
      { id: 'close-all', label: $r('app.string.tab_menu_close_all'), icon: '⊗', dangerous: false },
      { id: 'new-request', label: $r('app.string.tab_menu_new_request'), icon: '+', dangerous: false }
    ];
  }

  private handleMenuAction(action: string): void {
    const tabId = this.menuTabId;
    this.menuTabId = '';
    if (action === 'close-current') {
      if (tabId.length > 0) this.onClose(tabId);
    } else if (action === 'close-all') {
      this.onCloseAll();
    } else if (action === 'new-request') {
      this.onCreate();
    }
  }

  @Builder
  private tabMenu() {
    NimboContextMenu({
      items: this.menuItems(),
      onSelect: (id: string) => this.handleMenuAction(id),
      onDismiss: () => { this.menuTabId = ''; }
    })
  }

  private methodColor(method: string): ResourceColor {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  build() {
    Row() {
      Scroll() {
        Row() {
          ForEach(this.tabs, (tab: RequestTabModel) => {
            Row({ space: SpacingTokens.x2 }) {
              Text(tab.request.protocol === 'websocket' ? 'WS' :
                (tab.request.protocol === 'sse' ? 'SSE' : tab.method))
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor(tab.request.protocol === 'http' || tab.request.protocol === undefined ?
                  this.methodColor(tab.method) : ColorTokens.brand600)
              if (this.editingTabId === tab.id) {
                TextInput({ text: this.editingName })
                  .id('nimboRequestTabRenameInput')
                  .layoutWeight(1)
                  .height(28)
                  .fontSize(12)
                  .fontColor(ColorTokens.textPrimary)
                  .backgroundColor(Color.Transparent)
                  .padding(0)
                  .defaultFocus(true)
                  .selectAll(true)
                  .enterKeyType(EnterKeyType.Done)
                  .onChange((value: string) => { this.editingName = value; })
                  .onSubmit(() => this.commitRename(tab))
                  .onBlur(() => this.commitRename(tab))
                  .onAppear(() => {
                    setTimeout(() => focusControl.requestFocus('nimboRequestTabRenameInput'), 20);
                  })
                  .onKeyEvent((event: KeyEvent) => {
                    if (event.type === KeyType.Down && event.keyCode === 2070) {
                      this.cancelRename();
                      return true;
                    }
                    return false;
                  })
              } else {
                Text(tab.name)
                  .fontSize(12)
                  .fontColor(ColorTokens.textPrimary)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .gesture(TapGesture({ count: 2 }).onAction(() => this.beginRename(tab)))
              }
              if (tab.dirty) {
                Text('●')
                  .fontSize(7)
                  .fontColor(ColorTokens.textSecondary)
              }
              Text('×')
                .fontSize(15)
                .fontColor(ColorTokens.textTertiary)
                .width(20)
                .height(20)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
                    this.onClose(tab.id);
                  });
                })
            }
            .height(SizeTokens.requestTabBarHeight)
            .width(192)
            .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
            .backgroundColor(tab.id === this.activeTabId ? ColorTokens.bgWorkspace :
              (tab.id === this.hoveredTabId ? ColorTokens.bgSurfaceHover : ColorTokens.bgApp))
            .border({
              width: { top: tab.id === this.activeTabId ? 2 : 0, right: 1 },
              color: tab.id === this.activeTabId ? ColorTokens.brand500 : ColorTokens.borderSubtle
            })
            .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
            .transition(TransitionEffect.OPACITY
              .combine(TransitionEffect.scale({ x: 0.94, y: 1, centerX: '0%', centerY: '50%' }))
              .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
            .onHover((hovered: boolean) => { this.hoveredTabId = hovered ? tab.id : ''; })
            .onMouse((event: MouseEvent) => {
              if (event.action === MouseAction.Press && event.button === MouseButton.Right) {
                this.menuOffsetX = event.x;
                this.menuOffsetY = event.y - SizeTokens.requestTabBarHeight;
                this.menuTabId = tab.id;
              }
            })
            .onClick(() => {
              this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }, () => {
                this.onSelect(tab.id);
              });
            })
            .bindPopup(this.menuTabId === tab.id, {
              builder: this.tabMenu,
              placement: Placement.BottomLeft,
              offset: { x: this.menuOffsetX, y: this.menuOffsetY },
              popupColor: Color.Transparent,
              enableArrow: false,
              autoCancel: true,
              targetSpace: 0,
              onStateChange: (event: PopupVisibilityEvent) => {
                if (!event.isVisible && this.menuTabId === tab.id) this.menuTabId = '';
              }
            })
          }, (tab: RequestTabModel) => `${tab.id}-${tab.name}-${tab.method}-${tab.dirty}`)
        }
        .justifyContent(FlexAlign.Start)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .layoutWeight(1)

      Text('+')
        .fontSize(20)
        .fontColor(ColorTokens.textSecondary)
        .width(SizeTokens.requestTabBarHeight)
        .height(SizeTokens.requestTabBarHeight)
        .textAlign(TextAlign.Center)
        .backgroundColor(ColorTokens.bgApp)
        .stateStyles({
          normal: { .backgroundColor(ColorTokens.bgApp) },
          pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) }
        })
        .onClick(() => {
          this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
            this.onCreate();
          });
        })

      Blank()
    }
    .width('100%')
    .height(SizeTokens.requestTabBarHeight)
    .backgroundColor(ColorTokens.bgApp)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
