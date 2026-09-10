import { KeyValueItem, KeyValueMode } from '../../../models/ShellModels';
import filePicker from '@ohos.file.picker';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { MotionTokens } from '../../tokens/MotionTokens';

@Component
export struct KeyValueEditor {
  @Prop items: KeyValueItem[] = [];
  @Prop mode: KeyValueMode = 'params';
  @Prop showDescription: boolean = true;
  @Prop showType: boolean = false;
  @Prop showSecret: boolean = false;
  @State bulkMode: boolean = false;
  @State bulkValue: string = '';
  @State bulkError: ResourceStr = '';
  @State bulkErrorVisible: boolean = false;
  private nextItemNumber: number = 1;
  onChange: (items: KeyValueItem[]) => void = () => {};

  private addLabel(): ResourceStr {
    if (this.mode === 'headers') return $r('app.string.add_header');
    if (this.mode === 'form') return $r('app.string.add_field');
    if (this.mode === 'multipart') return $r('app.string.add_part');
    if (this.mode === 'environment') return $r('app.string.add_variable');
    return $r('app.string.add_parameter');
  }

  private toggleSecret(id: string, secret: boolean): void {
    this.onChange(this.items.map((item: KeyValueItem) => {
      if (item.id !== id) return item;
      return {
        id: item.id,
        enabled: item.enabled,
        key: item.key,
        value: item.value,
        description: item.description,
        type: item.type,
        secret
      };
    }));
  }

  private updateItem(id: string, key: string, value: string, description: string,
    enabled: boolean, type: 'text' | 'file'): void {
    this.onChange(this.items.map((item: KeyValueItem) => {
      if (item.id !== id) return item;
      return {
        id: item.id,
        enabled,
        key,
        value,
        description,
        type,
        secret: item.secret
      };
    }));
  }

