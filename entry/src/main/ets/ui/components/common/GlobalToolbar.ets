import { EnvironmentSwitcher } from '../environment/EnvironmentSwitcher';
import { NimboLogo } from './NimboLogo';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct GlobalToolbar {
  @Prop compact: boolean = false;
  @Prop selectedEnvironmentId: string = 'development';
  onEnvironmentChange: (id: string) => void = () => {};
  onSettings: () => void = () => {};

  build() {
    Row() {
      Row() {
        NimboLogo({ compact: this.compact })
      }
      .width(this.compact ? SizeTokens.primarySidebarCompactWidth : SizeTokens.primarySidebarWidth)
      .padding({ left: this.compact ? SpacingTokens.x4 : SpacingTokens.x5 })

      Row() {
        Text('⌕')
          .fontSize(18)
          .fontColor(ColorTokens.textSecondary)
        Text('Search requests, collections, or history…')
          .fontSize(13)
          .fontColor(ColorTokens.textTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text('Ctrl  K')
          .fontSize(11)
          .fontColor(ColorTokens.textTertiary)
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.small)
      }
      .layoutWeight(1)
      .height(SizeTokens.controlMedium)
      .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
      .backgroundColor(ColorTokens.bgApp)
      .borderRadius(RadiusTokens.medium)

      Row({ space: SpacingTokens.x3 }) {
        EnvironmentSwitcher({ selectedId: this.selectedEnvironmentId, onChange: this.onEnvironmentChange })
        Text('⚙')
          .fontSize(18)
          .fontColor(ColorTokens.textSecondary)
          .width(SizeTokens.controlMedium)
          .height(SizeTokens.controlMedium)
          .textAlign(TextAlign.Center)
          .onClick(this.onSettings)
      }
      .padding({ left: SpacingTokens.x4, right: SpacingTokens.x5 })
    }
    .width('100%')
    .height(SizeTokens.globalToolbarHeight)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
