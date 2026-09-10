import { ResponseMediaKind } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct MediaViewer {
  @Prop kind: ResponseMediaKind = 'none';
  @Prop uri: string = '';
  @Prop contentType: string = '';
  @Prop responseSize: string = '';
  @State loadFailed: boolean = false;
  private videoController: VideoController = new VideoController();
  onSave: () => void = () => {};

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Text(this.kind === 'video' ? $r('app.string.response_video') : $r('app.string.response_image'))
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textSecondary)
        Text(this.contentType)
          .fontSize(10)
          .fontColor(ColorTokens.textTertiary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text(this.responseSize).fontSize(10).fontColor(ColorTokens.textTertiary)
        Text($r('app.string.response_download_action'))
          .fontSize(11)
          .fontColor(ColorTokens.brand600)
          .height(SizeTokens.controlSmall)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .textAlign(TextAlign.Center)
          .backgroundColor(ColorTokens.brand50)
          .borderRadius(RadiusTokens.small)
          .onClick(this.onSave)
      }
      .width('100%')
      .height(36)
      .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2 })

      if (this.loadFailed) {
        Column({ space: SpacingTokens.x2 }) {
          Text($r('app.string.response_media_preview_failed'))
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
          Text(this.contentType).fontSize(11).fontColor(ColorTokens.textTertiary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.kind === 'image') {
        Image(this.uri)
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .interpolation(ImageInterpolation.High)
          .backgroundColor(ColorTokens.bgApp)
          .borderRadius(RadiusTokens.small)
          .onError(() => { this.loadFailed = true; })
      } else {
        Video({ src: this.uri, controller: this.videoController })
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .autoPlay(false)
          .controls(true)
          .backgroundColor(Color.Black)
          .borderRadius(RadiusTokens.small)
          .onError(() => { this.loadFailed = true; })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: SpacingTokens.x2, right: SpacingTokens.x2, bottom: SpacingTokens.x2 })
  }
}
