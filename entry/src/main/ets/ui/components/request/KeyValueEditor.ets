import { KeyValueItem, KeyValueMode } from '../../../models/ShellModels';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct KeyValueEditor {
  @Prop items: KeyValueItem[] = [];
  @Prop mode: KeyValueMode = 'params';
  @Prop showDescription: boolean = true;
  @Prop showType: boolean = false;
  @State bulkMode: boolean = false;
  @State bulkValue: string = '';
  @State bulkError: string = '';
  private nextItemNumber: number = 1;
  onChange: (items: KeyValueItem[]) => void = () => {};

  private placeholderLabel(): string {
    if (this.mode === 'headers') return 'header';
    if (this.mode === 'form') return 'field';
    if (this.mode === 'multipart') return 'part';
    return 'parameter';
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
    this.onChange([...this.items, {
      id,
      enabled: true,
      key: '',
      value: '',
      description: '',
      type: 'text',
      secret: false
    }]);
  }

  private duplicateItem(item: KeyValueItem): void {
    const id = `${this.mode}-copy-${Date.now()}-${this.nextItemNumber}`;
    this.nextItemNumber += 1;
    this.onChange([...this.items, {
      id,
      enabled: item.enabled,
      key: item.key,
      value: item.value,
      description: item.description,
      type: item.type,
      secret: item.secret
    }]);
  }

  private removeItem(id: string): void {
    this.onChange(this.items.filter((item: KeyValueItem) => item.id !== id));
  }

  private enterBulkMode(): void {
    const lines: string[] = [];
    this.items.forEach((item: KeyValueItem) => {
      lines.push(`${item.key}:${item.value}`);
    });
    this.bulkValue = lines.join('\n');
    this.bulkError = '';
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
        this.bulkError = `Line ${index + 1}: expected key:value`;
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
    this.onChange(nextItems);
    this.bulkError = '';
    this.bulkMode = false;
  }

  build() {
    Column() {
      Row({ space: SpacingTokens.x2 }) {
        Text(`${this.items.length} ${this.items.length === 1 ? 'item' : 'items'}`)
          .fontSize(12)
          .fontColor(ColorTokens.textTertiary)
        Blank()
        Text(this.bulkMode ? 'Table Edit' : 'Bulk Edit')
          .fontSize(12)
          .fontColor(ColorTokens.brand600)
          .height(SizeTokens.controlSmall)
          .padding({ left: SpacingTokens.x3, right: SpacingTokens.x3 })
          .textAlign(TextAlign.Center)
          .borderRadius(RadiusTokens.small)
          .onClick(() => {
            if (this.bulkMode) {
              this.bulkMode = false;
              this.bulkError = '';
            } else {
              this.enterBulkMode();
            }
          })
      }
      .width('100%')
      .height(36)

      if (this.bulkMode) {
        Column({ space: SpacingTokens.x2 }) {
          TextArea({ text: this.bulkValue, placeholder: 'key:value' })
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor(ColorTokens.textPrimary)
            .height(180)
            .padding(SpacingTokens.x3)
            .backgroundColor(ColorTokens.bgApp)
            .border({ width: 1, color: this.bulkError.length > 0 ? ColorTokens.httpDelete : ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.small)
            .onChange((value: string) => {
              this.bulkValue = value;
              this.bulkError = '';
            })
          if (this.bulkError.length > 0) {
            Text(this.bulkError)
              .fontSize(12)
              .fontColor(ColorTokens.httpDelete)
          }
          Row() {
            Blank()
            Button('Apply')
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
      } else {
        Row() {
          Text('✓').width(34).textAlign(TextAlign.Center).fontSize(10).fontColor(ColorTokens.textTertiary)
          Text('KEY').layoutWeight(3).fontSize(10).fontColor(ColorTokens.textTertiary)
          Text('VALUE').layoutWeight(4).fontSize(10).fontColor(ColorTokens.textTertiary)
          if (this.showType) {
            Text('TYPE').width(76).fontSize(10).fontColor(ColorTokens.textTertiary)
          }
          if (this.showDescription) {
            Text('DESCRIPTION').layoutWeight(3).fontSize(10).fontColor(ColorTokens.textTertiary)
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
            TextInput({ text: item.key, placeholder: 'Key' })
              .fontSize(13)
              .height(SizeTokens.controlMedium)
              .backgroundColor(ColorTokens.bgWorkspace)
              .layoutWeight(3)
              .onChange((value: string) => this.updateItem(item.id, value, item.value,
                item.description, item.enabled, item.type))
            TextInput({ text: item.value, placeholder: 'Value' })
              .fontSize(13)
              .height(SizeTokens.controlMedium)
              .backgroundColor(ColorTokens.bgWorkspace)
              .layoutWeight(4)
              .onChange((value: string) => this.updateItem(item.id, item.key, value,
                item.description, item.enabled, item.type))
            if (this.showType) {
              Select([{ value: 'Text' }, { value: 'File' }])
                .selected(item.type === 'file' ? 1 : 0)
                .value(item.type === 'file' ? 'File' : 'Text')
                .width(76)
                .height(SizeTokens.controlMedium)
                .onSelect((index: number) => this.updateItem(item.id, item.key, item.value,
                  item.description, item.enabled, index === 1 ? 'file' : 'text'))
            }
            if (this.showDescription) {
              TextInput({ text: item.description, placeholder: 'Description' })
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
        }, (item: KeyValueItem) => item.id)

        Row({ space: SpacingTokens.x2 }) {
          Text('+')
            .fontSize(17)
            .fontColor(ColorTokens.brand500)
          Text(`Add ${this.placeholderLabel()}`)
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
