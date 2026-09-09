import { EnvironmentModel, KeyValueItem } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { KeyValueEditor } from '../request/KeyValueEditor';

@Component
export struct EnvironmentPage {
  @Prop environments: EnvironmentModel[] = [];
  @State selectedId: string = 'development';
  onChange: (id: string, variables: KeyValueItem[]) => void = () => {};
  onSaved: () => void = () => {};

  private selectedEnvironment(): EnvironmentModel {
    const found = this.environments.find((environment: EnvironmentModel) => environment.id === this.selectedId);
    if (found) return found;
    return { id: '', name: 'Environment', kind: 'development', variables: [] };
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text('Environments')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
          Blank()
          Text('+')
            .fontSize(20)
            .fontColor(ColorTokens.brand500)
        }
        .width('100%')
        .height(48)
        .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4 })

        ForEach(this.environments, (environment: EnvironmentModel) => {
          Row({ space: SpacingTokens.x3 }) {
            Text('◎')
              .fontSize(15)
              .fontColor(environment.id === this.selectedId ? ColorTokens.brand500 : ColorTokens.textTertiary)
            Column({ space: 2 }) {
              Text(environment.name)
                .fontSize(13)
                .fontWeight(environment.id === this.selectedId ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(ColorTokens.textPrimary)
                .width('100%')
              Text(`${environment.variables.length} variables`)
                .fontSize(11)
                .fontColor(ColorTokens.textTertiary)
                .width('100%')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .height(54)
          .padding({ left: SpacingTokens.x4, right: SpacingTokens.x3 })
          .backgroundColor(environment.id === this.selectedId ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
          .borderRadius(RadiusTokens.medium)
          .onClick(() => { this.selectedId = environment.id; })
        }, (environment: EnvironmentModel) => environment.id)
        Blank()
      }
      .width(240)
      .height('100%')
      .padding(SpacingTokens.x2)
      .backgroundColor(ColorTokens.bgSidebar)
      .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

      Column() {
        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text(this.selectedEnvironment().name)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text('Variables are resolved in the active request environment.')
              .fontSize(12)
              .fontColor(ColorTokens.textTertiary)
          }
          Blank()
          Button('Save')
            .fontSize(13)
            .fontColor(ColorTokens.textOnBrand)
            .backgroundColor(ColorTokens.brand500)
            .borderRadius(RadiusTokens.medium)
            .onClick(this.onSaved)
        }
        .width('100%')
        .height(76)
        .padding({ left: SpacingTokens.x6, right: SpacingTokens.x6 })
        .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })

        Scroll() {
          Column({ space: SpacingTokens.x3 }) {
            Text('Variables')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
              .width('100%')
            KeyValueEditor({
              items: this.selectedEnvironment().variables,
              mode: 'environment',
              showDescription: true,
              showSecret: true,
              onChange: (items: KeyValueItem[]) => this.onChange(this.selectedId, items)
            })
          }
          .width('100%')
          .padding(SpacingTokens.x6)
        }
        .layoutWeight(1)
        .width('100%')
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(ColorTokens.bgWorkspace)
    }
    .width('100%')
    .height('100%')
  }
}
