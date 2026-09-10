import { EnvironmentModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

interface PopupVisibilityEvent {
  isVisible: boolean;
}

@Component
export struct EnvironmentSwitcher {
  @Prop selectedId: string = 'development';
  @Prop environments: EnvironmentModel[] = [];
  @State menuOpen: boolean = false;
  @State hoveredId: string = '';
  onChange: (id: string) => void = () => {};

  private selectedIndex(): number {
    const index = this.environments.findIndex((environment: EnvironmentModel) => environment.id === this.selectedId);
    return index >= 0 ? index : 0;
  }

  private selectedName(): string {
    return this.environments.length > 0 ? this.environments[this.selectedIndex()].name : '';
  }

  private select(id: string): void {
    this.menuOpen = false;
    this.onChange(id);
  }

  @Builder
  private menu() {
    Column({ space: 2 }) {
      ForEach(this.environments, (environment: EnvironmentModel) => {
        Row({ space: SpacingTokens.x2 }) {
          Text('●')
            .fontSize(6)
            .fontColor(environment.id === this.selectedId ? ColorTokens.brand500 : ColorTokens.textTertiary)
          Text(environment.name)
            .fontSize(11)
            .fontColor(ColorTokens.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (environment.id === this.selectedId) {
            Text('✓').fontSize(10).fontWeight(FontWeight.Bold).fontColor(ColorTokens.brand600)
          }
        }
        .width('100%')
        .height(32)
        .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
        .backgroundColor(environment.id === this.selectedId ? ColorTokens.bgSurfaceActive :
          (this.hoveredId === environment.id ? ColorTokens.bgSurfaceHover : ColorTokens.bgSurface))
        .borderRadius(RadiusTokens.small)
        .onHover((hovered: boolean) => { this.hoveredId = hovered ? environment.id : ''; })
        .onClick(() => this.select(environment.id))
      }, (environment: EnvironmentModel) => environment.id)
    }
    .width(180)
    .padding(SpacingTokens.x1)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: 1, color: ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.medium)
    .shadow({ radius: 10, color: ColorTokens.shadowDefault, offsetY: 3 })
  }

  build() {
    Row({ space: SpacingTokens.x2 }) {
      Text('●').fontSize(6).fontColor(ColorTokens.statusSuccess)
      Text(this.selectedName())
        .fontSize(11)
        .fontColor(ColorTokens.textSecondary)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Image($r('app.media.chevron_muted'))
        .width(11)
        .height(11)
        .objectFit(ImageFit.Contain)
        .rotate({ angle: this.menuOpen ? 180 : 0 })
    }
    .width(148)
    .height(28)
    .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
    .backgroundColor(this.menuOpen ? ColorTokens.bgSurfaceActive : ColorTokens.bgSurface)
    .border({ width: 1, color: this.menuOpen ? ColorTokens.borderFocus : ColorTokens.borderSubtle })
    .borderRadius(RadiusTokens.small)
    .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
    .onClick(() => { this.menuOpen = !this.menuOpen; })
    .bindPopup(this.menuOpen, {
      builder: this.menu,
      placement: Placement.BottomRight,
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
