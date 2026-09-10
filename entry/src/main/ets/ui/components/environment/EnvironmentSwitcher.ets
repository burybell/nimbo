import { EnvironmentModel } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct EnvironmentSwitcher {
  @Prop selectedId: string = 'development';
  @Prop environments: EnvironmentModel[] = [];
  onChange: (id: string) => void = () => {};

  private options(): SelectOption[] {
    return this.environments.map((environment: EnvironmentModel): SelectOption => ({ value: environment.name }));
  }

  private selectedIndex(): number {
    const index = this.environments.findIndex((environment: EnvironmentModel) => environment.id === this.selectedId);
    return index >= 0 ? index : 0;
  }

  build() {
    Select(this.options())
      .selected(this.selectedIndex())
      .value(this.environments.length > 0 ? this.environments[this.selectedIndex()].name : '')
      .font({ size: 13 })
      .fontColor(ColorTokens.textPrimary)
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
      .backgroundColor(ColorTokens.bgSurface)
      .border({ width: 1, color: ColorTokens.borderDefault })
      .borderRadius(RadiusTokens.medium)
      .onSelect((index: number) => {
        if (index >= 0 && index < this.environments.length) this.onChange(this.environments[index].id);
      })
  }
}
