import { AuthConfig, AuthType } from '../../../models/ShellModels';
import { SecretInput } from '../common/SecretInput';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SizeTokens, SpacingTokens } from '../../tokens/LayoutTokens';

@Component
export struct AuthEditor {
  @Prop config: AuthConfig;
  onChange: (config: AuthConfig) => void = () => {};

  private update(type: AuthType, bearerToken: string, username: string, password: string,
    apiKey: string, apiValue: string, apiLocation: 'header' | 'query'): void {
    this.onChange({ type, bearerToken, username, password, apiKey, apiValue, apiLocation });
  }

  @Builder
  private authTypeItem(type: AuthType, label: string, description: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(this.config.type === type ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.config.type === type ? ColorTokens.brand600 : ColorTokens.textPrimary)
      Text(description)
        .fontSize(10)
        .fontColor(ColorTokens.textTertiary)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: SpacingTokens.x3, right: SpacingTokens.x2, top: 9, bottom: 9 })
    .backgroundColor(this.config.type === type ? ColorTokens.brand50 : ColorTokens.bgWorkspace)
    .borderRadius(RadiusTokens.small)
    .onClick(() => this.update(type, this.config.bearerToken, this.config.username,
      this.config.password, this.config.apiKey, this.config.apiValue, this.config.apiLocation))
  }

  @Builder
  private fieldLabel(label: string) {
    Text(label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(ColorTokens.textSecondary)
  }

  build() {
    Row() {
      Column({ space: SpacingTokens.x1 }) {
        Text('TYPE')
          .fontSize(10)
          .fontColor(ColorTokens.textTertiary)
          .margin({ left: SpacingTokens.x3, bottom: SpacingTokens.x2 })
        this.authTypeItem('none', 'No Auth', 'No authorization data')
        this.authTypeItem('bearer', 'Bearer Token', 'Authorization header')
        this.authTypeItem('basic', 'Basic Auth', 'Username and password')
        this.authTypeItem('apiKey', 'API Key', 'Header or query value')
      }
      .width(190)
      .height('100%')
      .padding({ top: SpacingTokens.x4, left: SpacingTokens.x2, right: SpacingTokens.x2 })
      .alignItems(HorizontalAlign.Start)
      .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

      Column({ space: SpacingTokens.x3 }) {
        if (this.config.type === 'none') {
          Text('This request does not use authorization.')
            .fontSize(13)
            .fontColor(ColorTokens.textSecondary)
        } else if (this.config.type === 'bearer') {
          this.fieldLabel('TOKEN')
          SecretInput({
            value: this.config.bearerToken,
            placeholder: 'Bearer token',
            onChange: (value: string) => this.update(this.config.type, value, this.config.username,
              this.config.password, this.config.apiKey, this.config.apiValue, this.config.apiLocation)
          })
          Text('The token will be sent as an Authorization: Bearer header.')
            .fontSize(11)
            .fontColor(ColorTokens.textTertiary)
        } else if (this.config.type === 'basic') {
          this.fieldLabel('USERNAME')
          TextInput({ text: this.config.username, placeholder: 'Username' })
            .fontSize(13)
            .height(SizeTokens.controlMedium)
            .backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.small)
            .onChange((value: string) => this.update(this.config.type, this.config.bearerToken,
              value, this.config.password, this.config.apiKey, this.config.apiValue, this.config.apiLocation))
          this.fieldLabel('PASSWORD')
          SecretInput({
            value: this.config.password,
            placeholder: 'Password',
            onChange: (value: string) => this.update(this.config.type, this.config.bearerToken,
              this.config.username, value, this.config.apiKey, this.config.apiValue, this.config.apiLocation)
          })
        } else {
          this.fieldLabel('KEY')
          TextInput({ text: this.config.apiKey, placeholder: 'X-API-Key' })
            .fontSize(13)
            .height(SizeTokens.controlMedium)
            .backgroundColor(ColorTokens.bgSurface)
            .border({ width: 1, color: ColorTokens.borderDefault })
            .borderRadius(RadiusTokens.small)
            .onChange((value: string) => this.update(this.config.type, this.config.bearerToken,
              this.config.username, this.config.password, value, this.config.apiValue, this.config.apiLocation))
          this.fieldLabel('VALUE')
          SecretInput({
            value: this.config.apiValue,
            placeholder: 'API key value',
            onChange: (value: string) => this.update(this.config.type, this.config.bearerToken,
              this.config.username, this.config.password, this.config.apiKey, value, this.config.apiLocation)
          })
          this.fieldLabel('ADD TO')
          Select([{ value: 'Header' }, { value: 'Query Params' }])
            .selected(this.config.apiLocation === 'query' ? 1 : 0)
            .value(this.config.apiLocation === 'query' ? 'Query Params' : 'Header')
            .height(SizeTokens.controlMedium)
            .width(180)
            .onSelect((index: number) => this.update(this.config.type, this.config.bearerToken,
              this.config.username, this.config.password, this.config.apiKey, this.config.apiValue,
              index === 1 ? 'query' : 'header'))
        }
      }
      .layoutWeight(1)
      .height('100%')
      .padding({ left: SpacingTokens.x6, right: SpacingTokens.x6, top: SpacingTokens.x5 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
