import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct SettingRow {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop controlLabel: string = '';
  @Prop toggle: boolean = false;
  @Prop checked: boolean = false;
  @Prop dangerous: boolean = false;
  onToggle: (checked: boolean) => void = () => {};
  onPress: () => void = () => {};

  build() {
    Row({ space: SpacingTokens.x5 }) {
      Column({ space: SpacingTokens.x1 }) {
        Text(this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.dangerous ? ColorTokens.httpDelete : ColorTokens.textPrimary)
          .width('100%')
        Text(this.description)
          .fontSize(12)
          .lineHeight(18)
          .fontColor(ColorTokens.textTertiary)
          .width('100%')
      }
      .layoutWeight(1)
      if (this.toggle) {
        Toggle({ type: ToggleType.Switch, isOn: this.checked })
          .selectedColor(ColorTokens.brand500)
          .onChange(this.onToggle)
      } else if (this.controlLabel.length > 0) {
        Button(this.controlLabel)
          .fontSize(12)
          .fontColor(this.dangerous ? ColorTokens.httpDelete : ColorTokens.textPrimary)
          .backgroundColor(ColorTokens.bgSurface)
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium)
          .onClick(this.onPress)
      }
    }
    .width('100%')
    .height(76)
    .padding({ top: SpacingTokens.x3, bottom: SpacingTokens.x3 })
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
