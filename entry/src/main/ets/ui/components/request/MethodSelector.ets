import { HttpMethod } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct MethodSelector {
  @Prop value: HttpMethod = 'GET';
  @Prop fluid: boolean = false;
  onChange: (value: HttpMethod) => void = () => {};

  private methodIndex(): number {
    if (this.value === 'POST') return 1;
    if (this.value === 'PUT') return 2;
    if (this.value === 'PATCH') return 3;
    if (this.value === 'DELETE') return 4;
    if (this.value === 'HEAD') return 5;
    if (this.value === 'OPTIONS') return 6;
    return 0;
  }

  private methodFromIndex(index: number): HttpMethod {
    if (index === 1) return 'POST';
    if (index === 2) return 'PUT';
    if (index === 3) return 'PATCH';
    if (index === 4) return 'DELETE';
    if (index === 5) return 'HEAD';
    if (index === 6) return 'OPTIONS';
    return 'GET';
  }

  build() {
    Select([
      { value: 'GET' },
      { value: 'POST' },
      { value: 'PUT' },
      { value: 'PATCH' },
      { value: 'DELETE' },
      { value: 'HEAD' },
      { value: 'OPTIONS' }
    ])
      .selected(this.methodIndex())
      .value(this.value)
      .font({ size: 13, weight: FontWeight.Bold })
      .fontColor(ColorTokens.textPrimary)
      .selectedOptionBgColor(ColorTokens.brand50)
      .selectedOptionFontColor(ColorTokens.brand600)
      .height(SizeTokens.controlLarge)
      .width(this.fluid ? '100%' : 104)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x1 })
      .backgroundColor(ColorTokens.bgSurface)
      .borderRadius({ topLeft: RadiusTokens.medium, bottomLeft: RadiusTokens.medium })
      .border({ width: 1, color: ColorTokens.borderDefault })
      .onSelect((index: number) => this.onChange(this.methodFromIndex(index)))
  }
}
