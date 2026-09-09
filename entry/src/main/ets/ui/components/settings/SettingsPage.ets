import { SettingsSection, SettingsSectionModel } from '../../../models/ShellModels';
import { AppPreferencesModel } from '../../../models/PersistenceModels';
import { createDefaultPreferences } from '../../../state/AppDefaults';
import { SETTINGS_SECTIONS } from '../../../mock/SupportingMockData';
import { ColorTokens } from '../../tokens/ColorTokens';
import { RadiusTokens, SpacingTokens } from '../../tokens/LayoutTokens';
import { SettingRow } from './SettingRow';

@Component
export struct SettingsPage {
  @State section: SettingsSection = 'General';
  @Prop preferences: AppPreferencesModel = createDefaultPreferences();
  onChange: (preferences: AppPreferencesModel) => void = () => {};
  onExport: () => void = () => {};
  onExportSecrets: () => void = () => {};
  onReset: () => void = () => {};

  private emit(restoreWorkspace: boolean, language: 'en' | 'zh', followRedirects: boolean,
    sslVerification: boolean, defaultTimeoutMs: number, saveHistory: boolean,
    historyRetentionDays: number, maskSecrets: boolean): void {
    this.onChange({ restoreWorkspace, language, followRedirects, sslVerification, defaultTimeoutMs,
      saveHistory, historyRetentionDays, maskSecrets });
  }

  private timeoutLabel(): string {
    return this.preferences.language === 'zh' ? `${this.preferences.defaultTimeoutMs / 1000} 秒` :
      `${this.preferences.defaultTimeoutMs / 1000} seconds`;
  }

  private sectionLabel(section: SettingsSection): ResourceStr {
    if (section === 'General') return $r('app.string.settings_general');
    if (section === 'Appearance') return $r('app.string.settings_appearance');
    if (section === 'Network') return $r('app.string.settings_network');
    if (section === 'Data') return $r('app.string.settings_data');
    if (section === 'Privacy') return $r('app.string.settings_privacy');
    return $r('app.string.settings_about');
  }

  private nextTimeout(): number {
    if (this.preferences.defaultTimeoutMs === 15000) return 30000;
    if (this.preferences.defaultTimeoutMs === 30000) return 60000;
    if (this.preferences.defaultTimeoutMs === 60000) return 120000;
    return 15000;
  }

  private nextRetention(): number {
    if (this.preferences.historyRetentionDays === 7) return 30;
    if (this.preferences.historyRetentionDays === 30) return 90;
    return 7;
  }

