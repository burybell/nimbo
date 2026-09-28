import { RunnerFilter, RunnerItemModel, RunnerItemStatus } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct CollectionRunnerDialog {
  @Prop targetName: string = '';
  @Prop environmentName: string = '';
  @Prop dataFileName: string = '';
  @Prop dataRowCount: number = 0;
  @Prop dataColumns: string = '';
  @Prop dataError: string = '';
  @Link items: RunnerItemModel[];
  @Prop running: boolean = false;
  @State iterationsText: string = '1';
  @State delayText: string = '0';
  @State activeFilter: RunnerFilter = 'all';
  @State expandedItemId: string = '';
  onStart: (iterations: number, delayMs: number) => void = () => {};
  onStop: () => void = () => {};
  onExport: () => void = () => {};
  onSelectData: () => void = () => {};
  onClearData: () => void = () => {};
  onClose: () => void = () => {};

  private statusLabel(status: RunnerItemStatus): ResourceStr {
    if (status === 'running') return $r('app.string.runner_running');
    if (status === 'passed') return $r('app.string.runner_passed');
    if (status === 'failed') return $r('app.string.runner_failed');
    if (status === 'cancelled') return $r('app.string.runner_cancelled');
    return $r('app.string.runner_queued');
  }

  private statusColor(status: RunnerItemStatus): ResourceColor {
    if (status === 'passed') return ColorTokens.statusSuccess;
    if (status === 'failed') return ColorTokens.httpDelete;
    if (status === 'running') return ColorTokens.brand500;
    return ColorTokens.textTertiary;
  }

  private completedCount(): number {
    return this.items.filter((item: RunnerItemModel) => item.status === 'passed' ||
      item.status === 'failed' || item.status === 'cancelled').length;
  }

  private passedCount(): number {
    return this.items.filter((item: RunnerItemModel) => item.status === 'passed').length;
  }

  private failedCount(): number {
    return this.items.filter((item: RunnerItemModel) => item.status === 'failed').length;
  }

  private cancelledCount(): number {
    return this.items.filter((item: RunnerItemModel) => item.status === 'cancelled').length;
  }

  private filteredItems(): RunnerItemModel[] {
    if (this.activeFilter === 'all') return this.items;
    return this.items.filter((item: RunnerItemModel) => item.status === this.activeFilter);
  }

  private filterCount(filter: RunnerFilter): number {
    if (filter === 'all') return this.items.length;
    if (filter === 'passed') return this.passedCount();
    if (filter === 'failed') return this.failedCount();
    return this.cancelledCount();
  }

  private start(): void {
    const iterations = Math.max(1, Math.min(100, Number.parseInt(this.iterationsText) || 1));
    const delayMs = Math.max(0, Math.min(60000, Number.parseInt(this.delayText) || 0));
    this.iterationsText = iterations.toString();
    this.delayText = delayMs.toString();
    this.activeFilter = 'all';
    this.expandedItemId = '';
    this.onStart(iterations, delayMs);
  }

  @Builder
  private numericField(label: ResourceStr, value: string, enabled: boolean,
    change: (value: string) => void) {
    Column({ space: SpacingTokens.x2 }) {
      Text(label).fontSize(11).fontColor(ColorTokens.textSecondary).width('100%')
      TextInput({ text: value })
        .type(InputType.Number)
        .height(SizeTokens.controlLarge)
        .fontSize(13)
        .fontColor(ColorTokens.textPrimary)
        .backgroundColor(ColorTokens.bgWorkspace)
        .border({ width: 1, color: ColorTokens.borderDefault })
        .borderRadius(RadiusTokens.medium)
        .enabled(enabled)
        .onChange(change)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private filterButton(filter: RunnerFilter, label: ResourceStr) {
    Button() {
      Row({ space: SpacingTokens.x1 }) {
        Text(label).fontSize(11)
        Text(this.filterCount(filter).toString()).fontSize(10)
      }
    }
    .height(SizeTokens.controlSmall)
    .fontColor(this.activeFilter === filter ? ColorTokens.textOnBrand : ColorTokens.textSecondary)
    .backgroundColor(this.activeFilter === filter ? ColorTokens.brand500 : ColorTokens.bgWorkspace)
    .borderRadius(RadiusTokens.full)
    .onClick(() => {
      this.activeFilter = filter;
      this.expandedItemId = '';
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width('100%').height('100%').backgroundColor(ColorTokens.overlayScrim)
      Column() {
        Row({ space: SpacingTokens.x3 }) {
          Column({ space: SpacingTokens.x1 }) {
            Text($r('app.string.runner_title'))
              .fontSize(19).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary)
            Text(this.targetName)
              .fontSize(12).fontColor(ColorTokens.textSecondary).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text('×').fontSize(20).fontColor(ColorTokens.textSecondary)
            .width(SizeTokens.controlMedium).height(SizeTokens.controlMedium).textAlign(TextAlign.Center)
            .enabled(!this.running).opacity(this.running ? 0.4 : 1).onClick(this.onClose)
        }
        .width('100%')
        .padding({ left: SpacingTokens.x6, right: SpacingTokens.x5, top: SpacingTokens.x5,
          bottom: SpacingTokens.x4 })

        Column({ space: SpacingTokens.x4 }) {
          Row({ space: SpacingTokens.x4 }) {
            Column({ space: SpacingTokens.x2 }) {
              Text($r('app.string.runner_scope')).fontSize(11).fontColor(ColorTokens.textSecondary)
                .width('100%')
              Text(this.targetName).fontSize(13).fontColor(ColorTokens.textPrimary).width('100%')
                .height(SizeTokens.controlLarge).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
                .backgroundColor(ColorTokens.bgWorkspace).borderRadius(RadiusTokens.medium)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Column({ space: SpacingTokens.x2 }) {
              Text($r('app.string.runner_environment')).fontSize(11).fontColor(ColorTokens.textSecondary)
                .width('100%')
              Text(this.environmentName).fontSize(13).fontColor(ColorTokens.textPrimary).width('100%')
                .height(SizeTokens.controlLarge).padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
                .backgroundColor(ColorTokens.bgWorkspace).borderRadius(RadiusTokens.medium)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }.width('100%')

          Row({ space: SpacingTokens.x4 }) {
            this.numericField($r('app.string.runner_iterations'),
              this.dataRowCount > 0 ? this.dataRowCount.toString() : this.iterationsText,
              !this.running && this.dataRowCount === 0,
              (value: string) => { this.iterationsText = value; })
            this.numericField($r('app.string.runner_delay'), this.delayText, !this.running,
              (value: string) => { this.delayText = value; })
          }.width('100%')

          Column({ space: SpacingTokens.x2 }) {
            Text($r('app.string.runner_data')).fontSize(11).fontColor(ColorTokens.textSecondary).width('100%')
            Row({ space: SpacingTokens.x2 }) {
              if (this.dataFileName.length > 0) {
                Column({ space: SpacingTokens.x1 }) {
                  Text(this.dataFileName).fontSize(12).fontColor(ColorTokens.textPrimary).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: SpacingTokens.x1 }) {
                    Text(this.dataRowCount.toString()).fontSize(10).fontColor(ColorTokens.brand500)
                    Text($r('app.string.runner_data_rows')).fontSize(10).fontColor(ColorTokens.textTertiary)
                  }
                  Row({ space: SpacingTokens.x1 }) {
                    Text($r('app.string.runner_data_variables')).fontSize(10).fontColor(ColorTokens.textTertiary)
                    Text(this.dataColumns).fontSize(10).fontColor(ColorTokens.textSecondary).maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button($r('app.string.runner_data_clear')).height(SizeTokens.controlSmall).fontSize(11)
                  .fontColor(ColorTokens.textSecondary).backgroundColor(ColorTokens.bgWorkspace)
                  .borderRadius(RadiusTokens.medium).enabled(!this.running).onClick(this.onClearData)
              } else {
                Button($r('app.string.runner_data_select')).height(SizeTokens.controlMedium).fontSize(12)
                  .fontColor(ColorTokens.brand500).backgroundColor(ColorTokens.bgWorkspace)
                  .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
                  .enabled(!this.running).onClick(this.onSelectData)
                Text($r('app.string.runner_data_hint')).fontSize(10).fontColor(ColorTokens.textTertiary)
                  .layoutWeight(1).maxLines(2)
              }
            }.width('100%')
            if (this.dataError.length > 0) {
              Text(this.dataError).fontSize(10).fontColor(ColorTokens.httpDelete).width('100%').maxLines(2)
            }
          }
          .width('100%').padding(SpacingTokens.x3).backgroundColor(ColorTokens.bgWorkspace)
          .borderRadius(RadiusTokens.medium).alignItems(HorizontalAlign.Start)

          Row({ space: SpacingTokens.x3 }) {
            Text($r('app.string.runner_progress')).fontSize(13).fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
            Text(`${this.completedCount()} / ${this.items.length}`)
              .fontSize(12).fontColor(ColorTokens.textSecondary)
            Blank()
            Text(`✓ ${this.passedCount()}`).fontSize(12).fontColor(ColorTokens.statusSuccess)
            Text(`× ${this.failedCount()}`).fontSize(12).fontColor(ColorTokens.httpDelete)
          }.width('100%')

          Row({ space: SpacingTokens.x2 }) {
            this.filterButton('all', $r('app.string.runner_all'))
            this.filterButton('passed', $r('app.string.runner_passed'))
            this.filterButton('failed', $r('app.string.runner_failed'))
            this.filterButton('cancelled', $r('app.string.runner_cancelled'))
          }.width('100%')

          if (this.items.length === 0) {
            Column({ space: SpacingTokens.x2 }) {
              Text('◇').fontSize(28).fontColor(ColorTokens.textTertiary)
              Text($r('app.string.runner_no_requests')).fontSize(13).fontColor(ColorTokens.textSecondary)
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.filteredItems().length === 0) {
            Column({ space: SpacingTokens.x2 }) {
              Text('◇').fontSize(28).fontColor(ColorTokens.textTertiary)
              Text($r('app.string.runner_no_filtered')).fontSize(13).fontColor(ColorTokens.textSecondary)
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            Scroll() {
              Column({ space: SpacingTokens.x2 }) {
                ForEach(this.filteredItems(), (item: RunnerItemModel) => {
                  Row({ space: SpacingTokens.x3 }) {
                    Text(item.method).fontSize(10).fontWeight(FontWeight.Medium)
                      .fontColor(item.method === 'GET' ? ColorTokens.httpGet :
                        (item.method === 'POST' ? ColorTokens.httpPost : ColorTokens.httpOther))
                      .width(44)
                    Column({ space: SpacingTokens.x1 }) {
                      Text(item.name).fontSize(13).fontColor(ColorTokens.textPrimary).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Row({ space: SpacingTokens.x2 }) {
                        Row({ space: SpacingTokens.x1 }) {
                          Text($r('app.string.runner_iteration')).fontSize(10).fontColor(ColorTokens.textTertiary)
                          Text(item.iteration.toString()).fontSize(10).fontColor(ColorTokens.textTertiary)
                        }
                        if (item.statusCode > 0) {
                          Text(item.statusCode.toString()).fontSize(10).fontColor(ColorTokens.textSecondary)
                        }
                        if (item.duration.length > 0) {
                          Text(item.duration).fontSize(10).fontColor(ColorTokens.textSecondary)
                        }
                        if (item.passedTests + item.failedTests > 0) {
                          Row({ space: SpacingTokens.x1 }) {
                            Text(`${item.passedTests}/${item.passedTests + item.failedTests}`)
                              .fontSize(10).fontColor(ColorTokens.textSecondary)
                            Text($r('app.string.runner_tests')).fontSize(10).fontColor(ColorTokens.textSecondary)
                          }
                        }
                      }
                      if (item.message.length > 0) {
                        Text(item.message).fontSize(10).fontColor(ColorTokens.textTertiary).maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      if (this.expandedItemId === item.id && item.details.length > 0) {
                        Column({ space: SpacingTokens.x1 }) {
                          Text($r('app.string.runner_details')).fontSize(10).fontWeight(FontWeight.Medium)
                            .fontColor(ColorTokens.textSecondary).width('100%')
                          ForEach(item.details, (detail: string) => {
                            Text(`• ${detail}`).fontSize(10).fontColor(ColorTokens.textTertiary).width('100%')
                          }, (detail: string, detailIndex: number) => `${detailIndex}-${detail}`)
                        }.width('100%').padding({ top: SpacingTokens.x1 })
                      }
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    Text(this.statusLabel(item.status)).fontSize(11).fontWeight(FontWeight.Medium)
                      .fontColor(this.statusColor(item.status))
                    if (item.details.length > 0) {
                      Text('›').fontSize(16).fontColor(ColorTokens.textTertiary)
                        .rotate({ angle: this.expandedItemId === item.id ? 90 : 0 })
                        .animation({ duration: MotionTokens.fast, curve: MotionTokens.standardCurve })
                    }
                  }
                  .width('100%').padding(SpacingTokens.x3).backgroundColor(ColorTokens.bgWorkspace)
                  .borderRadius(RadiusTokens.medium)
                  .onClick(() => {
                    if (item.details.length > 0) {
                      this.expandedItemId = this.expandedItemId === item.id ? '' : item.id;
                    }
                  })
                }, (item: RunnerItemModel) =>
                  `${item.id}-${item.status}-${item.statusCode}-${item.message}-${this.expandedItemId === item.id}`)
              }.width('100%')
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Auto)
          }
        }
        .width('100%').layoutWeight(1)
        .padding({ left: SpacingTokens.x6, right: SpacingTokens.x6, bottom: SpacingTokens.x4 })

        Row({ space: SpacingTokens.x3 }) {
          Blank()
          if (this.running) {
            Button($r('app.string.runner_stop')).height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.httpDelete).backgroundColor(ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.statusDangerBorder }).borderRadius(RadiusTokens.medium)
              .onClick(this.onStop)
          } else {
            if (this.completedCount() > 0) {
              Button($r('app.string.runner_export')).height(SizeTokens.controlMedium).fontSize(13)
                .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
                .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
                .onClick(this.onExport)
            }
            Button($r('app.string.runner_close')).height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.textPrimary).backgroundColor(ColorTokens.bgSurface)
              .border({ width: 1, color: ColorTokens.borderDefault }).borderRadius(RadiusTokens.medium)
              .onClick(this.onClose)
            Button($r('app.string.runner_start')).height(SizeTokens.controlMedium).fontSize(13)
              .fontColor(ColorTokens.textOnBrand)
              .backgroundColor(this.items.length > 0 && this.dataError.length === 0 ?
                ColorTokens.brand500 : ColorTokens.textTertiary)
              .borderRadius(RadiusTokens.medium).enabled(this.items.length > 0 && this.dataError.length === 0)
              .onClick(() => this.start())
          }
        }.width('100%').padding({ left: SpacingTokens.x6, right: SpacingTokens.x6,
          top: SpacingTokens.x3, bottom: SpacingTokens.x5 })
      }
      .width('78%').height('82%').constraintSize({ minWidth: 640, maxWidth: 860, minHeight: 520, maxHeight: 720 })
      .backgroundColor(ColorTokens.bgSurface).borderRadius(RadiusTokens.large)
      .shadow({ radius: 20, color: ColorTokens.shadowDefault, offsetY: 8 })
      .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 }))
        .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
    }
    .width('100%').height('100%')
  }
}
