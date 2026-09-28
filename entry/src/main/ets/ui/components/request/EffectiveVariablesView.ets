import { EffectiveVariableModel, VariableSourceKind } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct EffectiveVariablesView {
  @Prop variables: EffectiveVariableModel[] = [];
  @Prop missingVariables: string[] = [];
  @Prop compact: boolean = false;
  onEditSource: (kind: VariableSourceKind, id: string) => void = () => {};
  onConfigureMissing: () => void = () => {};

  private sourceLabel(kind: VariableSourceKind): ResourceStr {
    if (kind === 'collection') return $r('app.string.variable_source_collection');
    if (kind === 'folder') return $r('app.string.variable_source_folder');
    if (kind === 'runner') return $r('app.string.variable_source_runner');
    return $r('app.string.variable_source_environment');
  }

  private sourceChain(item: EffectiveVariableModel): string {
    return item.overriddenSources.map(source => source.name).join(' · ');
  }

  private sensitiveKey(key: string): boolean {
    const value = key.toLowerCase().split('_').join('-');
    return value.includes('authorization') || value.includes('password') || value.includes('secret') ||
      value.includes('token') || value.includes('api-key') || value.includes('apikey') ||
      value.includes('access-key') || value.includes('private-key') || value.includes('credential') ||
      value === 'cookie' || value === 'set-cookie';
  }

  private displayValue(item: EffectiveVariableModel): string {
    if (item.secret || this.sensitiveKey(item.key)) return '••••••';
    return item.value.length > 0 ? item.value : '—';
  }

  build() {
    Column({ space: SpacingTokens.x3 }) {
      Column({ space: SpacingTokens.x1 }) {
        Row({ space: SpacingTokens.x2 }) {
          Text($r('app.string.effective_variables_title'))
            .fontSize(13).fontWeight(FontWeight.Medium).fontColor(ColorTokens.textPrimary)
          Text(`${this.variables.length}`).fontSize(10).fontColor(ColorTokens.textTertiary)
        }.width('100%')
        Text($r('app.string.effective_variables_hint'))
          .fontSize(11).fontColor(ColorTokens.textTertiary).width('100%')
      }.width('100%').alignItems(HorizontalAlign.Start)

      if (this.missingVariables.length > 0) {
        Row({ space: SpacingTokens.x3 }) {
          Column({ space: 3 }) {
            Text($r('app.string.variable_missing_title')).fontSize(11).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.statusServerError)
            Text(this.missingVariables.map((name: string) => `{{${name}}}`).join(', '))
              .fontSize(11).fontFamily('monospace').fontColor(ColorTokens.statusServerError)
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Button($r('app.string.variable_configure')).height(SizeTokens.controlSmall).fontSize(10)
            .fontColor(ColorTokens.brand600).backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.small)
            .onClick(this.onConfigureMissing)
        }.width('100%').padding(SpacingTokens.x3).backgroundColor(ColorTokens.statusDangerBackground)
          .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
      }

      if (this.variables.length === 0) {
        Text($r('app.string.effective_variables_empty'))
          .width('100%').height(72).fontSize(12).fontColor(ColorTokens.textTertiary)
          .textAlign(TextAlign.Center).backgroundColor(ColorTokens.bgApp).borderRadius(RadiusTokens.medium)
      } else {
        Column() {
          ForEach(this.variables, (item: EffectiveVariableModel) => {
            Row({ space: SpacingTokens.x3 }) {
              Column({ space: 3 }) {
                Text(item.key).fontSize(12).fontFamily('monospace').fontWeight(FontWeight.Medium)
                  .fontColor(ColorTokens.textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                if (item.overriddenSources.length > 0) {
                  Row({ space: SpacingTokens.x1 }) {
                    Text($r('app.string.variable_overrides')).fontSize(10).fontColor(ColorTokens.textTertiary)
                    Text(this.sourceChain(item)).fontSize(10).fontColor(ColorTokens.textSecondary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.width('100%')
                }
              }.layoutWeight(3).alignItems(HorizontalAlign.Start)
              Text(this.displayValue(item))
                .layoutWeight(3).fontSize(11)
                .fontFamily(item.secret || this.sensitiveKey(item.key) ? '' : 'monospace')
                .fontColor(ColorTokens.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              Column({ space: 2 }) {
                Text(this.sourceLabel(item.source.kind)).fontSize(9).fontColor(ColorTokens.brand600)
                Text(item.source.name).fontSize(10).fontColor(ColorTokens.textTertiary)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }.layoutWeight(2).alignItems(HorizontalAlign.Start)
              Button($r('app.string.variable_edit_source'))
                .height(SizeTokens.controlSmall).fontSize(10).padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })
                .fontColor(ColorTokens.textSecondary).backgroundColor(ColorTokens.bgWorkspace)
                .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.small)
                .onClick(() => this.onEditSource(item.source.kind, item.source.id))
            }
            .width('100%').padding({ left: SpacingTokens.x3, right: SpacingTokens.x3,
              top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
            .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
          }, (item: EffectiveVariableModel) => `${item.key}-${item.source.kind}-${item.source.id}`)
        }
        .width('100%').backgroundColor(ColorTokens.bgApp)
        .border({ width: 1, color: ColorTokens.borderSubtle }).borderRadius(RadiusTokens.medium)
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding(this.compact ? SpacingTokens.x3 : 0)
  }
}
