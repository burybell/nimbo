import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

export interface CollectionTarget {
  id: string;
  name: string;
  depth: number;
}

@Component
export struct SaveRequestDialog {
  @Prop initialName: string = '';
  @Prop targets: CollectionTarget[] = [];
  @State requestName: string = '';
  @State targetId: string = '';
  onCancel: () => void = () => {};
  onConfirm: (name: string, targetId: string) => void = () => {};

  aboutToAppear(): void {
    this.requestName = this.initialName;
    if (this.targets.length > 0) this.targetId = this.targets[0].id;
  }

  private submit(): void {
    const name = this.requestName.trim();
    if (name.length > 0 && this.targetId.length > 0) this.onConfirm(name, this.targetId);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim)
        .onClick(this.onCancel)
      Column({ space: SpacingTokens.x4 }) {
        Text($r('app.string.collection_save_request')).fontSize(18).fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary).width('100%')
        TextInput({ text: this.requestName, placeholder: $r('app.string.request_name_placeholder') })
          .height(SizeTokens.controlLarge).fontSize(13).fontColor(ColorTokens.textPrimary)
          .backgroundColor(ColorTokens.bgWorkspace).border({ width: 1, color: ColorTokens.borderDefault })
          .borderRadius(RadiusTokens.medium).onChange((value: string) => { this.requestName = value; })
        Text($r('app.string.collection_location')).fontSize(12).fontColor(ColorTokens.textSecondary)
          .width('100%')
        Scroll() {
          Column({ space: SpacingTokens.x1 }) {
            ForEach(this.targets, (target: CollectionTarget) => {
              Row({ space: SpacingTokens.x2 }) {
                Text(target.depth === 0 ? '▣' : '□').fontSize(14)
                  .fontColor(target.id === this.targetId ? ColorTokens.brand600 : ColorTokens.textTertiary)
                Text(target.name).fontSize(13).fontColor(ColorTokens.textPrimary).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                if (target.id === this.targetId) {
                  Text('✓').fontSize(13).fontColor(ColorTokens.brand600)
                }
              }
              .width('100%').height(36)
              .padding({ left: SpacingTokens.x2 + target.depth * SpacingTokens.x4, right: SpacingTokens.x3 })
              .backgroundColor(target.id === this.targetId ? ColorTokens.bgSurfaceActive : ColorTokens.bgSurface)
              .borderRadius(RadiusTokens.small).onClick(() => { this.targetId = target.id; })
            }, (target: CollectionTarget) => target.id)
          }.width('100%')
        }
        .width('100%').height(180).border({ width: 1, color: ColorTokens.borderSubtle })
        .borderRadius(RadiusTokens.medium).scrollBar(BarState.Auto)
        Row({ space: SpacingTokens.x3 }) {
          Blank()
          Button($r('app.string.action_cancel')).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
            .onClick(this.onCancel)
          Button($r('app.string.action_save')).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(this.requestName.trim().length > 0 && this.targetId.length > 0 ?
              ColorTokens.brand500 : ColorTokens.textTertiary)
            .borderRadius(RadiusTokens.medium)
            .enabled(this.requestName.trim().length > 0 && this.targetId.length > 0)
            .onClick(() => this.submit())
        }.width('100%')
      }
      .width('90%').constraintSize({ maxWidth: 460 }).padding(SpacingTokens.x6)
      .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
  }
}
