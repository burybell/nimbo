import { EnvironmentSwitcher } from '../environment/EnvironmentSwitcher';
import { NimboLogo } from './NimboLogo';
import { ColorTokens } from '../../tokens/ColorTokens';
import { SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { WindowChromeController } from '../../../services/WindowChromeController';

@Component
export struct GlobalToolbar {
  @StorageProp('nimbo.titleButtonInset') titleButtonInset: number = 132;
  @Prop compact: boolean = false;
  @Prop phone: boolean = false;
  @Prop selectedEnvironmentId: string = 'development';
  onEnvironmentChange: (id: string) => void = () => {};
  onSettings: () => void = () => {};

  build() {
    Row() {
      if (this.phone) {
        NimboLogo()
        Blank()
        EnvironmentSwitcher({ selectedId: this.selectedEnvironmentId, onChange: this.onEnvironmentChange })
        Text('⚙')
          .fontSize(18)
          .fontColor(ColorTokens.textSecondary)
          .width(SizeTokens.controlMedium)
          .height(SizeTokens.controlMedium)
          .textAlign(TextAlign.Center)
          .onClick(this.onSettings)
      } else {
        Row() {
          NimboLogo({ compact: true })
        }
        .width(this.compact ? SizeTokens.primarySidebarCompactWidth : SizeTokens.primarySidebarWidth)
        .height('100%')
        .padding({ left: this.compact ? SpacingTokens.x4 : SpacingTokens.x5 })
        .backgroundColor(ColorTokens.bgSidebar)

        Row({ space: SpacingTokens.x2 }) {
          Text('●')
            .fontSize(8)
            .fontColor(ColorTokens.statusSuccess)
          Text($r('app.string.toolbar_workspace_hint'))
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .height(SizeTokens.controlMedium)
        .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) WindowChromeController.startMoving();
        })

        Row({ space: SpacingTokens.x3 }) {
          EnvironmentSwitcher({ selectedId: this.selectedEnvironmentId, onChange: this.onEnvironmentChange })
          Text('⚙')
            .fontSize(18)
            .fontColor(ColorTokens.textSecondary)
            .width(SizeTokens.controlMedium)
            .height(SizeTokens.controlMedium)
            .textAlign(TextAlign.Center)
            .borderRadius(SizeTokens.controlMedium / 2)
            .stateStyles({
              normal: { .backgroundColor(ColorTokens.bgSurface) },
              pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) }
            })
            .onClick(this.onSettings)
        }
        .padding({ left: SpacingTokens.x4, right: this.titleButtonInset })
      }
    }
    .width('100%')
    .height(SizeTokens.globalToolbarHeight)
    .padding(this.phone ? { left: SpacingTokens.x3, right: SpacingTokens.x2 } : 0)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