  @Builder
  sectionContent() {
    if (this.section === 'General') {
      SettingRow({ title: $r('app.string.restore_workspace_title'),
        description: $r('app.string.restore_workspace_description'), toggle: true,
        checked: this.preferences.restoreWorkspace, onToggle: (value: boolean) => this.emit(value,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.language_title'), description: $r('app.string.language_description'),
        controlLabel: this.preferences.language === 'zh' ? $r('app.string.language_chinese') :
          $r('app.string.language_english'),
        onPress: () => this.emit(this.preferences.restoreWorkspace,
          this.preferences.language === 'en' ? 'zh' : 'en', this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.shortcuts_title'), description: $r('app.string.shortcuts_description'),
        controlLabel: $r('app.string.action_view') })
    } else if (this.section === 'Appearance') {
      SettingRow({ title: $r('app.string.theme_title'), description: $r('app.string.theme_description'),
        controlLabel: $r('app.string.theme_system') })
      SettingRow({ title: $r('app.string.density_title'), description: $r('app.string.density_description'),
        controlLabel: $r('app.string.density_comfortable') })
    } else if (this.section === 'Network') {
      SettingRow({ title: $r('app.string.redirect_title'), description: $r('app.string.redirect_description'), toggle: true,
        checked: this.preferences.followRedirects, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, value,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.ssl_title'), description: $r('app.string.ssl_description'), toggle: true,
        checked: this.preferences.sslVerification, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          value, this.preferences.defaultTimeoutMs, this.preferences.saveHistory,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      if (!this.preferences.sslVerification) {
        Text($r('app.string.ssl_warning'))
          .fontSize(12)
          .fontColor(ColorTokens.httpDelete)
          .width('100%')
          .padding(SpacingTokens.x3)
          .backgroundColor(ColorTokens.statusDangerBackground)
          .borderRadius(RadiusTokens.small)
      }
      SettingRow({ title: $r('app.string.timeout_title'), description: $r('app.string.timeout_description'),
        controlLabel: this.timeoutLabel(), onPress: () => this.emit(this.preferences.restoreWorkspace,
          this.preferences.language, this.preferences.followRedirects, this.preferences.sslVerification,
          this.nextTimeout(), this.preferences.saveHistory, this.preferences.historyRetentionDays,
          this.preferences.maskSecrets) })
    } else if (this.section === 'Data') {
      SettingRow({ title: $r('app.string.nimbo_export_title'),
        description: $r('app.string.nimbo_export_description'),
        controlLabel: $r('app.string.export_action'), onPress: this.onExport })
      SettingRow({ title: $r('app.string.save_history_title'), description: $r('app.string.save_history_description'), toggle: true,
        checked: this.preferences.saveHistory, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs, value,
          this.preferences.historyRetentionDays, this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.retention_title'), description: $r('app.string.retention_description'),
        controlLabel: this.preferences.language === 'zh' ? `${this.preferences.historyRetentionDays} 天` :
          `${this.preferences.historyRetentionDays} days`,
        onPress: () => this.emit(this.preferences.restoreWorkspace, this.preferences.language,
          this.preferences.followRedirects, this.preferences.sslVerification,
          this.preferences.defaultTimeoutMs, this.preferences.saveHistory, this.nextRetention(),
          this.preferences.maskSecrets) })
      SettingRow({ title: $r('app.string.reset_title'), description: $r('app.string.reset_description'),
        controlLabel: $r('app.string.reset_action'), dangerous: true, onPress: this.onReset })
    } else if (this.section === 'Privacy') {
      SettingRow({ title: $r('app.string.mask_secrets_title'), description: $r('app.string.mask_secrets_description'), toggle: true,
        checked: this.preferences.maskSecrets, onToggle: (value: boolean) => this.emit(
          this.preferences.restoreWorkspace, this.preferences.language, this.preferences.followRedirects,
          this.preferences.sslVerification, this.preferences.defaultTimeoutMs,
          this.preferences.saveHistory, this.preferences.historyRetentionDays, value) })
      SettingRow({ title: $r('app.string.export_secrets_title'), description: $r('app.string.export_secrets_description'),
        controlLabel: $r('app.string.export_action'), onPress: this.onExportSecrets })
    } else {
      SettingRow({ title: 'Nimbo', description: $r('app.string.about_description'), controlLabel: 'Version 0.1.0' })
      SettingRow({ title: $r('app.string.application_identity'),
        description: 'Bundle com.nimbo.app · App ID 6917615930484878194', controlLabel: $r('app.string.local_build') })
    }
  }

  build() {
    Row() {
      Column() {
        Text($r('app.string.settings_title'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTokens.textPrimary)
          .width('100%')
          .height(48)
          .padding({ left: SpacingTokens.x3 })
        ForEach(SETTINGS_SECTIONS, (item: SettingsSectionModel) => {
          Row({ space: SpacingTokens.x3 }) {
            Text(item.icon).width(20).fontSize(15).textAlign(TextAlign.Center)
              .fontColor(item.id === this.section ? ColorTokens.brand500 : ColorTokens.textTertiary)
            Text(this.sectionLabel(item.id)).fontSize(13)
              .fontColor(item.id === this.section ? ColorTokens.brand600 : ColorTokens.textSecondary)
          }
          .width('100%')
          .height(40)
          .padding({ left: SpacingTokens.x3 })
          .backgroundColor(item.id === this.section ? ColorTokens.bgSurfaceActive : ColorTokens.bgSidebar)
          .borderRadius(RadiusTokens.medium)
          .onClick(() => { this.section = item.id; })
        }, (item: SettingsSectionModel) => item.id)
        Blank()
      }
      .width(220)
      .height('100%')
      .padding(SpacingTokens.x2)
      .backgroundColor(ColorTokens.bgSidebar)
      .border({ width: { right: 1 }, color: ColorTokens.borderSubtle })

      Scroll() {
        Column() {
          Text(this.sectionLabel(this.section))
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTokens.textPrimary)
            .width('100%')
          Text($r('app.string.settings_description'))
            .fontSize(12)
            .fontColor(ColorTokens.textTertiary)
            .width('100%')
            .margin({ top: SpacingTokens.x1, bottom: SpacingTokens.x5 })
          this.sectionContent()
        }
        .width('100%')
        .padding({ left: 40, right: 40, top: 30, bottom: 40 })
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor(ColorTokens.bgWorkspace)
    }
    .width('100%')
    .height('100%')
  }
}
