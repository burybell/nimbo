import { ColorTokens } from '../../tokens/ColorTokens';
import { SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct ResponseSummary {
  @Prop statusCode: number = 0;
  @Prop statusText: string = '';
  @Prop duration: string = '';
  @Prop responseSize: string = '';
  @Prop protocol: string = '';

  private statusColor(): ResourceColor {
    if (this.statusCode >= 200 && this.statusCode < 300) return ColorTokens.statusSuccess;
    if (this.statusCode >= 300 && this.statusCode < 400) return ColorTokens.statusRedirect;
    if (this.statusCode >= 400 && this.statusCode < 500) return ColorTokens.statusClientError;
    if (this.statusCode >= 500) return ColorTokens.statusServerError;
    return ColorTokens.textTertiary;
  }

  build() {
    Row({ space: SpacingTokens.x3 }) {
      Row({ space: SpacingTokens.x1 }) {
        Text('●')
          .fontSize(8)
          .fontColor(this.statusColor())
        Text(`${this.statusCode} ${this.statusText}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.statusColor())
      }
      Text(this.duration).fontSize(11).fontColor(ColorTokens.textSecondary)
      Text(this.responseSize).fontSize(11).fontColor(ColorTokens.textSecondary)
      Text(this.protocol).fontSize(11).fontColor(ColorTokens.textSecondary)
    }
  }
}
