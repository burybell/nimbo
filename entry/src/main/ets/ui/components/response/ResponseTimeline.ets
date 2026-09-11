import { ResponseTiming } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';

interface TimelineItem {
  id: string;
  label: ResourceStr;
  duration: number;
  color: ResourceColor;
}

@Component
export struct ResponseTimeline {
  @Prop timing: ResponseTiming;

  private items(): TimelineItem[] {
    return [
      { id: 'dns', label: $r('app.string.timeline_dns'), duration: this.timing.dnsMs,
        color: ColorTokens.brand500 },
      { id: 'connect', label: $r('app.string.timeline_connect'), duration: this.timing.connectMs,
        color: ColorTokens.statusInfo },
      { id: 'tls', label: $r('app.string.timeline_tls'), duration: this.timing.tlsMs,
        color: ColorTokens.httpPatch },
      { id: 'send', label: $r('app.string.timeline_send'), duration: this.timing.sendMs,
        color: ColorTokens.httpPost },
      { id: 'wait', label: $r('app.string.timeline_wait'), duration: this.timing.waitMs,
        color: ColorTokens.statusRedirect },
      { id: 'download', label: $r('app.string.timeline_download'), duration: this.timing.downloadMs,
        color: ColorTokens.statusSuccess }
    ];
  }

  private duration(value: number): string {
    if (value > 0 && value < 1) return '<1 ms';
    return `${Math.round(value)} ms`;
  }

  private barWidth(value: number): string {
    if (value <= 0 || this.timing.totalMs <= 0) return '0%';
    return `${Math.max(2, Math.min(100, value / this.timing.totalMs * 100))}%`;
  }

  @Builder
  private timingRow(item: TimelineItem) {
    Column({ space: SpacingTokens.x2 }) {
      Row() {
        Row({ space: SpacingTokens.x2 }) {
          Row()
            .width(8)
            .height(8)
            .borderRadius(RadiusTokens.full)
            .backgroundColor(item.color)
          Text(item.label)
            .fontSize(12)
            .fontColor(ColorTokens.textSecondary)
        }
        .layoutWeight(1)
        Text(this.duration(item.duration))
          .fontSize(12)
          .fontFamily('monospace')
          .fontColor(ColorTokens.textPrimary)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .borderRadius(RadiusTokens.full)
          .backgroundColor(ColorTokens.bgSurfaceActive)
        if (item.duration > 0) {
          Row()
            .width(this.barWidth(item.duration))
            .height(6)
            .borderRadius(RadiusTokens.full)
            .backgroundColor(item.color)
        }
      }
      .width('100%')
      .height(6)
    }
    .width('100%')
    .padding({ top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
  }

  build() {
    Scroll() {
      Column({ space: SpacingTokens.x3 }) {
        Row() {
          Column({ space: SpacingTokens.x1 }) {
            Text($r('app.string.timeline_total'))
              .fontSize(12)
              .fontColor(ColorTokens.textSecondary)
            Text(this.duration(this.timing.totalMs))
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorTokens.textPrimary)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(SpacingTokens.x4)
        .backgroundColor(ColorTokens.bgSurface)
        .border({ width: 1, color: ColorTokens.borderSubtle })
        .borderRadius(RadiusTokens.medium)

        Column() {
          ForEach(this.items(), (item: TimelineItem) => {
            this.timingRow(item)
          }, (item: TimelineItem) => item.id)
        }
        .width('100%')
        .padding({ left: SpacingTokens.x4, right: SpacingTokens.x4,
          top: SpacingTokens.x2, bottom: SpacingTokens.x2 })
        .backgroundColor(ColorTokens.bgSurface)
        .border({ width: 1, color: ColorTokens.borderSubtle })
        .borderRadius(RadiusTokens.medium)

        Text($r('app.string.timeline_reuse_hint'))
          .fontSize(11)
          .fontColor(ColorTokens.textTertiary)
          .width('100%')
      }
      .width('100%')
      .padding(SpacingTokens.x4)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .align(Alignment.TopStart)
  }
}