  private addItem(): void {
    const id = `${this.mode}-${Date.now()}-${this.nextItemNumber}`;
    this.nextItemNumber += 1;
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
      this.onChange([...this.items, {
        id,
        enabled: true,
        key: '',
        value: '',
        description: '',
        type: 'text',
        secret: false
      }]);
    });
  }

  private duplicateItem(item: KeyValueItem): void {
    const id = `${this.mode}-copy-${Date.now()}-${this.nextItemNumber}`;
    this.nextItemNumber += 1;
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
      this.onChange([...this.items, {
        id,
        enabled: item.enabled,
        key: item.key,
        value: item.value,
        description: item.description,
        type: item.type,
        secret: item.secret
      }]);
    });
  }

  private removeItem(id: string): void {
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.exitCurve }, () => {
      this.onChange(this.items.filter((item: KeyValueItem) => item.id !== id));
    });
  }

  private async selectItemFile(item: KeyValueItem): Promise<void> {
    try {
      const picker = new filePicker.DocumentViewPicker();
      const uris = await picker.select();
      if (uris.length > 0) {
        this.updateItem(item.id, item.key, uris[0], item.description, item.enabled, 'file');
      }
    } catch (_error) {
      // Cancelling the system picker keeps the previous selection.
    }
  }

  private enterBulkMode(): void {
    const lines: string[] = [];
    this.items.forEach((item: KeyValueItem) => {
      lines.push(`${item.key}:${item.value}`);
    });
    this.bulkValue = lines.join('\n');
    this.bulkError = '';
    this.bulkErrorVisible = false;
    this.bulkMode = true;
  }

  private applyBulk(): void {
    const lines = this.bulkValue.split('\n');
    const nextItems: KeyValueItem[] = [];
    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index].trim();
      if (line.length === 0) continue;
      const separator = line.indexOf(':');
      if (separator <= 0) {
        this.bulkError = $r('app.string.bulk_error');
        this.bulkErrorVisible = true;
        return;
      }
      nextItems.push({
        id: `${this.mode}-bulk-${index}`,
        enabled: true,
        key: line.substring(0, separator).trim(),
        value: line.substring(separator + 1).trim(),
        description: '',
        type: 'text',
        secret: false
      });
    }
    this.getUIContext().animateTo({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }, () => {
      this.onChange(nextItems);
      this.bulkError = '';
      this.bulkErrorVisible = false;
      this.bulkMode = false;
    });
  }

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Row({ space: SpacingTokens.x1 }) {
          Text(`${this.items.length}`).fontSize(12).fontColor(ColorTokens.textTertiary)
          Text($r('app.string.items')).fontSize(12).fontColor(ColorTokens.textTertiary)
        }
        Blank()
        Text(this.bulkMode ? $r('app.string.edit_table') : $r('app.string.edit_bulk'))
          .fontSize(12)
          .fontColor(ColorTokens.brand600)
          .height(SizeTokens.controlSmall)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .textAlign(TextAlign.Center)
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            if (this.bulkMode) {
              this.getUIContext().animateTo({ duration: MotionTokens.normal,
                curve: MotionTokens.standardCurve }, () => {
                this.bulkMode = false;
                this.bulkError = '';
                this.bulkErrorVisible = false;
              });
            } else {
              this.getUIContext().animateTo({ duration: MotionTokens.normal,
                curve: MotionTokens.standardCurve }, () => this.enterBulkMode());
            }
          })
      }
      .width('100%')
      .height(36)

      if (this.bulkMode) {
        Column({ space: SpacingTokens.x2 }) {
          TextArea({ text: this.bulkValue, placeholder: $r('app.string.bulk_placeholder') })
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor(ColorTokens.textPrimary)
            .height(180)
            .padding(SpacingTokens.x3)
            .backgroundColor(ColorTokens.bgApp)
            .border({ width: 1, color: this.bulkErrorVisible ? ColorTokens.httpDelete : ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.small)
            .onChange((value: string) => {
              this.bulkValue = value;
              this.bulkError = '';
              this.bulkErrorVisible = false;
            })
          if (this.bulkErrorVisible) {
            Text(this.bulkError)
              .fontSize(12)
              .fontColor(ColorTokens.httpDelete)
          }
          Row() {
            Blank()
            Button($r('app.string.action_apply'))
              .fontSize(12)
              .height(SizeTokens.controlMedium)
              .backgroundColor(ColorTokens.brand500)
              .fontColor(ColorTokens.textOnBrand)
              .borderRadius(RadiusTokens.small)
              .onClick(() => this.applyBulk())
          }
          .width('100%')
        }
        .width('100%')
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -6 }))
          .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
      } else {
        Row() {
          Text('✓').width(34).textAlign(TextAlign.Center).fontSize(10).fontColor(ColorTokens.textTertiary)
          Text($r('app.string.field_key')).layoutWeight(3).fontSize(10).fontColor(ColorTokens.textTertiary)
          Text($r('app.string.field_value')).layoutWeight(4).fontSize(10).fontColor(ColorTokens.textTertiary)
          if (this.showSecret) {
            Text($r('app.string.field_secret')).width(58).fontSize(10).fontColor(ColorTokens.textTertiary).textAlign(TextAlign.Center)
          }
          if (this.showType) {
            Text($r('app.string.field_type')).width(76).fontSize(10).fontColor(ColorTokens.textTertiary)
          }
          if (this.showDescription) {
            Text($r('app.string.field_description')).layoutWeight(3).fontSize(10).fontColor(ColorTokens.textTertiary)
          }
          Blank().width(72)
        }
        .height(30)
        .width('100%')
        .padding({ left: SpacingTokens.x1, right: SpacingTokens.x1 })
        .backgroundColor(ColorTokens.bgApp)
        .border({ width: { top: 1, bottom: 1 }, color: ColorTokens.borderSubtle })

        ForEach(this.items, (item: KeyValueItem) => {
          Row({ space: SpacingTokens.x2 }) {
            Checkbox({ name: item.id })
              .select(item.enabled)
              .selectedColor(ColorTokens.brand500)
              .width(18)
              .height(18)
              .onChange((enabled: boolean) => this.updateItem(item.id, item.key, item.value,
                item.description, enabled, item.type))
            TextInput({ text: item.key, placeholder: $r('app.string.field_key_placeholder') })
              .fontSize(13)
              .height(SizeTokens.controlMedium)
              .backgroundColor(ColorTokens.bgWorkspace)
              .layoutWeight(3)
              .onChange((value: string) => this.updateItem(item.id, value, item.value,
                item.description, item.enabled, item.type))
            if (this.showType && item.type === 'file') {
              Button() {
                Text(item.value.length > 0 ? item.value : $r('app.string.file_choose'))
                  .fontSize(12)
                  .fontColor(item.value.length > 0 ? ColorTokens.textSecondary : ColorTokens.brand600)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
                .height(SizeTokens.controlMedium)
                .backgroundColor(ColorTokens.bgApp)
                .borderRadius(RadiusTokens.small)
                .layoutWeight(4)
                .onClick(() => this.selectItemFile(item))
            } else {
              TextInput({ text: item.value, placeholder: $r('app.string.field_value_placeholder') })
                .type(item.secret ? InputType.Password : InputType.Normal)
                .fontSize(13)
                .height(SizeTokens.controlMedium)
                .backgroundColor(ColorTokens.bgWorkspace)
                .layoutWeight(4)
                .onChange((value: string) => this.updateItem(item.id, item.key, value,
                  item.description, item.enabled, item.type))
            }
            if (this.showSecret) {
              Checkbox({ name: `${item.id}-secret` })
                .select(item.secret)
                .selectedColor(ColorTokens.brand500)
                .width(58)
                .height(18)
                .onChange((secret: boolean) => this.toggleSecret(item.id, secret))
            }
            if (this.showType) {
              Select([{ value: $r('app.string.type_text') }, { value: $r('app.string.type_file') }])
                .selected(item.type === 'file' ? 1 : 0)
                .value(item.type === 'file' ? $r('app.string.type_file') : $r('app.string.type_text'))
                .width(76)
                .height(SizeTokens.controlMedium)
                .onSelect((index: number) => this.updateItem(item.id, item.key, item.value,
                  item.description, item.enabled, index === 1 ? 'file' : 'text'))
            }
            if (this.showDescription) {
              TextInput({ text: item.description, placeholder: $r('app.string.field_description_placeholder') })
                .fontSize(13)
                .height(SizeTokens.controlMedium)
                .backgroundColor(ColorTokens.bgWorkspace)
                .layoutWeight(3)
                .onChange((value: string) => this.updateItem(item.id, item.key, item.value,
                  value, item.enabled, item.type))
            }
            Text('⧉')
              .fontSize(15)
              .fontColor(ColorTokens.textTertiary)
              .width(28)
              .textAlign(TextAlign.Center)
              .onClick(() => this.duplicateItem(item))
            Text('×')
              .fontSize(17)
              .fontColor(ColorTokens.textTertiary)
              .width(28)
              .textAlign(TextAlign.Center)
              .onClick(() => this.removeItem(item.id))
          }
          .height(42)
          .width('100%')
          .padding({ left: SpacingTokens.x2, right: SpacingTokens.x1 })
          .border({ width: { bottom: 1 }, color: ColorTokens.borderSubtle })
          .transition(TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 1, y: 0.82, centerY: '0%' }))
            .animation({ duration: MotionTokens.normal, curve: MotionTokens.standardCurve }))
        }, (item: KeyValueItem) => `${item.id}-${item.type}-${item.secret}`)

        Row({ space: SpacingTokens.x2 }) {
          Text('+')
            .fontSize(17)
            .fontColor(ColorTokens.brand500)
          Text(this.addLabel())
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
        }
        .height(40)
        .width('100%')
        .padding({ left: SpacingTokens.x3 })
        .onClick(() => this.addItem())
      }
    }
    .width('100%')
  }
}
