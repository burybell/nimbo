import { KeyValueItem } from '../../../models/ShellModels';
import { KeyValueEditor } from '../request/KeyValueEditor';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct CollectionVariablesDialog {
  @Prop targetName: string = '';
  @Prop initialVariables: KeyValueItem[] = [];
  @State variables: KeyValueItem[] = [];
  onCancel: () => void = () => {};
  onConfirm: (variables: KeyValueItem[]) => void = () => {};

  aboutToAppear(): void {
    this.variables = this.initialVariables.map((item: KeyValueItem): KeyValueItem => ({
      id: item.id, enabled: item.enabled, key: item.key, value: item.value,
      description: item.description, type: item.type, secret: item.secret
    }));
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim)
        .onClick(this.onCancel)
      Column() {
        Row({ space: SpacingTokens.x3 }) {
          Column({ space: SpacingTokens.x1 }) {
            Text($r('app.string.collection_variables'))
              .fontSize(18).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
            Text(this.targetName).fontSize(12).fontColor(ColorTokens.textSecondary).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text('×').fontSize(20).fontColor(ColorTokens.textSecondary)
            .width(SizeTokens.controlMedium).height(SizeTokens.controlMedium).textAlign(TextAlign.Center)
            .onClick(this.onCancel)
        }
        .width('100%')
        .padding({ left: SpacingTokens.x5, right: SpacingTokens.x4, top: SpacingTokens.x4,
          bottom: SpacingTokens.x3 })

        Text($r('app.string.collection_variables_hint'))
          .fontSize(11).fontColor(ColorTokens.textTertiary).width('100%').maxLines(2)
          .padding({ left: SpacingTokens.x5, right: SpacingTokens.x5, bottom: SpacingTokens.x3 })

        Scroll() {
          KeyValueEditor({
            items: this.variables,
            mode: 'environment',
            showDescription: true,
            showSecret: true,
            onChange: (items: KeyValueItem[]) => { this.variables = items; }
          })
          .padding({ left: SpacingTokens.x5, right: SpacingTokens.x5 })
        }
        .width('100%').layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Auto)

        Row({ space: SpacingTokens.x3 }) {
          Blank()
          Button($r('app.string.action_cancel')).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
            .onClick(this.onCancel)
          Button($r('app.string.action_save')).height(SizeTokens.controlMedium).fontSize(13)
            .fontColor(ColorTokens.textOnBrand).backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium).onClick(() => this.onConfirm(this.variables))
        }
        .width('100%').padding(SpacingTokens.x5)
      }
      .width('92%').height('72%').constraintSize({ minHeight: 420, maxWidth: 820, maxHeight: 620 })
      .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
  }
}
