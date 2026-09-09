import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct EnvironmentSwitcher {
  @Prop selectedId: string = 'development';
  onChange: (id: string) => void = () => {};
  private environments: SelectOption[] = [
    { value: $r('app.string.environment_development') },
    { value: $r('app.string.environment_staging') },
    { value: $r('app.string.environment_production') }
  ];

  private selectedIndex(): number {
    if (this.selectedId === 'staging') return 1;
    if (this.selectedId === 'production') return 2;
    return 0;
  }

  private environmentId(index: number): string {
    if (index === 1) return 'staging';
    if (index === 2) return 'production';
    return 'development';
  }

  build() {
    Select(this.environments)
      .selected(this.selectedIndex())
      .value(this.environments[this.selectedIndex()].value)
      .font({ size: 13 })
      .fontColor(ColorTokens.textPrimary)
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .borderRadius(RadiusTokens.medium)
      .onSelect((index: number) => {
        this.onChange(this.environmentId(index));
      })
  }
}
