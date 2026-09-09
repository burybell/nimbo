import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct EnvironmentSwitcher {
  @State selectedIndex: number = 0;
  private environments: SelectOption[] = [
    { value: 'Development' },
    { value: 'Staging' },
    { value: 'Production' }
  ];

  build() {
    Select(this.environments)
      .selected(this.selectedIndex)
      .value(this.environments[this.selectedIndex].value)
      .font({ size: 13 })
      .fontColor(ColorTokens.textPrimary)
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .borderRadius(RadiusTokens.medium)
      .onSelect((index: number) => {
        this.selectedIndex = index;
      })
  }
}
