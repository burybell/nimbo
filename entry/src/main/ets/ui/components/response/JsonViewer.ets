import { JsonCodeSurface } from '../common/JsonCodeSurface';

@Component
export struct JsonViewer {
  @Prop value: string = '';
  @Prop query: string = '';
  @Prop searchIndex: number = 0;
  @Prop searchRevision: number = 0;

  build() {
    JsonCodeSurface({
      value: this.value,
      readOnly: true,
      query: this.query,
      searchIndex: this.searchIndex,
      searchRevision: this.searchRevision
    })
    .width('100%')
    .height('100%')
  }
}
