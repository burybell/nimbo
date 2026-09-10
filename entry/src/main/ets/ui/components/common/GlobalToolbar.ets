import { EnvironmentSwitcher } from '../environment/EnvironmentSwitcher';
import { EnvironmentModel } from '../../../models/ShellModels';
import { NimboLogo } from './NimboLogo';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { WindowChromeController } from '../../../services/WindowChromeController';

@Component
export struct GlobalToolbar {
  @StorageProp('nimbo.titleButtonInset') titleButtonInset: number = 132;
  @Prop compact: boolean = false;
  @Prop phone: boolean = false;
  @Prop selectedEnvironmentId: string = 'development';
  @Prop environments: EnvironmentModel[] = [];
  onEnvironmentChange: (id: string) => void = () => {};
  onSettings: () => void = () => {};
  onSearch: () => void = () => {};

  build() {
    Row() {
      if (this.phone) {
        NimboLogo({ compact: true })
        Blank()
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.search')).width(16).height(16).objectFit(ImageFit.Contain)
        }
          .width(SizeTokens.controlMedium).height(SizeTokens.controlMedium)
          .borderRadius(SizeTokens.controlMedium / 2)
          .stateStyles({ normal: {}, pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) } })
          .onClick(this.onSearch)
        EnvironmentSwitcher({ selectedId: this.selectedEnvironmentId, environments: this.environments,
          onChange: this.onEnvironmentChange })
        Image($r('app.media.settings'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
          .padding(3)
          .width(SizeTokens.controlMedium)
          .height(SizeTokens.controlMedium)
          .borderRadius(SizeTokens.controlMedium / 2)
          .stateStyles({ normal: { .opacity(0.9) }, pressed: { .opacity(0.65) } })
          .onClick(this.onSettings)
      } else {
        Stack({ alignContent: Alignment.Center }) {
          Row() {
            Row() {
              NimboLogo({ compact: true })
            }
            .width(this.compact ? SizeTokens.primarySidebarCompactWidth : SizeTokens.primarySidebarWidth)
            .height('100%')
            .padding({ left: this.compact ? SpacingTokens.x4 : SpacingTokens.x5 })
            .backgroundColor(ColorTokens.bgSidebar)

            Row({ space: SpacingTokens.x2 }) {
              Text('●').fontSize(8).fontColor(ColorTokens.statusSuccess)
              Text($r('app.string.toolbar_workspace_hint')).fontSize(12).fontColor(ColorTokens.textTertiary)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1).height('100%').padding({ left: SpacingTokens.x3 })
            .gesture(TapGesture({ count: 2 }).onAction(() => WindowChromeController.toggleMaximized()))

            Row({ space: SpacingTokens.x3 }) {
              EnvironmentSwitcher({ selectedId: this.selectedEnvironmentId, environments: this.environments,
                onChange: this.onEnvironmentChange })
              Image($r('app.media.settings'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
                .padding(3)
                .width(SizeTokens.controlMedium)
                .height(SizeTokens.controlMedium)
                .borderRadius(SizeTokens.controlMedium / 2)
                .stateStyles({
                  normal: { .backgroundColor(ColorTokens.bgSurface).opacity(0.9) },
                  pressed: { .backgroundColor(ColorTokens.bgSurfaceActive).opacity(0.65) }
                })
                .onClick(this.onSettings)
            }
            .padding({ left: SpacingTokens.x4, right: this.titleButtonInset })
          }
          .width('100%')
          .height('100%')

          Row({ space: SpacingTokens.x2 }) {
            Image($r('app.media.search')).width(14).height(14).objectFit(ImageFit.Contain)
            Text($r('app.string.global_search_placeholder')).fontSize(12).fontColor(ColorTokens.textTertiary)
              .layoutWeight(1).maxLines(1)
            Text('Ctrl K').fontSize(10).fontColor(ColorTokens.textTertiary)
              .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, top: 3, bottom: 3 })
              .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.small)
          }
          .width(this.compact ? 220 : 300).height(SizeTokens.controlMedium)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2 })
          .backgroundColor(ColorTokens.bgWorkspace)
          .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.medium)
          .stateStyles({ normal: {}, pressed: { .backgroundColor(ColorTokens.bgSurfaceActive) } })
          .onClick(this.onSearch)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height(SizeTokens.globalToolbarHeight)
    .padding(this.phone ? { left: SpacingTokens.x3, right: this.titleButtonInset } : 0)
    .backgroundColor(ColorTokens.bgSurface)
    .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
  }
}
