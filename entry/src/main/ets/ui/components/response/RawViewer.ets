import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct RawViewer {
  @Prop value: string = '';
  @Prop query: string = '';
  @Prop searchIndex: number = 0;
  @Prop searchRevision: number = 0;

  build() {
    JsonCodeSurface({
      value: this.value,
      readOnly: true,
      syntaxHighlight: false,
      query: this.query,
      searchIndex: this.searchIndex,
      searchRevision: this.searchRevision
    })
    .width('100%')
    .height('100%')
  }
}
