import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct WebSocketSchemeSelector {
  @Prop value: 'WS' | 'WSS' = 'WSS';
  @State menuOpen: boolean = false;
  @State hoveredValue: string = '';
  onChange: (value: 'WS' | 'WSS') => void = () => {};
  private values: Array<'WS' | 'WSS'> = ['WS', 'WSS'];

  @Builder
  private menu() {
    Column() {
      ForEach(this.values, (value: 'WS' | 'WSS') => {
        Row() {
          Text(value).fontSize(12).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
            .layoutWeight(1).textAlign(TextAlign.Start)
          if (value === this.value) {
            Text('✓').fontSize(12).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
          }
        }
        .width('100%').height(34).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        .backgroundColor(value === this.value ? ColorTokens.bgSurfaceActive :
          (value === this.hoveredValue ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface))
        .borderRadius(RadiusTokens.small)
        .onHover((hovered: boolean) => { this.hoveredValue = hovered ? value : ''; })
        .onClick(() => {
          this.menuOpen = false;
          this.onChange(value);
        })
      }, (value: string) => value)
    }
    .width(112).padding(SpacingTokens.x1).backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
  }

  build() {
    Button() {
      Row({ space: SpacingTokens.x2 }) {
        Text(this.value).fontSize(13).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
          .layoutWeight(1).textAlign(TextAlign.Start)
        Image($r('app.media.chevron_muted')).width(14).height(14).objectFit(ImageFit.Contain)
          .rotate({ angle: this.menuOpen ? 180 : 0 })
          .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
      }.width('100%')
    }
    .height(SizeTokens.controlLarge).width(104).padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
    .backgroundColor(this.menuOpen ? ColorTokens.bgSurfaceActive : Color.Transparent)
    .borderRadius(0).border({ width: { right: 1 }, color: ColorTokens.borderSubtle })
    .onClick(() => { this.menuOpen = !this.menuOpen; })
    .bindPopup(this.menuOpen, {
      builder: this.menu, placement: Placement.BottomLeft, popupColor: Color.Transparent,
      enableArrow: false, autoCancel: true, targetSpace: SpacingTokens.x1,
      onStateChange: (event: PopupVisibilityEvent) => { if (!event.isVisible) this.menuOpen = false; }
    })
  }
}
