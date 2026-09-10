import { HttpMethod } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct MethodSelector {
  @Prop value: HttpMethod = 'GET';
  @Prop fluid: boolean = false;
  @Prop embedded: boolean = false;
  @State menuOpen: boolean = false;
  @State hoveredMethod: string = '';
  onChange: (value: HttpMethod) => void = () => {};
  private methods: HttpMethod[] = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

  private methodColor(method: HttpMethod): ResourceColor {
    if (method === 'GET') return ColorTokens.httpGet;
    if (method === 'POST') return ColorTokens.httpPost;
    if (method === 'PUT') return ColorTokens.httpPut;
    if (method === 'PATCH') return ColorTokens.httpPatch;
    if (method === 'DELETE') return ColorTokens.httpDelete;
    return ColorTokens.httpOther;
  }

  private select(method: HttpMethod): void {
    this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.exitCurve }, () => {
      this.menuOpen = false;
    });
    this.onChange(method);
  }

  @Builder
  private menu() {
    Column() {
      ForEach(this.methods, (method: HttpMethod) => {
        Row() {
          Text(method)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.methodColor(method))
            .layoutWeight(1)
            .textAlign(TextAlign.Start)
          if (method === this.value) {
            Text('✓')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.methodColor(method))
          }
        }
        .width('100%')
        .height(34)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        .backgroundColor(method === this.value ? ColorTokens.bgSurfaceActive :
          (method === this.hoveredMethod ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface))
        .borderRadius(RadiusTokens.small)
        .onHover((hovered: boolean) => { this.hoveredMethod = hovered ? method : ''; })
        .onClick(() => this.select(method))
      }, (method: HttpMethod) => method)
    }
    .width(132)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.large)
    .shadow({ radius: 12, color: ColorTokens.shadowDefault, offsetY: 4 })
    .transition(TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ y: -4 }))
      .combine(TransitionEffect.scale({ x: 0.96, y: 0.96, centerX: '0%', centerY: '0%' }))
      .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }))
  }

  build() {
    Button() {
      Row({ space: SpacingTokens.x2 }) {
        Text(this.value)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.methodColor(this.value))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        Image($r('app.media.chevron_muted'))
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
          .rotate({ angle: this.menuOpen ? 180 : 0 })
          .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
      }
      .width('100%')
    }
    .height(SizeTokens.controlLarge)
    .width(this.fluid ? '100%' : 104)
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
    .backgroundColor(this.menuOpen ? ColorTokens.bgSurfaceActive :
      (this.embedded ? Color.Transparent : ColorTokens.bgSurface))
    .borderRadius(this.embedded ? 0 : { topLeft: RadiusTokens.medium, bottomLeft: RadiusTokens.medium })
    .border({ width: this.embedded ? { right: 1 } : 1,
      color: this.menuOpen ? ColorTokens.borderFocus :
        (this.embedded ? ColorTokens.borderSubtle : ColorTokens.borderDefault) })
    .stateStyles({
      normal: { .backgroundColor(this.menuOpen ? ColorTokens.bgSurfaceActive : ColorTokens.bgSurface) },
      pressed: { .backgroundColor(ColorTokens.bgSurfaceHover) }
    })
    .onClick(() => {
      this.getUIContext().animateTo({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve }, () => {
        this.menuOpen = !this.menuOpen;
      });
    })
    .bindPopup(this.menuOpen, {
      builder: this.menu,
      placement: Placement.BottomLeft,
      popupColor: Color.Transparent,
      enableArrow: false,
      autoCancel: true,
      targetSpace: SpacingTokens.x1,
      onStateChange: (event: PopupVisibilityEvent) => {
        if (!event.isVisible) {
          this.menuOpen = false;
        }
      }
    })
  }
}
