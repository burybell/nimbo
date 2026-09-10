import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct MultipartTypeSelector {
  @Prop value: 'text' | 'file' = 'text';
  @State menuOpen: boolean = false;
  @State hoveredValue: string = '';
  onChange: (value: 'text' | 'file') => void = () => {};

  private select(value: 'text' | 'file'): void {
    this.menuOpen = false;
    this.onChange(value);
  }

  @Builder
  private menu() {
    Column({ space: 2 }) {
      this.menuItem('text', $r('app.string.type_text'))
      this.menuItem('file', $r('app.string.type_file'))
    }
    .width(116)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.medium)
    .shadow({ radius: 10, color: ColorTokens.shadowDefault, offsetY: 3 })
  }

  @Builder
  private menuItem(value: 'text' | 'file', label: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor(ColorTokens.textPrimary)
        .layoutWeight(1)
      if (this.value === value) {
        Text('✓')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTokens.brand600)
      }
    }
    .width('100%')
    .height(32)
    .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
    .backgroundColor(this.value === value ? ColorTokens.bgSurfaceActive :
      (this.hoveredValue === value ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface))
    .borderRadius(RadiusTokens.small)
    .onHover((hovered: boolean) => { this.hoveredValue = hovered ? value : ''; })
    .onClick(() => this.select(value))
  }

  build() {
    Row({ space: SpacingTokens.x1 }) {
      Text(this.value === 'file' ? $r('app.string.type_file') : $r('app.string.type_text'))
        .fontSize(12)
        .fontColor(ColorTokens.textSecondary)
        .layoutWeight(1)
        .maxLines(1)
      Text(this.menuOpen ? '⌃' : '⌄')
        .fontSize(10)
        .fontColor(ColorTokens.textTertiary)
    }
    .width(92)
    .height(28)
    .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
    .backgroundColor(this.menuOpen ? ColorTokens.bgSurfaceActive : ColorTokens.bgWorkspace)
    .border({ width: 1, color: this.menuOpen ? ColorTokens.borderFocus : ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.small)
    .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
    .onClick(() => { this.menuOpen = !this.menuOpen; })
    .bindPopup(this.menuOpen, {
      builder: this.menu,
      placement: Placement.BottomLeft,
      popupColor: Color.Transparent,
      enableArrow: false,
      autoCancel: true,
      targetSpace: SpacingTokens.x1,
      onStateChange: (event: PopupVisibilityEvent) => {
        if (!event.isVisible) this.menuOpen = false;
      }
    })
  }
}
